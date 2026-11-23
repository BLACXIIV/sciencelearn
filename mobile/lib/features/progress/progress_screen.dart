import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

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

    final rings = <(String, double, Color)>[
      ('Lessons', lessons / 100, AppColors.yellow),
      ('Quizzes', quizzes / 100, AppColors.blue),
      ('Pre-Test', (pre?.toDouble() ?? 0) / 100, AppColors.pink),
      ('Post-Test', (post?.toDouble() ?? 0) / 100, AppColors.teal),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracker')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Overall Progress', style: Theme.of(context).textTheme.titleMedium),
        Text('${overall.round()}%', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final r in rings)
                Column(children: [
                  RingChart(r.$2, color: r.$3, size: 56, stroke: 6),
                  const SizedBox(height: 6),
                  Text(r.$1, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Score breakdown', style: TextStyle(fontWeight: FontWeight.w700)),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            BreakdownRow(color: AppColors.yellow, percent: '${lessons.round()}%', label: 'Lessons completed', value: '${lessons.round()} / 100'),
            BreakdownRow(color: AppColors.blue, percent: '${quizzes.round()}%', label: 'Quiz average', value: quizzes > 0 ? '${quizzes.round()}' : '-'),
            BreakdownRow(color: AppColors.pink, percent: pre == null ? '-' : '${pre.round()}%', label: 'Pre-Test', value: pre == null ? '-' : '${pre.round()}'),
            BreakdownRow(color: AppColors.teal, percent: post == null ? '-' : '${post.round()}%', label: 'Post-Test', value: post == null ? '-' : '${post.round()}'),
            if (gain != null)
              BreakdownRow(color: AppColors.success, percent: '', label: 'Learning gain', value: '${gain >= 0 ? '+' : ''}$gain%'),
          ]),
        ),
      ]),
    );
  }
}
