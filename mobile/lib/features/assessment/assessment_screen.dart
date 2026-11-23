import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

class AssessmentScreen extends ConsumerWidget {
  const AssessmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment Center')),
      body: FutureBuilder<List<Json>>(
        future: repo.assessments(['pre_test', 'post_test', 'topic_quiz', 'problem_solving', 'final_challenge']),
        builder: (context, snap) => AsyncView<List<Json>>(
          snap: snap,
          builder: (rows) {
            final tests = rows.where((a) => a['kind'] == 'pre_test' || a['kind'] == 'post_test').toList();
            final quizzes = rows.where((a) => a['kind'] != 'pre_test' && a['kind'] != 'post_test').toList();
            return ListView(padding: const EdgeInsets.all(16), children: [
              // Pre/Post as the mockup's two pastel hero tiles.
              if (tests.isNotEmpty)
                Row(children: [
                  for (final a in tests) ...[
                    Expanded(child: _TestTile(a: a)),
                    if (a != tests.last) const SizedBox(width: 10),
                  ],
                ]),
              if (tests.isNotEmpty) const SizedBox(height: 18),
              const Text('Quizzes & Exercises', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (quizzes.isEmpty)
                const AppCard(child: EmptyState(icon: Icons.fact_check_outlined, title: 'No quizzes published yet')),
              for (final a in quizzes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => context.push('/quiz/${a['id']}?t=${Uri.encodeComponent(a['title'])}'),
                    child: Row(children: [
                      iconChip(context, _icon(a['kind']), _color(a['kind'])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a['title'], style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(a['description'] ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ])),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }

  IconData _icon(String kind) => switch (kind) {
        'pre_test' => Icons.assignment_outlined,
        'post_test' => Icons.emoji_events_outlined,
        'problem_solving' => Icons.extension,
        'final_challenge' => Icons.check_circle_outline,
        _ => Icons.help_outline,
      };

  Color _color(String kind) => switch (kind) {
        'problem_solving' => AppColors.success,
        'final_challenge' => AppColors.orange,
        _ => AppColors.purple,
      };
}

class _TestTile extends StatelessWidget {
  final Json a;
  const _TestTile({required this.a});

  @override
  Widget build(BuildContext context) {
    final isPre = a['kind'] == 'pre_test';
    final color = isPre ? AppColors.blue : AppColors.orange;
    return AppCard(
      color: pastelBg(context, color),
      onTap: () => context.push('/quiz/${a['id']}?t=${Uri.encodeComponent(a['title'])}'),
      child: Column(children: [
        Icon(isPre ? Icons.assignment_outlined : Icons.emoji_events_outlined, size: 34, color: color),
        const SizedBox(height: 6),
        Text(isPre ? 'Pre-Test' : 'Post-Test', style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(isPre ? 'Before Learning' : 'After Learning',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}
