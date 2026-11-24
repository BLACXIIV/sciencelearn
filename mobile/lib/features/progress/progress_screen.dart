import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider).valueOrNull;
    double n(String k) => ((p?[k] ?? 0) as num).toDouble();
    final lessons = n('lessons_pct'), quizzes = n('quizzes_pct');
    final pre = p?['pre_score'] as num?, post = p?['post_score'] as num?;
    final overall = ((lessons + quizzes + (post?.toDouble() ?? 0)) / 3);
    final gain = (pre != null && post != null) ? (post - pre).round() : null;

    final rings = <(String, double, int)>[
      ('Lessons', lessons / 100, 1),
      ('Quizzes', quizzes / 100, 2),
      ('Pre-test', (pre?.toDouble() ?? 0) / 100, 3),
      ('Post-test', (post?.toDouble() ?? 0) / 100, 4),
    ];
    final breakdown = <(String, double?, String, DSProgressBarTone)>[
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
        'Pre-test',
        pre?.toDouble(),
        pre == null ? '-' : '${pre.round()}%',
        DSProgressBarTone.blue
      ),
      (
        'Post-test',
        post?.toDouble(),
        post == null ? '-' : '${post.round()}%',
        DSProgressBarTone.mint
      ),
    ];

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
            child: MaxWidth(
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
                  Text('Gain = post-test − pre-test', style: DSText.caption),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pre-test', style: DSText.label),
                      Text(pre == null ? '-' : '${pre.round()}%',
                          style: DSText.label),
                    ],
                  ),
                  const SizedBox(height: 4),
                  DSProgressBar(value: (pre?.toDouble() ?? 0) / 100),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Post-test', style: DSText.label),
                      Text(post == null ? '-' : '${post.round()}%',
                          style: DSText.label),
                    ],
                  ),
                  const SizedBox(height: 4),
                  DSProgressBar(
                      value: (post?.toDouble() ?? 0) / 100,
                      tone: DSProgressBarTone.mint),
                  if (gain != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: DSStickerBadge(
                          rotation: -5,
                          child: Text('${gain >= 0 ? '+' : ''}$gain% gain'),
                        ),
                      ),
                    ),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(b.$1, style: DSText.bodySm),
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
            if (p == null) ...[
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
        ))),
      ]),
    );
  }
}
