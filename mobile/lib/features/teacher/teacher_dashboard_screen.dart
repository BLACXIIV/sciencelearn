import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Mirrors the web Dashboard: class stat cards + per-student progress list.
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(classProgressProvider);
    final completed = ref.watch(completedCountProvider);
    final me = ref.watch(meProvider);

    return Scaffold(
      body: Column(children: [
        DSPageHeader(
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Good Day, ${me.valueOrNull?['full_name'] ?? ''}!',
                  style: DSText.h2),
            ),
          ),
        ),
        Expanded(child: students.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => DSEmptyState(
            icon: DSIconName.offline,
            title: "Couldn't load this right now",
            body: 'Check your connection and try again.',
            action: DSButton(
              variant: DSButtonVariant.outline,
              size: DSButtonSize.sm,
              leadingIcon: DSIconName.retry,
              onPressed: () {
                ref.invalidate(classProgressProvider);
                ref.invalidate(completedCountProvider);
              },
              child: const Text('Try again'),
            ),
          ),
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
            final classRings = <(String, double, int)>[
              ('Lessons', (avgOf('lessons_pct') ?? 0) / 100, 1),
              ('Quizzes', (avgOf('quizzes_pct') ?? 0) / 100, 2),
              ('Pre-Test', (avgOf('pre_score') ?? 0) / 100, 3),
              ('Post-Test', (avgOf('post_score') ?? 0) / 100, 4),
            ];
            final stats = <(String, String, DSIconName, DSStatPastel)>[
              ('Total Students', '${rows.length}', DSIconName.students, DSStatPastel.blue),
              ('Completed Lessons', '${completed.valueOrNull ?? 0}', DSIconName.done, DSStatPastel.mint),
              ('Average Score', '$avg%', DSIconName.progress, DSStatPastel.yellow),
              ('Class Gain', '${gain >= 0 ? '+' : ''}$gain%', DSIconName.gain, DSStatPastel.purple),
            ];

            return MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
              GridView.extent(
                maxCrossAxisExtent: 260, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 96,
                children: [
                  for (final s in stats)
                    DSStatCard(icon: s.$3, value: s.$2, label: s.$1, pastel: s.$4),
                ],
              ),
              const SizedBox(height: 20),
              Text('Class Averages', style: DSText.title),
              const SizedBox(height: 8),
              DSCard(
                child: rows.isEmpty
                    ? const DSEmptyState(icon: DSIconName.students, title: 'No student data yet')
                    : Wrap(
                        alignment: WrapAlignment.spaceAround, runSpacing: 12,
                        children: [
                          for (final r in classRings)
                            Column(children: [
                              DSRingChart(
                                size: 56, thickness: 6,
                                slices: [
                                  DSRingSlice(r.$2 * 100, series: r.$3),
                                  DSRingSlice((r.$2 >= 1 ? 0.0 : 1 - r.$2) * 100, series: 0),
                                ],
                                center: Text('${(r.$2 * 100).round()}%', style: DSText.label),
                              ),
                              const SizedBox(height: 6),
                              Text(r.$1, style: DSText.caption.copyWith(color: DSColors.muted)),
                            ]),
                        ]),
              ),
              const SizedBox(height: 20),
              Text('Student Performance', style: DSText.title),
              const SizedBox(height: 8),
              if (rows.isEmpty)
                const DSCard(child: DSEmptyState(icon: DSIconName.students, title: 'No students yet')),
              for (final s in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DSListItemCard(
                    leading: DSAvatar(name: '${s['full_name'] ?? '?'}'),
                    title: Text('${s['full_name']}'),
                    subtitle: Text('Pre ${s['pre_score'] ?? '–'} → Post ${s['post_score'] ?? '–'}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        width: 80,
                        child: DSProgressBar(
                          value: (((s['lessons_pct'] as num?) ?? 0) / 100).clamp(0.0, 1.0),
                          size: DSProgressBarSize.sm,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${((s['lessons_pct'] as num?) ?? 0).round()}%', style: DSText.label),
                    ]),
                  ),
                ),
            ]));
          },
        )),
      ]),
    );
  }
}
