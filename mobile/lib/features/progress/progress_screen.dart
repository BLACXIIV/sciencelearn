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

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracker')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          child: Row(children: [
            SizedBox(
              width: 110, height: 110,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: overall / 100, strokeWidth: 12, color: AppColors.green, backgroundColor: const Color(0xFFE2E8F0)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${overall.round()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const Text('Overall', style: TextStyle(fontSize: 11)),
                ]),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(children: [
              _row('Lessons', lessons, AppColors.green),
              _row('Quizzes', quizzes, AppColors.blue),
              _row('Post-Test', post?.toDouble() ?? 0, AppColors.orange),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Assessment Results', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _col('Pre-Test', pre?.toDouble() ?? 0, AppColors.blue),
                _col('Post-Test', post?.toDouble() ?? 0, AppColors.green),
                if (gain != null)
                  Text('${gain >= 0 ? '+' : ''}$gain% Gain',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.green)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _row(String l, double v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(l)),
          Text(v == 0 && l == 'Post-Test' ? '–' : '${v.round()}%'),
        ]),
      );

  Widget _col(String l, double v, Color c) => Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text('${v.round()}%'),
        Container(width: 48, height: v * 1.0, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 4),
        Text(l, style: const TextStyle(fontSize: 11)),
      ]);
}
