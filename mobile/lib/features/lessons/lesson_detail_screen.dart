import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

class LessonDetailScreen extends ConsumerWidget {
  final String id;
  const LessonDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    return FutureBuilder<Json>(
      future: repo.lesson(id),
      builder: (context, snap) {
        final l = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(l?['title'] ?? 'Lesson')),
          body: l == null
              ? (snap.hasError ? const ErrorState() : const Center(child: CircularProgressIndicator()))
              : MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
                  Text(l['title'], style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Objectives: ${l['objectives']}'),
                  const Divider(height: 32),
                  Text(l['content_md'] ?? ''),
                  const SizedBox(height: 24),
                  if (l['content_key'] != null)
                    OutlinedButton.icon(
                      icon: const Icon(AppIcons.openExternal),
                      label: const Text('Open lesson material'),
                      onPressed: () async {
                        final url = await repo.signedUrl(l['content_key']); // R2 signed URL
                        if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                    ),
                  const SizedBox(height: 8),
                  _Activities(lessonId: id, repo: repo),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      await repo.setProgress(id, 100);
                      ref.invalidate(lessonsProvider);
                      ref.invalidate(progressProvider);
                      ref.invalidate(recentProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Mark as completed'),
                  ),
                ])),
        );
      },
    );
  }
}

/// Published activities attached to this lesson (quizzes, tests, exercises).
class _Activities extends StatelessWidget {
  final String lessonId;
  final Repo repo;
  const _Activities({required this.lessonId, required this.repo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({List<Json> rows, Map<String, num> scores})>(
      future: (() async => (
        rows: await repo.lessonActivities(lessonId),
        scores: await repo.myAttemptScores(),
      ))(),
      builder: (context, snap) {
        final rows = snap.data?.rows ?? const <Json>[];
        final scores = snap.data?.scores ?? const <String, num>{};
        if (rows.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          const Text('Activities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final a in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                onTap: () => context.push('/quiz/${a['id']}?t=${Uri.encodeComponent('${a['title']}')}'),
                child: Row(children: [
                  Icon(_icon('${a['kind']}'), size: 20, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${a['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${a['description'] ?? ''}',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ])),
                  if (scores.containsKey('${a['id']}'))
                    _ScoreChip('${scores['${a['id']}']!.round()}%'),
                  Icon(AppIcons.chevron, color: AppColors.muted),
                ]),
              ),
            ),
        ]);
      },
    );
  }

  IconData _icon(String kind) => switch (kind) {
        'pre_test' => AppIcons.preTest,
        'post_test' => AppIcons.postTest,
        'problem_solving' => AppIcons.puzzle,
        'final_challenge' => AppIcons.award,
        _ => AppIcons.quiz,
      };
}

class _ScoreChip extends StatelessWidget {
  final String label;
  const _ScoreChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: pastelBg(context, AppColors.success),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
  );
}
