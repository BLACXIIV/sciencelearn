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
      ('My Lessons', Icons.menu_book, AppColors.blue, '/lessons'),
      ('Assessment Center', Icons.fact_check, Colors.teal, '/assessments'),
      ('Review Center', Icons.star, AppColors.orange, '/review'),
      ('Progress Tracker', Icons.bar_chart, AppColors.green, '/progress'),
      ('Credits', Icons.info, AppColors.blue, '/more'),
    ];

    return ListView(padding: EdgeInsets.zero, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
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
                  onTap: () => const ['/lessons', '/progress', '/more'].contains(it.$4) ? context.go(it.$4) : context.push(it.$4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(it.$2, color: it.$3, size: 30),
                    const SizedBox(height: 6),
                    Text(it.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final r in recent.valueOrNull ?? const <Json>[])
            AppCard(
              child: Row(children: [
                Icon(r['percent'] == 100 ? Icons.check_circle : Icons.timelapse,
                    color: r['percent'] == 100 ? AppColors.green : AppColors.orange),
                const SizedBox(width: 10),
                Expanded(child: Text('${r['lessons']?['title'] ?? 'Lesson'}\n${r['percent'] == 100 ? 'Completed' : 'In progress'} • ${r['percent']}%')),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
