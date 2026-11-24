import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ref.watch(subjectProvider);
    final lessons = ref.watch(lessonsProvider);
    const subjects = ['all', 'Physics', 'Chemistry', 'Earth Science'];

    return Scaffold(
      body: MaxWidth(child: Column(children: [
        DSPageHeader(
          compact: true,
          child: SafeArea(
            bottom: false,
            child: Text('My lessons', style: DSText.h2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: DSSegmentedControl(
            options: [for (final s in subjects) DSSegment(s, s == 'all' ? 'All' : s)],
            value: subject ?? 'all',
            onChanged: (v) =>
                ref.read(subjectProvider.notifier).state = v == 'all' ? null : v,
          ),
        ),
        Expanded(
          child: lessons.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => DSEmptyState(
              icon: DSIconName.offline,
              title: "Couldn't load this right now",
              body: 'Check your connection and try again.',
              action: DSButton(
                variant: DSButtonVariant.outline,
                size: DSButtonSize.sm,
                leadingIcon: DSIconName.retry,
                onPressed: () => ref.invalidate(lessonsProvider),
                child: const Text('Try again'),
              ),
            ),
            data: (rows) => RefreshIndicator(
              onRefresh: () async => ref.refresh(lessonsProvider.future),
              child: rows.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 80),
                      DSEmptyState(icon: DSIconName.lessons, title: 'No lessons here yet',
                          body: 'Try another subject, or check back soon.'),
                    ])
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final l = rows[i];
                  final lp = (l['lesson_progress'] as List?) ?? [];
                  final pct = lp.isEmpty ? 0 : (lp.first['percent'] as int);
                  return GestureDetector(
                    onTap: () => context.push('/lesson/${l['id']}'),
                    child: DSCard(
                      child: Row(children: [
                        LessonThumb(thumbKey: l['thumbnail_key'] as String?),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l['title'], style: DSText.title),
                            Text('Objectives: ${l['objectives']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: DSText.caption.copyWith(color: DSColors.muted)),
                            const SizedBox(height: 6),
                            Row(children: [
                              Expanded(child: DSProgressBar(
                                value: pct / 100,
                                size: DSProgressBarSize.sm,
                              )),
                              const SizedBox(width: 8),
                              Text('$pct%', style: DSText.caption),
                            ]),
                          ]),
                        ),
                        const DSIcon(DSIconName.chevron, color: DSColors.muted),
                      ]),
                    ),
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

/// Lesson thumbnail — resolves the R2 object key to a signed URL, then caches
/// the image. Falls back to the science icon when there is no image.
class LessonThumb extends ConsumerWidget {
  final String? thumbKey;
  const LessonThumb({super.key, required this.thumbKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    Widget fallback() => Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: DSColors.track, borderRadius: DSRadii.chipBr),
          child: const DSIcon(DSIconName.science, size: 30, color: DSColors.muted),
        );
    if (thumbKey == null || thumbKey!.isEmpty) return fallback();
    return ClipRRect(
      borderRadius: DSRadii.chipBr,
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
