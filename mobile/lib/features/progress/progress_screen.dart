import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Progress tracker — completed lessons, quiz scores and recent activity.
/// (Pre/post gain was removed; overall = mean of lessons % + quiz avg.)
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  Future<({List<Json> lessons, List<Json> scores, List<Json> recent})>
      _load(Repo repo) async => (
            lessons: await repo.lessons(),
            scores: await repo.myQuizScores(),
            recent: await repo.recentActivity(),
          );

  int _pct(Json l) {
    final lp = (l['lesson_progress'] as List?) ?? [];
    return lp.isEmpty ? 0 : ((lp.first['percent'] as num?) ?? 0).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider).valueOrNull;
    final repo = ref.read(repoProvider);
    double n(String k) => ((p?[k] ?? 0) as num).toDouble();
    final lessons = n('lessons_pct'), quizzes = n('quizzes_pct');
    final overall = (lessons + quizzes) / 2;

    return Scaffold(
      body: Column(children: [
        DSPageHeader(
          compact: true,
          child: SafeArea(
            bottom: false,
            child: Text('Progress tracker', style: DSText.h2),
          ),
        ),
        Expanded(
          child: KeepDataFutureBuilder<
              ({List<Json> lessons, List<Json> scores, List<Json> recent})>(
            future: _load(repo),
            builder: (context, snap) {
              final total = snap.data?.lessons.length ?? 0;
              final done = snap.data == null
                  ? 0
                  : snap.data!.lessons
                      .where((l) => _pct(l) >= 100)
                      .length;
              final scores = snap.data?.scores ?? const <Json>[];
              final recent = snap.data?.recent ?? const <Json>[];
              final donePct = total == 0 ? 0.0 : done / total * 100;

              final rings = <(String, double, int)>[
                ('Lessons', lessons / 100, 1),
                ('Quizzes', quizzes / 100, 2),
                ('Lessons done', donePct / 100, 4),
              ];
              final breakdown =
                  <(String, double?, String, DSProgressBarTone)>[
                (
                  'Lessons completed',
                  lessons,
                  '${lessons.round()} / 100',
                  DSProgressBarTone.sun
                ),
                (
                  'Quiz average',
                  quizzes,
                  quizzes > 0 ? '${quizzes.round()}%' : '-',
                  DSProgressBarTone.blue
                ),
                (
                  'Lessons done',
                  donePct,
                  total == 0 ? '-' : '$done of $total',
                  DSProgressBarTone.mint
                ),
              ];

              final empty = p == null &&
                  done == 0 &&
                  scores.isEmpty &&
                  recent.isEmpty;

              return MaxWidth(
                  child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DSStatCard(
                    icon: DSIconName.progress,
                    value: '${overall.round()}%',
                    label: 'Overall progress',
                  ),
                  const SizedBox(height: 12),
                  DSCard(
                    child: Wrap(
                      alignment: WrapAlignment.spaceAround,
                      runSpacing: 12,
                      children: [
                        for (final r in rings)
                          Column(children: [
                            DSRingChart(
                              size: 64,
                              slices: [
                                DSRingSlice(r.$2 * 100, series: r.$3),
                                DSRingSlice(100 - r.$2 * 100, series: 0),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(r.$1, style: DSText.caption),
                          ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Score breakdown', style: DSText.title),
                        const SizedBox(height: 8),
                        for (final b in breakdown)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text(b.$1,
                                          style: DSText.bodySm,
                                          overflow: TextOverflow.ellipsis)),
                                  Text(b.$3, style: DSText.label),
                                ],
                              ),
                              const SizedBox(height: 4),
                              DSProgressBar(
                                value: (b.$2 ?? 0) / 100,
                                size: DSProgressBarSize.sm,
                                tone: b.$4,
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quiz scores', style: DSText.title),
                        const SizedBox(height: 8),
                        if (scores.isEmpty)
                          Text('No quiz scores yet — take a quiz to see it here.',
                              style: DSText.bodySm
                                  .copyWith(color: DSColors.muted)),
                        for (final s in scores)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(children: [
                              Expanded(
                                child: Text(
                                    '${(s['assessments'] as Map?)?['title'] ?? 'Quiz'}',
                                    style: DSText.bodySm,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              DSBadge(
                                tone: DSBadgeTone.mint,
                                child: Text(
                                    '${(s['score'] as num?)?.round() ?? 0}%'),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent activity', style: DSText.title),
                        const SizedBox(height: 8),
                        if (recent.isEmpty)
                          Text('Nothing yet — open a lesson to start tracking.',
                              style: DSText.bodySm
                                  .copyWith(color: DSColors.muted)),
                        for (final r in recent)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text(
                                          '${(r['lessons'] as Map?)?['title'] ?? 'Lesson'}',
                                          style: DSText.bodySm,
                                          overflow:
                                              TextOverflow.ellipsis)),
                                  Text(
                                      '${(r['percent'] as num?)?.round() ?? 0}%',
                                      style: DSText.label),
                                ],
                              ),
                              const SizedBox(height: 4),
                              DSProgressBar(
                                value:
                                    ((r['percent'] as num?) ?? 0) / 100,
                                size: DSProgressBarSize.sm,
                                tone: DSProgressBarTone.sun,
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                  if (empty) ...[
                    const SizedBox(height: 12),
                    const DSCard(
                      child: DSEmptyState(
                        icon: DSIconName.progress,
                        title: 'No progress yet',
                        body: 'Finish a lesson or quiz to start tracking.',
                      ),
                    ),
                  ],
                ],
              ));
            },
          ),
        ),
      ]),
    );
  }
}
