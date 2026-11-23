import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final prog = ref.watch(progressProvider);
    final recent = ref.watch(recentProvider);
    final pct = ((prog.valueOrNull?['lessons_pct'] ?? 0) as num).toDouble();

    final items = <(String, String, String)>[
      ('My Classes', AppEmoji.school, '/classes'),
      ('Assessment Center', AppEmoji.assessment, '/assessments'),
      ('Review Center', AppEmoji.review, '/review'),
      ('Progress Tracker', AppEmoji.progress, '/progress'),
      ('Account', AppEmoji.account, '/account'),
    ];

    return ListView(padding: EdgeInsets.zero, children: [
      MaxWidth(child: Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 8),
        child: Row(children: [
          const UserAvatar(radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome, ${me.valueOrNull?['full_name'] ?? ''}!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text('Keep learning, keep growing!', style: TextStyle(color: AppColors.muted)),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppCard(
            child: Row(children: [
              RingChart(pct / 100, color: AppColors.blue, size: 92, stroke: 9, label: '${pct.round()}%'),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your Learning Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Average lesson completion', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.extent(
            maxCrossAxisExtent: 170, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1,
            children: [
              for (final it in items)
                AppCard(
                  padding: const EdgeInsets.all(8),
                  onTap: () => const ['/classes', '/progress', '/account'].contains(it.$3) ? context.go(it.$3) : context.push(it.$3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    EmojiIcon(it.$2, size: 44),
                    const SizedBox(height: 8),
                    Text(it.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const _MyClassesCard(),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () => context.go('/progress'),
              child: Text('View All', style: TextStyle(color: AppColors.blue)),
            ),
          ]),
          if (recent.hasValue && (recent.valueOrNull ?? const <Json>[]).isEmpty)
            const AppCard(child: EmptyState(icon: AppIcons.history, title: 'No activity yet', message: 'Open a lesson to get started.')),
          for (final r in recent.valueOrNull ?? const <Json>[])
            AppCard(
              child: Row(children: [
                Icon(r['percent'] == 100 ? AppIcons.done : AppIcons.pending,
                    color: r['percent'] == 100 ? AppColors.success : AppColors.orange),
                const SizedBox(width: 10),
                Expanded(child: Text('${r['lessons']?['title'] ?? 'Lesson'}\n${r['percent'] == 100 ? 'Completed' : 'In progress'} â€¢ ${r['percent']}%')),
              ]),
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
  final _code = TextEditingController();
  bool _busy = false;
  String? _msg;
  bool _err = false;
  int _refresh = 0;

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _join() async {
    setState(() { _busy = true; _msg = null; });
    try {
      final r = await ref.read(repoProvider).joinClass(_code.text.trim());
      _code.clear();
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
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('My Classes', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Enter class code', isDense: true),
          )),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _busy || _code.text.trim().isEmpty ? null : _join,
            child: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Join'),
          ),
        ]),
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_msg!, style: TextStyle(
                fontSize: 12,
                color: _err ? Theme.of(context).colorScheme.error : AppColors.success)),
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
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              );
            }
            return Column(children: [
              const SizedBox(height: 10),
              for (final e in snap.data!)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    Icon(AppIcons.students, size: 16,
                        color: e['status'] == 'active' ? AppColors.blue : AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${e['classes']?['name'] ?? 'Class'}')),
                    if (e['status'] == 'pending')
                      const Text('Pending', style: TextStyle(fontSize: 11, color: AppColors.orange)),
                  ]),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}
