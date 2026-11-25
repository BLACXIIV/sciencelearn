import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'class_portal_header.dart';

/// Class-scoped dashboard: is THIS class on track? Stat cards, class-average
/// rings, then the students who need attention (roster lives in Students).
class ClassDashboardScreen extends ConsumerWidget {
  const ClassDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cls = currentClass.value;
    if (cls == null) return const Scaffold(body: SizedBox.shrink());
    final classId = '${cls['id']}';
    final students = ref.watch(classProgressProvider(classId));
    final members = ref.watch(classMembersProvider(classId));
    final completed = ref.watch(classCompletedProvider(classId));

    return Scaffold(
      body: Column(children: [
        const ClassPortalHeader(),
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
                ref.invalidate(classProgressProvider(classId));
                ref.invalidate(classCompletedProvider(classId));
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
            final pending = (members.valueOrNull ?? [])
                .where((m) => m['status'] == 'pending')
                .length;
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
              ('Students', '${rows.length}', DSIconName.students, DSStatPastel.blue),
              ('Completed', '${completed.valueOrNull ?? 0}', DSIconName.done, DSStatPastel.mint),
              ('Average Score', '$avg%', DSIconName.progress, DSStatPastel.yellow),
              ('Class Gain', '${gain >= 0 ? '+' : ''}$gain%', DSIconName.gain, DSStatPastel.purple),
              ('Requests', '$pending', DSIconName.pending, DSStatPastel.yellow),
            ];

            // Lowest scores first; nulls (no attempts) sort below 0.
            final attention = [...rows]
              ..sort((a, b) => ((a['quizzes_pct'] as num?) ?? -1)
                  .compareTo((b['quizzes_pct'] as num?) ?? -1));
            final flagged = attention
                .where((r) => r['quizzes_pct'] == null || (r['quizzes_pct'] as num) < 70)
                .take(5)
                .toList();

            return MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
              GridView.extent(
                maxCrossAxisExtent: 260, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 142,
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
              Text('Needs attention', style: DSText.title),
              const SizedBox(height: 8),
              if (flagged.isEmpty)
                const DSCard(child: DSEmptyState(
                    icon: DSIconName.done,
                    title: "Everyone's on track",
                    body: 'No students are behind on quizzes right now.')),
              for (final s in flagged)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DSListItemCard(
                    leading: DSAvatar(name: '${s['full_name'] ?? '?'}'),
                    title: Text('${s['full_name']}'),
                    subtitle: Text(s['quizzes_pct'] == null
                        ? 'No quiz attempts yet'
                        : 'Quiz average ${(s['quizzes_pct'] as num).round()}%'),
                  ),
                ),
              if (flagged.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: DSButton(
                    variant: DSButtonVariant.ghost,
                    size: DSButtonSize.sm,
                    onPressed: () => context.go('/teacher/students'),
                    child: const Text('View all students'),
                  ),
                ),
            ]));
          },
        )),
      ]),
    );
  }
}
