import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

/// Per-student progress — same rows as the dashboard list, full-screen.
class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(classProgressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: students.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(onRetry: () => ref.invalidate(classProgressProvider)),
        data: (rows) => rows.isEmpty
            ? const EmptyState(icon: Icons.groups_outlined, title: 'No students yet')
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final s = rows[i];
                  final pct = ((s['lessons_pct'] as num?) ?? 0).toDouble();
                  return AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${s['full_name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: Bar(pct / 100)),
                        const SizedBox(width: 8),
                        Text('${pct.round()}%'),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        'Quizzes ${s['quizzes_pct'] ?? '–'}% · Pre ${s['pre_score'] ?? '–'} → Post ${s['post_score'] ?? '–'}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}
