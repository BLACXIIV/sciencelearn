import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

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
        _Hero(cls: cls),
        Expanded(
          child: students.when(
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
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.05,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (final r in classRings)
                                Column(children: [
                                  DSRingChart(
                                    size: 72,
                                    thickness: 12,
                                    slices: r.$2 == null
                                        ? const []
                                        : [
                                            DSRingSlice(r.$2!.toDouble(),
                                                series: r.$3),
                                            DSRingSlice(100 - r.$2!.toDouble(),
                                                series: 0),
                                          ],
                                    center: Text(
                                      r.$2 == null ? '—' : '${r.$2!.round()}%',
                                      style:
                                          DSText.label.copyWith(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(r.$1,
                                      style: DSText.caption
                                          .copyWith(color: DSColors.muted)),
                                ]),
                            ],
                          ),
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

/// Navy hero: bleeds to the screen edges — full width, top corners run under
/// the status bar (only the bottom corners round). Content is padded for the
/// status bar instead of wrapping the card in SafeArea.
class _Hero extends StatelessWidget {
  final Json cls;
  const _Hero({required this.cls});

  @override
  Widget build(BuildContext context) {
    // Transparent status bar + light icons — the navy hero shows through it
    // instead of Android's dark scrim strip.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DSColors.navyDeep, DSColors.navy],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          // The 8px edge is a bottom border INSIDE the rect — a boxShadow would
          // overflow into the ListView and get painted over by scrolled cards.
          border: Border(
            bottom: BorderSide(color: DSColors.edgeNavy, width: 8),
          ),
        ),
        // ClipRRect lets the dashed ring bleed past the card edge while still
        // clipping it to the rounded shape; padding lives inside the Stack.
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(30)),
          child: Stack(children: [
            const Positioned(
              top: -45,
              right: -55,
              child: CustomPaint(
                size: Size(170, 170),
                painter: _DashedRingPainter(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.paddingOf(context).top + 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '${cls['name'] ?? 'Class'}',
                          style: DSText.h1
                              .copyWith(fontSize: 28, color: DSColors.surface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _HeroTile(
                        icon: DSIconName.school,
                        label: 'Switch class',
                        onTap: () {
                          currentClass.value = null;
                          classPicked.value = false;
                          context.go('/select-class');
                        },
                      ),
                      const SizedBox(width: 10),
                      _HeroTile(
                        icon: DSIconName.account,
                        label: 'Account',
                        onTap: () => context.push('/teacher/account'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: '${cls['code'] ?? ''}'));
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                              content: Text('Class code copied')));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: DSColors.mint,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: dsEdge(DSColors.edgeMint, h: 4),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                            '${cls['code'] ?? ''}',
                            style: DSText.label.copyWith(
                                fontSize: 15,
                                letterSpacing: 1.8,
                                color: DSColors.navy),
                          ),
                          const SizedBox(width: 8),
                          const DSIcon(DSIconName.copy,
                              size: 15, color: DSColors.navy),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        cls['join_policy'] == 'approval'
                            ? 'Approval required'
                            : 'Instant join',
                        style: DSText.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: DSColors.pastelBlue),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Decorative broken circle bleeding off the hero's top-right corner.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.22);
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width / 2 - 2);
    const dashes = 14;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.65, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}

/// White rounded tile with a navy icon — hero actions on the navy panel.
class _HeroTile extends StatelessWidget {
  final DSIconName icon;
  final String label;
  final VoidCallback onTap;
  const _HeroTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: dsEdge(DSColors.edgeWhite, h: 4),
        ),
        child: Center(child: DSIcon(icon, size: 22, color: DSColors.navy)),
      ),
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
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: DSText.label.copyWith(fontSize: 13, color: DSColors.navy)),
    );
  }
}
