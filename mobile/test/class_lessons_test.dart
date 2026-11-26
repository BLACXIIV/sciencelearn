// Functional test for the redesigned teacher Lessons screen: the card "···"
// menu, the delete guard (blocked with activities, confirmed without), the
// edit sheet and the publish switch's attempt-aware confirm.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sciencelearn/data/repository.dart';
import 'package:sciencelearn/design_system/design_system.dart';
import 'package:sciencelearn/features/teacher/class_lessons_screen.dart';

final _cls = <String, dynamic>{
  'id': 'c1',
  'name': 'test classroom',
  'code': 'WYR5V2',
  'teacher_id': 't1',
  'join_policy': 'approval',
};

Json _lesson({bool published = false}) => {
      'id': 'l1',
      'title': 'Bio',
      'subject': 'Earth Science',
      'objectives': 'cells',
      'is_published': published,
      'class_id': 'c1',
    };

/// Records calls instead of hitting Supabase — the delete/publish paths are
/// what this test is proving.
class _FakeRepo extends Repo {
  int deletes = 0;
  final List<(String, bool)> publishes = [];

  @override
  Future<void> deleteLesson(String lessonId) async => deletes++;

  @override
  Future<void> setPublished(String lessonId, bool publish) async =>
      publishes.add((lessonId, publish));
}

List<Override> _overrides(
  _FakeRepo repo, {
  required Json lesson,
  Map<String, int> activities = const {},
  Map<String, int> attempts = const {},
}) =>
    [
      repoProvider.overrideWithValue(repo),
      meProvider.overrideWith(
          (ref) => {'id': 't1', 'role': 'teacher', 'full_name': 'adrian'}),
      classLessonsProvider.overrideWith((ref, id) => [lesson]),
      lessonActivityCountsProvider.overrideWith((ref, id) => activities),
      lessonAttemptCountsProvider.overrideWith((ref, id) => attempts),
    ];

Widget _app(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: ClassLessonsScreen()),
    );

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.ellipsis));
  await tester.pumpAndSettle();
}

void main() {
  const defaultSubjects = ['Physics', 'Chemistry', 'Earth Science'];
  setUp(() {
    currentClass.value = _cls;
    subjectsN.value = List.of(defaultSubjects);
  });
  tearDown(() {
    currentClass.value = null;
    subjectsN.value = List.of(defaultSubjects);
  });

  testWidgets('card "···" opens a menu with Edit and Delete', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_app(_overrides(repo, lesson: _lesson())));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('delete is blocked while the lesson has activities',
      (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_app(_overrides(repo,
        lesson: _lesson(), activities: const {'l1': 2})));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete or move its activities first.'), findsOneWidget);
    expect(find.text('Delete this lesson?'), findsNothing);
    expect(repo.deletes, 0);
  });

  testWidgets('delete without activities confirms then deletes',
      (tester) async {
    final repo = _FakeRepo();
    await tester
        .pumpWidget(_app(_overrides(repo, lesson: _lesson())));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this lesson?'), findsOneWidget);
    expect(
        find.text('This also removes students’ progress for “Bio”.'),
        findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repo.deletes, 1);
  });

  testWidgets('cancel in the delete confirm does not delete', (tester) async {
    final repo = _FakeRepo();
    await tester
        .pumpWidget(_app(_overrides(repo, lesson: _lesson())));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repo.deletes, 0);
  });

  testWidgets('edit opens the sheet prefilled as "Edit lesson"',
      (tester) async {
    final repo = _FakeRepo();
    await tester
        .pumpWidget(_app(_overrides(repo, lesson: _lesson())));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit lesson'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Bio');
  });

  testWidgets('publishing a draft toggles without a confirm', (tester) async {
    final repo = _FakeRepo();
    await tester
        .pumpWidget(_app(_overrides(repo, lesson: _lesson())));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DSSwitch));
    await tester.pumpAndSettle();

    expect(repo.publishes, [('l1', true)]);
    expect(find.text('Unpublish this lesson?'), findsNothing);
  });

  testWidgets('unpublishing with attempts asks first', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_app(_overrides(repo,
        lesson: _lesson(published: true),
        attempts: const {'l1': 3})));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DSSwitch));
    await tester.pumpAndSettle();

    expect(find.text('Unpublish this lesson?'), findsOneWidget);
    expect(repo.publishes, isEmpty);
  });

  testWidgets('"+ Subject" card opens the add/manage modal', (tester) async {
    final repo = _FakeRepo();
    await tester
        .pumpWidget(_app(_overrides(repo, lesson: _lesson())));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DSButton, 'New lesson'));
    await tester.pumpAndSettle();

    // The dashed "+ Subject" card is the only DSDashedBox labeled "Subject"
    // (the file pickers carry different labels).
    await tester.tap(find.descendant(
        of: find.byType(DSDashedBox), matching: find.text('Subject')));
    await tester.pumpAndSettle();

    // Modal: title, name field, and every subject as a removable card
    // ('Physics' also shows in the chip row + sheet card behind it).
    expect(find.text('Add subject'), findsOneWidget);
    expect(find.text('Physics'), findsWidgets);

    // First field in the modal is "Subject name" (the modal's only field).
    await tester.enterText(
        find.descendant(
            of: find.byType(DSModal), matching: find.byType(TextField))
            .first,
        'Biology');
    await tester.pump();
    await tester.tap(find.widgetWithText(DSButton, 'Save'));
    await tester.pumpAndSettle();
    expect(subjectsN.value, contains('Biology'));

    // Deleting a subject asks first (name also shows in the chip row and
    // the sheet card — target the card inside the modal).
    await tester.tap(find.descendant(
        of: find.byType(DSModal), matching: find.text('Biology')));
    await tester.pumpAndSettle();
    expect(find.text('Remove this subject?'), findsOneWidget);
    expect(subjectsN.value, contains('Biology'));

    await tester.tap(find.widgetWithText(DSButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(subjectsN.value, isNot(contains('Biology')));
  });
}
