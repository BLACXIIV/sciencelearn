import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'attempt_paper_sheet.dart';
import 'class_portal_header.dart';
import 'report_parts.dart';

/// The student's report as CSV — header metrics, per-assessment scores
/// (with release visibility) and lesson progress. Shared shape with web.
String buildReportCsv({
  required String studentName,
  required String className,
  required Json? progress,
  required List<Json> assessments,
  required List<Json> lessons,
}) {
  final p = progress;
  final pre = p?['pre_score'] as num?;
  final post = p?['post_score'] as num?;
  final gain = pre != null && post != null ? post - pre : null;
  final b = StringBuffer()
    ..writeln('Student report')
    ..writeln('Student,${csvCell(studentName)}')
    ..writeln('Class,${csvCell(className)}')
    ..writeln(
        'Lessons,${p == null ? '—' : '${(p['lessons_pct'] as num?)?.round() ?? 0}%'}')
    ..writeln(
        'Quiz average,${p?['quizzes_pct'] == null ? '—' : '${p!['quizzes_pct']}%'}')
    ..writeln('Pre-test,${pre == null ? '—' : '$pre%'}')
    ..writeln('Post-test,${post == null ? '—' : '$post%'}')
    ..writeln('Gain,${gain == null ? '—' : '${gain >= 0 ? '+' : ''}$gain%'}')
    ..writeln()
    ..writeln('Assessment,Score,Visibility');
  for (final a in assessments) {
    final score = a['score'];
    b.writeln([
      csvCell(a['title']),
      score == null
          ? 'Not taken'
          : a['points_total'] != null
              ? '${fmtPts(a['points_earned'] as num?)}/'
                '${fmtPts(a['points_total'] as num?)} pts'
              : '$score%',
      score != null && a['released'] != true ? 'Not released' : '',
    ].join(','));
  }
  b
    ..writeln()
    ..writeln('Lesson,Progress');
  for (final l in lessons) {
    b.writeln(
        '${csvCell(l['title'])},${(l['percent'] as num?)?.round() ?? 0}%');
  }
  return b.toString();
}

/// Export: builds the CSV and opens the platform share sheet.
Future<void> _exportReport({
  required String name,
  required String className,
  required Json? progress,
  required List<Json> assessments,
  required List<Json> lessons,
}) async {
  final csv = buildReportCsv(
    studentName: name,
    className: className,
    progress: progress,
    assessments: assessments,
    lessons: lessons,
  );
  final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  await SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(utf8.encode('﻿$csv'), // ﻿ = UTF-8 BOM
          name: 'student-report-$slug.csv', mimeType: 'text/csv'),
    ],
    subject: 'Student report — $name',
  ));
}

/// Per-student report pushed inside the Students branch (bottom bar stays,
/// Students tab lit). Guard: the student must be an ACTIVE member of the
/// current class and the class must belong to this teacher (or admin).
class StudentReportScreen extends ConsumerWidget {
  final String studentId;
  const StudentReportScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cls = currentClass.value;
    if (cls == null) return const Scaffold(body: SizedBox.shrink());
    final classId = '${cls['id']}';
    final ids = (classId, studentId);
    final member = ref.watch(classMembershipProvider(ids));
    final me = ref.watch(meProvider);
    final progress = ref.watch(classProgressProvider(classId));
    final assessments = ref.watch(studentAssessmentsProvider(ids));
    final lessons = ref.watch(studentLessonsProvider(ids));

