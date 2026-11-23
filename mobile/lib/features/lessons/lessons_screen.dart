import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ref.watch(subjectProvider);
    final lessons = ref.watch(lessonsProvider);
    const subjects = [null, 'Physics', 'Chemistry', 'Earth Science'];

    return Scaffold(
      appBar: AppBar(title: const Text('My Lessons')),
      body: MaxWidth(child: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              for (final s in subjects)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s ?? 'All'),
                    selected: subject == s,
                    onSelected: (_) => ref.read(subjectProvider.notifier).state = s,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: lessons.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(onRetry: () => ref.invalidate(lessonsProvider)),
            data: (rows) => RefreshIndicator(
              onRefresh: () async => ref.refresh(lessonsProvider.future),
              child: rows.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 80),
                      EmptyState(icon: AppIcons.lessons, title: 'No lessons here yet',
                          message: 'Try another subject, or check back soon.'),
                    ])
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final l = rows[i];
                  final lp = (l['lesson_progress'] as List?) ?? [];
                  final pct = lp.isEmpty ? 0 : (lp.first['percent'] as int);
                  return AppCard(
                    onTap: () => context.push('/lesson/${l['id']}'),
                    child: Row(children: [
                      LessonThumb(thumbKey: l['thumbnail_key'] as String?),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l['title'], style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('Objectives: ${l['objectives']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          Row(children: [Expanded(child: Bar(pct / 100)), const SizedBox(width: 8), Text('$pct%')]),
                        ]),
                      ),
                      Icon(AppIcons.chevron, color: AppColors.muted),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
      ])),
    );
  }
}

/// Lesson thumbnail â€” resolves the R2 object key to a signed URL, then caches
/// the image. Falls back to the science icon when there is no image.
class LessonThumb extends ConsumerWidget {
  final String? thumbKey;
  const LessonThumb({super.key, required this.thumbKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    Widget fallback() => Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
          child: Icon(AppIcons.science, size: 30, color: AppColors.muted),
        );
    if (thumbKey == null || thumbKey!.isEmpty) return fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<String?>(
        future: repo.signedUrl(thumbKey),
        builder: (_, snap) => snap.data == null
            ? fallback()
            : CachedNetworkImage(
                imageUrl: snap.data!,
                width: 64, height: 64, fit: BoxFit.cover,
                placeholder: (_, __) => fallback(),
                errorWidget: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}
