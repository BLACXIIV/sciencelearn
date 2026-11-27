import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'class_portal_header.dart';
import 'lesson_activities_screen.dart';

/// Create Quiz: quizzes attach to lessons, so this tab is the lesson picker —
/// tapping a lesson opens its full activity/question builder.
class ClassQuizScreen extends ConsumerWidget {
  const ClassQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cls = currentClass.value;
    if (cls == null) return const Scaffold(body: SizedBox.shrink());
    final classId = '${cls['id']}';
    final lessons = ref.watch(classLessonsProvider(classId));

    return Scaffold(
      body: Column(children: [
        ClassHeroHeader(cls: cls),
        Expanded(
            child: MaxWidth(
                child: ListView(padding: const EdgeInsets.all(16), children: [
          DSCard(
              child: Row(children: [
            const DSIcon(DSIconName.quiz, size: 22, color: DSColors.blue),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              'Quizzes attach to lessons — pick the lesson this quiz is for.',
              style: DSText.bodySm.copyWith(color: DSColors.muted),
            )),
          ])),
          const SizedBox(height: 16),
          lessons.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: DSLoadingIndicator())),
            error: (e, _) => DSEmptyState(
              icon: DSIconName.offline,
              title: "Couldn't load this right now",
              body: 'Check your connection and try again.',
              action: DSButton(
                variant: DSButtonVariant.outline,
                size: DSButtonSize.sm,
                leadingIcon: DSIconName.retry,
                onPressed: () => ref.invalidate(classLessonsProvider(classId)),
                child: const Text('Try again'),
              ),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return DSCard(
                    child: DSEmptyState(
                  icon: DSIconName.lessons,
                  title: 'No lessons yet',
                  body: 'Create a lesson first, then build its quizzes here.',
                  action: DSButton(
                    onPressed: () => context.go('/teacher/lessons'),
                    child: const Text('Go to Lessons'),
                  ),
                ));
              }
              return Column(children: [
                for (final l in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DSListItemCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => LessonActivitiesScreen(lesson: l))),
                      leading: const DSIcon(DSIconName.assessment, size: 22),
                      title: Text('${l['title']}'),
                      subtitle: Row(children: [
                        Flexible(
                            child: Text('${l['subject']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        DSStatusBadge(
                            status: l['is_published'] == true
                                ? DSStatus.published
                                : DSStatus.draft),
                      ]),
                      trailing: const DSIcon(DSIconName.chevron,
                          size: 20, color: DSColors.muted),
                    ),
                  ),
              ]);
            },
          ),
        ]))),
      ]),
    );
  }
}