    // Guard — wait for membership + profile, then bounce non-members/owners.
    if (member.hasValue && me.hasValue) {
      final owns = '${cls['teacher_id']}' == '${me.value?['id']}' ||
          me.value?['role'] == 'admin';
      if (!owns || member.value?['status'] != 'active') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          DSToast.show(context,
              message: "That student isn't in this class.",
              tone: DSToastTone.error);
          context.go('/teacher/students');
        });
        return const Scaffold(body: SizedBox.shrink());
      }
    }
    if (member.hasError || me.hasError) {
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
                ref.invalidate(classMembershipProvider(ids));
                ref.invalidate(meProvider);
              },
              child: const Text('Try again'),
            ),
          ),
        ),
      );
    }
    if (!member.hasValue || !me.hasValue) {
      return const Scaffold(body: Center(child: DSLoadingIndicator()));
    }

    final repo = ref.read(repoProvider);
    final rows = progress.valueOrNull ?? const <Json>[];
    Json? p;
    for (final r in rows) {
      if ('${r['student_id']}' == studentId) p = r;
    }
    final name =
        '${member.value?['profiles']?['full_name'] ?? p?['full_name'] ?? 'Student'}';
    final acts = assessments.valueOrNull ?? const <Json>[];
    final anyAttempt = acts.any((a) => a['score'] != null);
    /// lesson_title -> its activities, in assessment order.
    final groups = <String, List<Json>>{};
    for (final a in acts) {
      groups.putIfAbsent('${a['lesson_title']}', () => []).add(a);
    }

    return Scaffold(
      body: Column(children: [
        ClassHeroHeader(
          cls: cls,
          title: name,
          subtitle: '${cls['name'] ?? ''}',
          leading: Row(mainAxisSize: MainAxisSize.min, children: [
            HeroTile(
              icon: DSIconName.back,
              label: 'Back to students',
              onTap: () => context.pop(),
            ),
            const SizedBox(width: 12),
            DSAvatar(name: name, size: 48, pastel: DSAvatarPastel.mint),
          ]),
        ),
        Expanded(
          child: MaxWidth(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  ReportHeadTile(
                    value: p == null
                        ? '—'
                        : '${(p['lessons_pct'] as num?)?.round() ?? 0}%',
                    label: 'Lessons',
                    bg: DSColors.pastelBlue,
                  ),
                  const SizedBox(width: 10),
                  ReportHeadTile(
                    value: p?['quizzes_pct'] == null
                        ? '—'
                        : '${p!['quizzes_pct']}%',
                    label: 'Quiz avg',
                    bg: DSColors.pastelPurple,
                  ),
                ]),
                const SizedBox(height: 16),
                DSCard(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overall progress', style: DSText.title),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: ReportRing(
                          label: 'Lessons',
                          value: (p?['lessons_pct'] as num?)?.toDouble(),
                          series: 1,
                        ),
                      ),
                      Expanded(
                        child: ReportRing(
                          label: 'Quizzes',
                          value: (p?['quizzes_done_pct'] as num?)?.toDouble(),
                          series: 2,
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
                    Text('Activities', style: DSText.title),
                    if (acts.isNotEmpty && !anyAttempt)
                      const ReportEmpty(
                        message:
                            'No attempts yet — tap an activity to preview its test paper.',
                      ),
                    for (final e in groups.entries) ...[
                      const SizedBox(height: 14),
                      Text(e.key,
                          style: DSText.label
                              .copyWith(color: DSColors.muted)),
                      for (final a in e.value) ...[
                        const SizedBox(height: 8),
                        DSListItemCard(
                          onTap: () => showDSBottomSheet<void>(
                            context,
                            child: AttemptPaperSheet(
                              repo: repo,
                              assessmentId: '${a['id']}',
                              studentId: studentId,
                              studentName: name,
                              teacherId: '${cls['teacher_id']}',
                              released: a['released'] == true,
                            ),
                          ),
                          leading: const DSIcon(DSIconName.quiz,
                              size: 20, color: DSColors.blue),
                          title: Text('${a['title']}'),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (a['score'] != null)
                                  Text(
                                      a['points_total'] != null
                                          ? '${fmtPts(a['points_earned'] as num?)}/'
                                            '${fmtPts(a['points_total'] as num?)} pts'
                                          : '${(a['score'] as num).round()}%',
                                      style: DSText.label
                                          .copyWith(color: DSColors.navy))
                                else
                                  Text('Not taken',
                                      style: DSText.caption
                                          .copyWith(color: DSColors.muted)),
                                if (a['score'] != null &&
                                    a['released'] != true) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: DSColors.sun,
                                      borderRadius: DSRadii.pillBr,
                                    ),
                                    child: Text('Not released',
                                        style: DSText.label.copyWith(
                                            fontSize: 11,
                                            color: DSColors.navy)),
                                  ),
                                ],
                                const SizedBox(width: 6),
                                const DSIcon(DSIconName.chevron,
                                    size: 16, color: DSColors.muted),
                              ]),
                        ),
                      ],
                    ],
                    if (acts.isEmpty && assessments.hasValue)
                      const ReportEmpty(),
                  ],
                )),
                const SizedBox(height: 16),
                DSCard(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lessons', style: DSText.title),
                    for (final l in lessons.valueOrNull ?? const <Json>[]) ...[
                      const SizedBox(height: 12),
                      ReportLessonRow(lesson: l),
                    ],
                    if ((lessons.valueOrNull ?? const []).isEmpty &&
                        lessons.hasValue)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('No lessons in this class yet.',
                            style: DSText.body.copyWith(color: DSColors.muted)),
                      ),
                  ],
                )),
                const SizedBox(height: 16),
                DSButton(
                  variant: DSButtonVariant.outline,
                  leadingIcon: DSIconName.export,
                  onPressed: () => _exportReport(
                    name: name,
                    className: '${cls['name'] ?? ''}',
                    progress: p,
                    assessments: acts,
                    lessons: lessons.valueOrNull ?? const [],
                  ),
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
