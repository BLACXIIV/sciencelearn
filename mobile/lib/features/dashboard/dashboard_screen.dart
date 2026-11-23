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
      ('My Lessons', AppEmoji.lessons, '/lessons'),
      ('Assessment Center', AppEmoji.assessment, '/assessments'),
      ('Review Center', AppEmoji.review, '/review'),
      ('Progress Tracker', AppEmoji.progress, '/progress'),
      ('Account', AppEmoji.account, '/account'),
    ];

    return ListView(padding: EdgeInsets.zero, children: [
      Padding(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 8),
        child: Row(children: [
          const UserAvatar(radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome, ${me.valueOrNull?['full_name'] ?? ''}!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Text('Keep learning, keep growing!', style: TextStyle(color: AppColors.muted)),
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
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your Learning Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Average lesson completion', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1,
            children: [
              for (final it in items)
                AppCard(
                  padding: const EdgeInsets.all(8),
                  onTap: () => const ['/lessons', '/progress', '/account'].contains(it.$3) ? context.go(it.$3) : context.push(it.$3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    EmojiIcon(it.$2, size: 44),
                    const SizedBox(height: 8),
                    Text(it.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () => context.go('/progress'),
              child: const Text('View All', style: TextStyle(color: AppColors.blue)),
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
                Expanded(child: Text('${r['lessons']?['title'] ?? 'Lesson'}\n${r['percent'] == 100 ? 'Completed' : 'In progress'} • ${r['percent']}%')),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
