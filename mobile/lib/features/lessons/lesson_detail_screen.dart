import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

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
          body: Column(children: [
            DSPageHeader(
              compact: true,
              child: SafeArea(
                bottom: false,
                child: Row(children: [
                  DSIconButton(
                    icon: DSIconName.back,
                    label: 'Back',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l?['title'] ?? 'Lesson',
                        style: DSText.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: l == null
                  ? (snap.hasError
                      ? const DSEmptyState(
                          icon: DSIconName.offline,
                          title: "Couldn't load this right now",
                          body: 'Check your connection and try again.',
                        )
                      : const Center(child: CircularProgressIndicator()))
                  : MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
                      DSCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l['title'], style: DSText.h2),
                        const SizedBox(height: 8),
                        Text('Objectives: ${l['objectives']}', style: DSText.body),
                        const DSDivider(spacing: 16),
                        Text(l['content_md'] ?? '', style: DSText.body),
                        const SizedBox(height: 24),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          if (l['content_key'] != null)
                            DSButton(
                              variant: DSButtonVariant.outline,
                              leadingIcon: DSIconName.openExternal,
                              onPressed: () async {
                                final url = await repo.signedUrl(l['content_key']); // R2 signed URL
                                if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              },
                              child: const Text('Open lesson material'),
                            ),
                          DSButton(
                            onPressed: () async {
                              await repo.setProgress(id, 100);
                              ref.invalidate(lessonsProvider);
                              ref.invalidate(progressProvider);
                              ref.invalidate(recentProvider);
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            child: const Text('Mark as completed'),
                          ),
                        ]),
                      ])),
                      _Activities(lessonId: id, repo: repo),
                    ])),
            ),
          ]),
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
          Text('Activities', style: DSText.h3),
          const SizedBox(height: 8),
          for (final a in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DSListItemCard(
                onTap: () => context.push('/quiz/${a['id']}?t=${Uri.encodeComponent('${a['title']}')}'),
                leading: DSIcon(_icon('${a['kind']}'), size: 20, color: DSColors.blue),
                title: Text('${a['title']}'),
                subtitle: Text('${a['description'] ?? ''}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (scores.containsKey('${a['id']}'))
                    DSBadge(tone: DSBadgeTone.mint,
                        child: Text('${scores['${a['id']}']!.round()}%')),
                  const SizedBox(width: 6),
                  const DSIcon(DSIconName.chevron, color: DSColors.muted),
                ]),
              ),
            ),
        ]);
      },
    );
  }

  DSIconName _icon(String kind) => switch (kind) {
        'pre_test' => DSIconName.preTest,
        'post_test' => DSIconName.postTest,
        'problem_solving' => DSIconName.puzzle,
        'final_challenge' => DSIconName.award,
        _ => DSIconName.quiz,
      };
}
