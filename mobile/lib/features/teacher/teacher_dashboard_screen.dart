import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

/// Mirrors the web Dashboard: class stat cards + per-student progress list.
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(classProgressProvider);
    final completed = ref.watch(completedCountProvider);
    final me = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Good Day, ${me.valueOrNull?['full_name'] ?? ''}!')),
      body: students.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(onRetry: () {
          ref.invalidate(classProgressProvider);
          ref.invalidate(completedCountProvider);
        }),
        data: (rows) {
          final scored = rows.where((s) => s['quizzes_pct'] != null);
          final avg = scored.isEmpty
              ? 0
              : (scored.fold<num>(0, (a, s) => a + (s['quizzes_pct'] as num)) / scored.length).round();
          final both = rows.where((s) => s['pre_score'] != null && s['post_score'] != null);
          final gain = both.isEmpty
              ? 0
              : (both.fold<num>(0, (a, s) => a + ((s['post_score'] as num) - (s['pre_score'] as num))) /
                      both.length)
                  .round();
          num? avgOf(String key) {
            final have = rows.map((s) => s[key] as num?).whereType<num>().toList();
            return have.isEmpty ? null : have.fold<num>(0, (a, b) => a + b) / have.length;
          }
          final classRings = <(String, double, Color)>[
            ('Lessons', (avgOf('lessons_pct') ?? 0) / 100, AppColors.yellow),
            ('Quizzes', (avgOf('quizzes_pct') ?? 0) / 100, AppColors.blue),
            ('Pre-Test', (avgOf('pre_score') ?? 0) / 100, AppColors.pink),
            ('Post-Test', (avgOf('post_score') ?? 0) / 100, AppColors.teal),
          ];
          final stats = <(String, String, IconData, Color)>[
            ('Total Students', '${rows.length}', AppIcons.students, AppColors.blue),
            ('Completed Lessons', '${completed.valueOrNull ?? 0}', AppIcons.done, AppColors.success),
            ('Average Score', '$avg%', AppIcons.progress, AppColors.orange),
            ('Class Gain', '${gain >= 0 ? '+' : ''}$gain%', AppIcons.gain, AppColors.purple),
          ];

          return ListView(padding: const EdgeInsets.all(16), children: [
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.6,
              children: [
                for (final s in stats)
                  AppCard(child: Row(children: [
                    iconChip(context, s.$3, s.$4),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(s.$1, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(s.$2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    ])),
                  ])),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Class Averages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: rows.isEmpty
                  ? const EmptyState(icon: AppIcons.students, title: 'No student data yet')
                  : Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      for (final r in classRings)
                        Column(children: [
                          RingChart(r.$2, color: r.$3, size: 56, stroke: 6),
                          const SizedBox(height: 6),
                          Text(r.$1, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ]),
                    ]),
            ),
            const SizedBox(height: 20),
            const Text('Student Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const AppCard(child: EmptyState(icon: AppIcons.students, title: 'No students yet')),
            for (final s in rows)
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s['full_name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: Bar(((s['lessons_pct'] as num?) ?? 0) / 100)),
                    const SizedBox(width: 8),
                    Text('${((s['lessons_pct'] as num?) ?? 0).round()}%'),
                  ]),
                  Text('Pre ${s['pre_score'] ?? '–'} → Post ${s['post_score'] ?? '–'}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}
