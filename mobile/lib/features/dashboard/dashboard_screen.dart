import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final prog = ref.watch(progressProvider);
    final recent = ref.watch(recentProvider);
    final pct = ((prog.valueOrNull?['lessons_pct'] ?? 0) as num).toDouble();

    const items = <(String, DSIconName, String, DSCardPastel)>[
      ('My Classes', DSIconName.school, '/classes', DSCardPastel.blue),
      (
        'Assessment Center',
        DSIconName.assessment,
        '/assessments',
        DSCardPastel.yellow
      ),
      ('Review Center', DSIconName.review, '/review', DSCardPastel.purple),
      ('Progress Tracker', DSIconName.progress, '/progress', DSCardPastel.mint),
      ('Account', DSIconName.account, '/account', DSCardPastel.blue),
    ];

    return ListView(padding: EdgeInsets.zero, children: [
      MaxWidth(
          child: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.paddingOf(context).top + 20, 20, 8),
          child: Row(children: [
            const UserAvatar(radius: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome, ${me.valueOrNull?['full_name'] ?? ''}!',
                        style: DSText.h3),
                    Text('Keep learning, keep growing!',
                        style: DSText.bodySm.copyWith(color: DSColors.muted)),
                  ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DSCard(
              child: Row(children: [
                DSRingChart(
                  size: 92,
                  thickness: 9,
                  slices: [
                    DSRingSlice(pct, series: 1),
                    DSRingSlice(100 - pct, series: 0),
                  ],
                  center: Text('${pct.round()}%', style: DSText.title),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Learning Progress', style: DSText.title),
                        const SizedBox(height: 4),
                        Text('Average lesson completion',
                            style:
                                DSText.caption.copyWith(color: DSColors.muted)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Text('Quick Access', style: DSText.h3),
            const SizedBox(height: 10),
            GridView.extent(
              maxCrossAxisExtent: 170,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              children: [
                for (final it in items)
                  GestureDetector(
                    onTap: () => const ['/classes', '/progress', '/account']
                            .contains(it.$3)
                        ? context.go(it.$3)
                        : context.push(it.$3),
                    child: DSCard(
                      variant: DSCardVariant.pastel,
                      pastel: it.$4,
                      tilt: true,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DSIcon(it.$2, size: 36, color: DSColors.navy),
                            const SizedBox(height: 8),
                            Text(it.$1,
                                textAlign: TextAlign.center,
                                style: DSText.label),
                          ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _MyClassesCard(),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text('Recent Activity',
                      style: DSText.title, overflow: TextOverflow.ellipsis)),
              DSButton(
                variant: DSButtonVariant.outline,
                size: DSButtonSize.sm,
                onPressed: () => context.go('/progress'),
                child: const Text('View all'),
              ),
            ]),
            const SizedBox(height: 10),
            if (recent.hasValue &&
                (recent.valueOrNull ?? const <Json>[]).isEmpty)
              const DSCard(
                  child: DSEmptyState(
                      icon: DSIconName.history,
                      title: 'No activity yet',
                      body: 'Open a lesson to get started.')),
            for (final r in recent.valueOrNull ?? const <Json>[])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DSListItemCard(
                  leading: DSIcon(
                      r['percent'] == 100
                          ? DSIconName.done
                          : DSIconName.pending,
                      color: r['percent'] == 100
                          ? DSColors.success
                          : DSColors.sun),
                  title: Text('${r['lessons']?['title'] ?? 'Lesson'}'),
                  subtitle: Text(
                      '${r['percent'] == 100 ? 'Completed' : 'In progress'} • ${r['percent']}%'),
                ),
              ),
          ]),
        ),
      ])),
    ]);
  }
}

/// Join a class by code + list enrolled classes. Mirrors web MyClasses.
class _MyClassesCard extends ConsumerStatefulWidget {
  const _MyClassesCard();
  @override
  ConsumerState<_MyClassesCard> createState() => _MyClassesState();
}

class _MyClassesState extends ConsumerState<_MyClassesCard> {
  String _code = '';
  bool _busy = false;
  String? _msg;
  bool _err = false;
  int _refresh = 0;

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final r = await ref.read(repoProvider).joinClass(_code.trim());
      _code = '';
      _msg = r['status'] == 'pending'
          ? 'Request sent to ${r['name']}, waiting for teacher approval'
          : 'Joined ${r['name']}';
      _err = false;
      _refresh++;
    } catch (e) {
      _msg = '$e'.replaceFirst('Exception: ', '');
      _err = true;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DSCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('My Classes', style: DSText.title),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: DSCodeInput(
              value: _code,
              onChanged: (v) => setState(() => _code = v),
              enabled: !_busy,
            )),
            const SizedBox(width: 8),
            DSButton(
              loading: _busy,
              disabled: _busy || _code.trim().isEmpty,
              onPressed: _join,
              child: const Text('Join'),
            ),
          ]),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_msg!,
                  style: DSText.caption.copyWith(
                      color: _err ? DSColors.error : DSColors.success)),
            ),
        ]),
      ),
      FutureBuilder<List<Json>>(
        key: ValueKey(_refresh),
        future: ref.read(repoProvider).enrolledClasses(),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          if (snap.data!.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Not in any class yet. Get a code from your teacher.',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
            );
          }
          return Column(children: [
            const SizedBox(height: 10),
            for (final e in snap.data!)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DSListItemCard(
                  pending: e['status'] == 'pending',
                  leading: DSIcon(DSIconName.students,
                      size: 16,
                      color: e['status'] == 'active'
                          ? DSColors.blue
                          : DSColors.muted),
                  title: Text('${e['classes']?['name'] ?? 'Class'}'),
                  trailing: e['status'] == 'pending'
                      ? const DSBadge(
                          tone: DSBadgeTone.sun, child: Text('Pending'))
                      : null,
                ),
              ),
          ]);
        },
      ),
    ]);
  }
}
