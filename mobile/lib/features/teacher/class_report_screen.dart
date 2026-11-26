import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'class_portal_header.dart';
import 'report_parts.dart';

num? _mean(Iterable<num?> xs) {
  final vals = xs.whereType<num>().toList();
  if (vals.isEmpty) return null;
  return (vals.reduce((s, v) => s + v) / vals.length).round();
}

/// Class-wide report as CSV — aggregates, per-assessment averages,
/// per-lesson averages and one row per student. Same shape as web.
String buildClassReportCsv({
  required String className,
  required int students,
  required num? lessonsAvg,
  required num? quizAvg,
  required num? preAvg,
  required num? postAvg,
  required num? gain,
  required List<Json> assessments,
  required List<Json> lessons,
  required List<Json> roster,
}) {
  String p(num? v) => v == null ? '—' : '${v.round()}%';
  final b = StringBuffer()
    ..writeln('Class report')
    ..writeln('Class,${csvCell(className)}')
    ..writeln('Students,$students')
    ..writeln('Lessons,${p(lessonsAvg)}')
    ..writeln('Quiz average,${p(quizAvg)}')
    ..writeln('Pre-test,${p(preAvg)}')
    ..writeln('Post-test,${p(postAvg)}')
    ..writeln('Gain,${gain == null ? '—' : '${gain >= 0 ? '+' : ''}$gain%'}')
    ..writeln()
    ..writeln('Assessment,Class average,Attempts,Visibility');
  for (final a in assessments) {
    final avg = a['avg'];
    b.writeln([
      csvCell(a['title']),
      avg == null ? 'No attempts' : '${(avg as num).round()}%',
      a['attempts'] ?? 0,
      avg != null && a['released'] != true ? 'Not released' : '',
    ].join(','));
  }
  b
    ..writeln()
    ..writeln('Lesson,Class average');
  for (final l in lessons) {
    b.writeln('${csvCell(l['title'])},${(l['avg'] as num?)?.round() ?? 0}%');
  }
  b
    ..writeln()
    ..writeln('Student,Lessons,Quiz average,Pre-test,Post-test,Gain');
  for (final r in roster) {
    final pre = r['pre_score'] as num?;
    final post = r['post_score'] as num?;
    final g = pre != null && post != null ? post - pre : null;
    b.writeln([
      csvCell(r['full_name']),
      p(r['lessons_pct'] as num?),
      p(r['quizzes_pct'] as num?),
      p(pre),
      p(post),
      g == null ? '—' : '${g >= 0 ? '+' : ''}$g%',
    ].join(','));
  }
  return b.toString();
}

/// Class-level report: aggregate pre/post chart, rings, per-assessment and
/// per-lesson averages, plus the full roster — tap through to each student.
class ClassReportScreen extends ConsumerWidget {
  const ClassReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cls = currentClass.value;
    if (cls == null) return const Scaffold(body: SizedBox.shrink());
    final classId = '${cls['id']}';
    final me = ref.watch(meProvider);
    final members = ref.watch(classMembersProvider(classId));
    final progress = ref.watch(classProgressProvider(classId));
    final assessments = ref.watch(classAssessmentsProvider(classId));
    final lessons = ref.watch(classLessonAvgsProvider(classId));

