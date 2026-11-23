import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../lessons/lessons_screen.dart';

final _classLessonsProvider = FutureProvider.autoDispose
    .family<List<Json>, String>((ref, id) => ref.read(repoProvider).lessons(classId: id));

/// Student view of one class: the lessons inside it with per-lesson progress.
class StudentClassScreen extends ConsumerWidget {
  final String classId;
  final String name;
  const StudentClassScreen({super.key, required this.classId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(_classLessonsProvider(classId));
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: lessons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(onRetry: () => ref.invalidate(_classLessonsProvider(classId))),
        data: (rows) => RefreshIndicator(
          onRefresh: () async => ref.refresh(_classLessonsProvider(classId).future),
          child: rows.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 80),
                  EmptyState(icon: AppIcons.lessons, title: 'No lessons here yet',
                      message: 'Your teacher has not published lessons for this class.'),
                ])
              : MaxWidth(child: ListView.separated(
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
                )),
        ),
      ),
    );
  }
}
