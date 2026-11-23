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
            Widget tile(Json a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => context.push('/quiz/${a['id']}?t=${Uri.encodeComponent(a['title'])}'),
                    child: Row(children: [
                      Icon(_icon(a['kind']), color: adaptiveColor(context, AppColors.teal, const Color(0xFF2DD4BF))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a['title'], style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(a['description'] ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ])),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                );
            final tests = rows.where((a) => a['kind'] == 'pre_test' || a['kind'] == 'post_test');
            final quizzes = rows.where((a) => a['kind'] != 'pre_test' && a['kind'] != 'post_test');
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Tests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...tests.map(tile),
              const SizedBox(height: 12),
              const Text('Quizzes & Exercises', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...quizzes.map(tile),
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
}