    // Guard — the class must belong to this teacher (or admin).
    if (me.hasValue) {
      final owns = '${cls['teacher_id']}' == '${me.value?['id']}' ||
          me.value?['role'] == 'admin';
      if (!owns) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          DSToast.show(context,
              message: "That class isn't yours.", tone: DSToastTone.error);
          context.pop();
        });
        return const Scaffold(body: SizedBox.shrink());
      }
    }
    if (me.hasError || members.hasError || progress.hasError) {
      return Scaffold(
        body: Center(
          child: DSEmptyState(
            icon: DSIconName.offline,
            title: "Couldn't load this report",
            body: 'Check your connection and try again.',
            action: DSButton(
              variant: DSButtonVariant.outline,
              size: DSButtonSize.sm,
              leadingIcon: DSIconName.retry,
              onPressed: () {
                ref.invalidate(meProvider);
                ref.invalidate(classMembersProvider(classId));
                ref.invalidate(classProgressProvider(classId));
              },
              child: const Text('Try again'),
            ),
          ),
        ),
      );
    }
    if (!me.hasValue) {
      return const Scaffold(body: Center(child: DSLoadingIndicator()));
    }

    final roster = progress.valueOrNull ?? const <Json>[];
    final studentCount = (members.valueOrNull ?? const <Json>[])
        .where((m) => m['status'] == 'active')
        .length;
    final lessonsAvg = _mean(roster.map((r) => r['lessons_pct'] as num?));
    final quizAvg = _mean(roster.map((r) => r['quizzes_pct'] as num?));
    final preAvg = _mean(roster.map((r) => r['pre_score'] as num?));
    final postAvg = _mean(roster.map((r) => r['post_score'] as num?));
    final gain = _mean(roster
        .where((r) => r['pre_score'] != null && r['post_score'] != null)
        .map((r) => (r['post_score'] as num) - (r['pre_score'] as num)));
    final acts = assessments.valueOrNull ?? const <Json>[];
    final anyAttempt = acts.any((a) => a['avg'] != null);
    final lessonRows = lessons.valueOrNull ?? const <Json>[];
    final className = '${cls['name'] ?? ''}';

    return Scaffold(
      body: Column(children: [
        ClassHeroHeader(
          cls: cls,
          title: 'Class report',
          subtitle: className,
          leading: HeroTile(
            icon: DSIconName.back,
            label: 'Back',
            onTap: () => context.pop(),
          ),
        ),
        Expanded(
          child: MaxWidth(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  ReportHeadTile(
                    value: '$studentCount',
                    label: 'Students',
                    bg: DSColors.pastelBlue,
                  ),
                  const SizedBox(width: 10),
                  ReportHeadTile(
                    value: quizAvg == null ? '—' : '$quizAvg%',
                    label: 'Quiz avg',
                    bg: DSColors.pastelPurple,
                  ),
                  const SizedBox(width: 10),
                  ReportHeadTile(
                    value: gain == null ? '—' : '${gain >= 0 ? '+' : ''}$gain%',
                    label: 'Gain',
                    bg: DSColors.pastelMint,
                  ),
                ]),
                const SizedBox(height: 16),
                DSCard(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text('Class pre-test to post-test',
                            style: DSText.title),
                      ),
                      if (gain != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: DSColors.mint,
                            borderRadius: DSRadii.pillBr,
                            boxShadow: dsEdge(DSColors.edgeMint, h: 3),
                          ),
                          child: Text(
                            '${gain >= 0 ? '+' : ''}$gain% avg gain',
                            style: DSText.label
                                .copyWith(fontSize: 12, color: DSColors.navy),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    PrePostChart(pre: preAvg, post: postAvg),
                  ],
                )),
                const SizedBox(height: 16),
                DSCard(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Class averages', style: DSText.title),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: ReportRing(
                          label: 'Lessons',
                          value: lessonsAvg?.toDouble(),
                          series: 1,
                        ),
                      ),
                      Expanded(
                        child: ReportRing(
                          label: 'Quizzes',
                          value: quizAvg?.toDouble(),
                          series: 2,
                        ),
                      ),
                      Expanded(
                        child: ReportRing(
                          label: 'Pre-test',
                          value: preAvg?.toDouble(),
                          series: 2,
                        ),
                      ),
                      Expanded(
                        child: ReportRing(
                          label: 'Post-test',
                          value: postAvg?.toDouble(),
                          series: 4,
                        ),
                      ),
                    ]),
                  ],
                )),
                const SizedBox(height: 16),
                DSCard(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assessment averages', style: DSText.title),
                    if (acts.isNotEmpty && !anyAttempt)
                      const ReportEmpty(
                          message:
                              'No attempts yet — class averages appear once students take an assessment.'),
                    for (final a in acts) ...[
                      const SizedBox(height: 12),
                      ReportScoreRow(
                        assessment: a,
                        emptyLabel: 'No attempts',
                        caption:
                            '${a['attempts'] ?? 0} ${(a['attempts'] ?? 0) == 1 ? 'student' : 'students'} attempted',
                      ),
                    ],
                    if (acts.isEmpty && assessments.hasValue)
                      const ReportEmpty(
                          message: 'No assessments in this class yet.'),
                  ],
                )),
                const SizedBox(height: 16),
                DSCard(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lesson averages', style: DSText.title),
                    for (final l in lessonRows) ...[
                      const SizedBox(height: 12),
                      ReportLessonRow(lesson: l),
                    ],
                    if (lessonRows.isEmpty && lessons.hasValue)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('No lessons in this class yet.',
                            style: DSText.body.copyWith(color: DSColors.muted)),
                      ),
                  ],
                )),
                const SizedBox(height: 16),
                DSCard(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text('Students', style: DSText.title),
                      ),
                      Flexible(
                        child: Text('Tap for the full report',
                            overflow: TextOverflow.ellipsis,
                            style:
                                DSText.caption.copyWith(color: DSColors.muted)),
                      ),
                    ]),
                    for (final r in roster) ...[
                      const SizedBox(height: 12),
                      _StudentTile(
                        row: r,
                        onTap: () => context.push(
                            '/teacher/students/report/${r['student_id']}'),
                      ),
                    ],
                    if (roster.isEmpty && progress.hasValue)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('No active students in this class yet.',
                            style: DSText.body.copyWith(color: DSColors.muted)),
                      ),
                  ],
                )),
                const SizedBox(height: 16),
                DSButton(
                  variant: DSButtonVariant.outline,
                  leadingIcon: DSIconName.export,
                  onPressed: () async {
                    final csv = buildClassReportCsv(
                      className: className,
                      students: studentCount,
                      lessonsAvg: lessonsAvg,
                      quizAvg: quizAvg,
                      preAvg: preAvg,
                      postAvg: postAvg,
                      gain: gain,
                      assessments: acts,
                      lessons: lessonRows,
                      roster: roster,
                    );
                    final slug = className
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
                    await SharePlus.instance.share(ShareParams(
                      files: [
                        XFile.fromData(utf8.encode('﻿$csv'), // ﻿ = UTF-8 BOM
                            name: 'class-report-$slug.csv',
                            mimeType: 'text/csv'),
                      ],
                      subject: 'Class report — $className',
                    ));
                  },
                  child: const Text('Export report'),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

/// One roster row in the Students card — avatar, name and the three
/// headline metrics; taps through to that student's report.
class _StudentTile extends StatelessWidget {
  final Json row;
  final VoidCallback onTap;
  const _StudentTile({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = '${row['full_name'] ?? 'Student'}';
    final pre = row['pre_score'] as num?;
    final post = row['post_score'] as num?;
    final gain = pre != null && post != null ? post - pre : null;
    return Semantics(
      button: true,
      label: 'Open report for $name',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          Row(children: [
            DSAvatar(name: name, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: DSText.label.copyWith(color: DSColors.navy),
                        overflow: TextOverflow.ellipsis),
                    Text('Tap to open the report',
                        style: DSText.caption.copyWith(color: DSColors.muted),
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
            const DSIcon(DSIconName.chevron, size: 18, color: DSColors.muted),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _Mini(
                  label: 'Lessons',
                  value: '${(row['lessons_pct'] as num?)?.round() ?? 0}%'),
            ),
            Expanded(
              child: _Mini(
                  label: 'Quiz',
                  value: row['quizzes_pct'] == null
                      ? '—'
                      : '${row['quizzes_pct']}%'),
            ),
            Expanded(
              child: _Mini(
                  label: 'Gain',
                  value: gain == null ? '—' : '${gain >= 0 ? '+' : ''}$gain%'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: DSText.label.copyWith(color: DSColors.navy)),
      Text(label,
          style: DSText.caption.copyWith(fontSize: 11, color: DSColors.muted)),
    ]);
  }
}
