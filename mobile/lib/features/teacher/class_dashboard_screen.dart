import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/bento.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'class_portal_header.dart';

/// Class-scoped dashboard (mobile): navy class hero (switch + account tiles),
/// pastel stat tiles + pending-request alert card, class-average rings, then
/// the students who need attention. Roster detail lives in Students.
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
        ClassHeroHeader(cls: cls),
        Expanded(
          child: students.when(
            loading: () => const Center(child: DSLoadingIndicator()),
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
              final scored =
                  rows.where((s) => s['quizzes_pct'] != null).toList();
              final avg = scored.isEmpty
                  ? null
                  : (scored.fold<num>(
                              0, (a, s) => a + (s['quizzes_pct'] as num)) /
                          scored.length)
                      .round();
              final both = rows
                  .where(
                      (s) => s['pre_score'] != null && s['post_score'] != null)
                  .toList();
              final gain = both.isEmpty
                  ? null
                  : (both.fold<num>(
                              0,
                              (a, s) =>
                                  a +
                                  ((s['post_score'] as num) -
                                      (s['pre_score'] as num))) /
                          both.length)
                      .round();
              final memberList = members.valueOrNull ?? [];
              final active =
                  memberList.where((m) => m['status'] == 'active').length;
              final pending =
                  memberList.where((m) => m['status'] == 'pending').length;
              num? avgOf(String key) {
                final have =
                    rows.map((s) => s[key] as num?).whereType<num>().toList();
                return have.isEmpty
                    ? null
                    : have.fold<num>(0, (a, b) => a + b) / have.length;
              }

              // Mockup: Lessons ring is sun (series 1), the others blue (series 2).
              final classRings = <(String, num?, int)>[
                ('Lessons', avgOf('lessons_pct'), 1),
                ('Quizzes', avgOf('quizzes_pct'), 2),
                ('Pre-test', avgOf('pre_score'), 2),
                ('Post-test', avgOf('post_score'), 2),
              ];

              // Lowest scores first; nulls (no attempts) sort below 0.
              final attention = [...rows]..sort((a, b) =>
                  ((a['quizzes_pct'] as num?) ?? -1)
                      .compareTo((b['quizzes_pct'] as num?) ?? -1));
              final flagged = attention
                  .where((r) =>
                      r['quizzes_pct'] == null ||
                      (r['quizzes_pct'] as num) < 70)
                  .take(5)
                  .toList();

              return MaxWidth(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    BentoGrid(
                      minWidth: 160,
                      gap: 10,
                      children: [
                        DSStatCard(
                          filled: true,
                          pastel: DSStatPastel.blue,
                          icon: DSIconName.students,
                          value: '$active',
                          label: 'Students',
                          note: '$active active',
                        ),
                        DSStatCard(
                          filled: true,
                          pastel: DSStatPastel.mint,
                          icon: DSIconName.done,
                          value: '${completed.valueOrNull ?? 0}',
                          label: 'Completed',
                          note: 'Lesson completions',
                        ),
                        DSStatCard(
                          filled: true,
                          pastel: DSStatPastel.purple,
                          icon: DSIconName.progress,
                          value: avg == null ? '—' : '$avg%',
                          label: 'Quiz average',
                          note: scored.isEmpty
                              ? 'No attempts yet'
                              : '${scored.length} attempted',
                        ),
                        DSStatCard(
                          filled: true,
                          pastel: DSStatPastel.yellow,
                          icon: DSIconName.gain,
                          value: gain == null
                              ? '—'
                              : '${gain >= 0 ? '+' : ''}$gain%',
                          label: 'Class gain',
                          note: both.isEmpty
                              ? 'Needs pre and post'
                              : 'Pre → post',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _PendingCard(
                      count: pending,
                      onReview: () => context.go('/teacher/students'),
                    ),
                    const SizedBox(height: 20),
                    DSCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class averages', style: DSText.title),
                          const SizedBox(height: 12),
                          Row(children: [
                            for (final r in classRings)
                              Expanded(
                                child: Column(children: [
                                  // FittedBox scales the fixed 72px ring down
                                  // to its share — 4×72 overflows ~320px cards.
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: DSRingChart(
                                        size: 72,
                                        thickness: 12,
                                        slices: r.$2 == null
                                            ? const []
                                            : [
                                                DSRingSlice(r.$2!.toDouble(),
                                                    series: r.$3),
                                                DSRingSlice(
                                                    100 - r.$2!.toDouble(),
                                                    series: 0),
                                              ],
                                        center: Text(
                                          r.$2 == null
                                              ? '—'
                                              : '${r.$2!.round()}%',
                                          style: DSText.label
                                              .copyWith(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(r.$1,
                                      style: DSText.caption
                                          .copyWith(color: DSColors.muted),
                                      overflow: TextOverflow.ellipsis),
                                ]),
                              ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: Text('Needs attention', style: DSText.title)),
                      GestureDetector(
                        onTap: () => context.go('/teacher/students'),
                        child: Text('All students',
                            style: DSText.label.copyWith(color: DSColors.blue)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    if (flagged.isEmpty)
                      DSCard(
                        child: Column(children: [
                          const DSEmptyState(
                              icon: DSIconName.done,
                              title: "Everyone's on track",
                              body:
                                  'No students are behind on quizzes right now.'),
                          // Empty-state art — swap the PNG for the final SVG when it lands.
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Image.asset(
                              'assets/illustrations/needs_attention.png',
                              width: 140,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ]),
                      ),
                    for (final s in flagged)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DSListItemCard(
                          leading: DSAvatar(name: '${s['full_name'] ?? '?'}'),
                          title: Text('${s['full_name']}'),
                          subtitle: Text(s['quizzes_pct'] == null
                              ? 'No quiz attempts yet'
                              : 'Quiz average ${(s['quizzes_pct'] as num).round()}%'),
                          trailing: s['quizzes_pct'] == null
                              ? const _SoftChip('—')
                              : DSBadge(
                                  tone: DSBadgeTone.sun,
                                  child: Text(
                                      '${(s['quizzes_pct'] as num).round()}%'),
                                ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Sun-bordered action tile: icon + count/label on the left, Review on the
/// right (mockup's horizontal pending-request card — not a stacked stat tile).
class _PendingCard extends StatelessWidget {
  final int count;
  final VoidCallback onReview;
  const _PendingCard({required this.count, required this.onReview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSRadii.cardBr,
        border: Border.all(color: DSColors.sun, width: 3),
        boxShadow: dsEdge(DSColors.edgeCard, h: 6),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DSColors.pastelYellow,
            borderRadius: DSRadii.inputBr,
          ),
          child: const Center(
            child: DSIcon(DSIconName.pending, size: 22, color: DSColors.navy),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count',
                  style:
                      DSText.h3.copyWith(fontSize: 22, color: DSColors.navy)),
              Text(count == 1 ? 'Pending request' : 'Pending requests',
                  style: DSText.bodySm.copyWith(
                      fontWeight: FontWeight.w600, color: DSColors.inkSoft)),
            ],
          ),
        ),
        DSButton(
          variant: DSButtonVariant.sun,
          size: DSButtonSize.sm,
          onPressed: onReview,
          child: const Text('Review'),
        ),
      ]),
    );
  }
}

/// Pale-sun "—" chip for students with no attempts yet.
class _SoftChip extends StatelessWidget {
  final String text;
  const _SoftChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DSColors.pastelYellow,
        borderRadius: DSRadii.pillBr,
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: DSText.label.copyWith(fontSize: 13, color: DSColors.navy)),
    );
  }
}
