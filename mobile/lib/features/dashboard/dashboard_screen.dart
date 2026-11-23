import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    final items = <(String, IconData, Color, String)>[
      ('My Lessons', Icons.menu_book, adaptiveColor(context, AppColors.blue, const Color(0xFF8FB4F8)), '/lessons'),
      ('Assessment Center', Icons.fact_check, adaptiveColor(context, AppColors.teal, const Color(0xFF2DD4BF)), '/assessments'),
      ('Review Center', Icons.style, adaptiveColor(context, AppColors.purple, const Color(0xFFB794F6)), '/review'),
      ('Progress Tracker', Icons.bar_chart, adaptiveColor(context, AppColors.success, const Color(0xFF4ADE80)), '/progress'),
      ('Account', Icons.person, adaptiveColor(context, AppColors.navy, const Color(0xFF8FB4F8)), '/account'),
    ];

    return ListView(padding: EdgeInsets.zero, children: [
      Container(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 24),
        decoration: BoxDecoration(
          color: adaptiveColor(context, AppColors.navy, AppColors.navyDark),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Row(children: [
          const CircleAvatar(radius: 28, child: Icon(Icons.person)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome, ${me.valueOrNull?['full_name'] ?? ''}!',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const Text('Keep learning, keep growing!', style: TextStyle(color: Colors.white70)),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppCard(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your Learning Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${pct.round()}%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  Bar(pct / 100),
                ]),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.emoji_events, color: AppColors.orange, size: 48),
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
                  onTap: () => const ['/lessons', '/progress', '/account'].contains(it.$4) ? context.go(it.$4) : context.push(it.$4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    iconChip(context, it.$2, it.$3, size: 46, iconSize: 26),
                    const SizedBox(height: 6),
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
              child: Text('View All', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          ]),
          if (recent.hasValue && (recent.valueOrNull ?? const <Json>[]).isEmpty)
            const AppCard(child: EmptyState(icon: Icons.history, title: 'No activity yet', message: 'Open a lesson to get started.')),
          for (final r in recent.valueOrNull ?? const <Json>[])
            AppCard(
              child: Row(children: [
                Icon(r['percent'] == 100 ? Icons.check_circle : Icons.timelapse,
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
