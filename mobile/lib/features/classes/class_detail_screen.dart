import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import '../lessons/lesson_thumb.dart';

final _classLessonsProvider = FutureProvider.autoDispose
    .family<List<Json>, String>(
        (ref, id) => ref.read(repoProvider).lessons(classId: id));

/// Student view of one class: the lessons inside it with per-lesson progress.
class StudentClassScreen extends ConsumerWidget {
  final String classId;
  final String name;
  const StudentClassScreen(
      {super.key, required this.classId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(_classLessonsProvider(classId));
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
              Expanded(child: Text(name, style: DSText.h2)),
            ]),
          ),
        ),
        Expanded(
            child: lessons.when(
          loading: () => const Center(child: DSLoadingIndicator()),
          error: (e, _) => DSEmptyState(
            icon: DSIconName.offline,
            title: "Couldn't load this right now",
            body: 'Check your connection and try again.',
            action: DSButton(
              variant: DSButtonVariant.outline,
              size: DSButtonSize.sm,
              leadingIcon: DSIconName.retry,
              onPressed: () => ref.invalidate(_classLessonsProvider(classId)),
              child: const Text('Try again'),
            ),
          ),
          data: (rows) => RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(_classLessonsProvider(classId).future),
            child: rows.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    DSEmptyState(
                        icon: DSIconName.lessons,
                        title: 'No lessons here yet',
                        body:
                            'Your teacher has not published lessons for this class.'),
                  ])
                : MaxWidth(
                    child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final l = rows[i];
                      final lp = (l['lesson_progress'] as List?) ?? [];
                      final pct = lp.isEmpty ? 0 : (lp.first['percent'] as int);
                      return DSListItemCard(
                        onTap: () => context.push('/lesson/${l['id']}'),
                        leading: LessonThumb(
                            thumbKey: l['thumbnail_key'] as String?),
                        title: Text(l['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Objectives: ${l['objectives']}',
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(children: [
                              Expanded(
                                  child: DSProgressBar(
                                value: pct / 100,
                                size: DSProgressBarSize.sm,
                              )),
                              const SizedBox(width: 8),
                              Text('$pct%'),
                            ]),
                          ],
                        ),
                        trailing: const DSIcon(DSIconName.chevron,
                            color: DSColors.muted),
                      );
                    },
                  )),
          ),
        )),
      ]),
    );
  }
}
