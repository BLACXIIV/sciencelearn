// Widget tests for the teacher Students screen + per-student report.
// Providers are overridden with fixture data — no Supabase needed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sciencelearn/data/repository.dart';
import 'package:sciencelearn/features/teacher/class_students_screen.dart';
import 'package:sciencelearn/features/teacher/student_report_screen.dart';

final _cls = <String, dynamic>{
  'id': 'c1',
  'name': 'test classroom',
  'code': 'WYR5V2',
  'teacher_id': 't1',
  'join_policy': 'approval',
};

List<Override> _overrides({bool nonMember = false}) => [
      meProvider.overrideWith(
          (ref) => {'id': 't1', 'role': 'teacher', 'full_name': 'adrian'}),
      classMembersProvider.overrideWith((ref, id) => [
            {
              'student_id': 's1',
              'status': 'active',
              'profiles': {'full_name': 'student'}
            },
            {
              'student_id': 's2',
              'status': 'pending',
              'profiles': {'full_name': 'kyle ramirez'}
            },
          ]),
      classProgressProvider.overrideWith((ref, id) => [
            {
              'student_id': 's1',
              'full_name': 'student',
              'lessons_pct': 100,
              'quizzes_pct': 80,
              'pre_score': 70,
              'post_score': 85,
            }
          ]),
      classMembershipProvider.overrideWith((ref, ids) => nonMember
          ? null
          : {
              'student_id': ids.$2,
              'status': 'active',
              'profiles': {'full_name': 'student'}
            }),
      studentAssessmentsProvider.overrideWith((ref, ids) => [
            {
              'id': 'a1',
              'title': 'Pre-test',
              'kind': 'pre_test',
              'score': 70,
              'released': true
            },
            {
              'id': 'a2',
              'title': 'Post-test',
              'kind': 'post_test',
              'score': 85,
              'released': true
            },
            {
              'id': 'a3',
              'title': 'Final challenge',
              'kind': 'final_challenge',
              'score': null,
              'released': true
            },
          ]),
      studentLessonsProvider.overrideWith((ref, ids) => [
            {'id': 'l1', 'title': 'Projectile Motion', 'percent': 100},
            {'id': 'l2', 'title': 'Climate Change', 'percent': 0},
          ]),
    ];

GoRouter _router() => GoRouter(routes: [
      GoRoute(
          path: '/teacher/students',
          builder: (_, __) => const ClassStudentsScreen()),
      GoRoute(
          path: '/teacher/students/report/:id',
          builder: (_, s) =>
              StudentReportScreen(studentId: s.pathParameters['id']!)),
      GoRoute(path: '/select-class', builder: (_, __) => const Placeholder()),
    ]);

Widget _app(GoRouter router, {bool nonMember = false}) => ProviderScope(
      overrides: _overrides(nonMember: nonMember),
      child: MaterialApp.router(routerConfig: router),
    );

void main() {
  setUp(() => currentClass.value = _cls);
  tearDown(() => currentClass.value = null);

  testWidgets('Students screen renders requests, roster and filters',
      (tester) async {
    final router = _router()..go('/teacher/students');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.text('test classroom'), findsOneWidget);
    expect(find.text('WYR5V2'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('kyle ramirez'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('student'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('100%'), findsWidgets);
    expect(find.text('Danger zone', skipOffstage: false), findsWidgets);
  });

  testWidgets('Needs attention chip hides students at or above 70',
      (tester) async {
    final router = _router()..go('/teacher/students');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Needs attention'));
    await tester.pumpAndSettle();
    expect(find.text('student'), findsNothing);
    expect(find.text('No students match this filter.'), findsOneWidget);
  });

  testWidgets('Tapping a roster card opens the student report', (tester) async {
    final router = _router()..go('/teacher/students');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('student'));
    await tester.pumpAndSettle();

    expect(find.text('Overall progress'), findsOneWidget);
    expect(find.text('Activities', skipOffstage: false), findsOneWidget);
    expect(find.text('Lessons', skipOffstage: false), findsWidgets);
    expect(find.text('Not taken', skipOffstage: false), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Projectile Motion'), 150,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Projectile Motion'), findsOneWidget);
    expect(find.text('70%'), findsWidgets);
    expect(find.text('85%'), findsWidgets);
  });

  testWidgets('"···" on a roster row opens the remove confirm, not the report',
      (tester) async {
    final router = _router()..go('/teacher/students');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await tester.pumpAndSettle();
    // "···" opens the action sheet first; the remove item opens the confirm.
    await tester.tap(find.text('Remove from class'));
    await tester.pumpAndSettle();
    expect(find.text('Remove from class?'), findsOneWidget);
    expect(find.text('Overall progress'), findsNothing);
  });

  testWidgets('Back from the report keeps the Students search state',
      (tester) async {
    final router = _router()..go('/teacher/students');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    // Search narrows the roster but keeps the only student visible.
    await tester.enterText(find.byType(TextField), 'stu');
    await tester.pumpAndSettle();
    expect(find.text('student'), findsOneWidget);

    await tester.tap(find.text('student'));
    await tester.pumpAndSettle();
    expect(find.text('Overall progress'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    // Back on Students, search text preserved.
    expect(find.text('Overall progress'), findsNothing);
    expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'stu');
  });

  testWidgets('Report scrolls fully without errors', (tester) async {
    final router = _router()..go('/teacher/students/report/s1');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    // Fling down through the whole list, then back up — any lazy-build
    // exception or layout overflow would surface here.
    for (var i = 0; i < 6; i++) {
      await tester.fling(
          find.byType(ListView).first, const Offset(0, -600), 4000);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Export report'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tester.fling(
          find.byType(ListView).first, const Offset(0, 600), 4000);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Report bounces a non-member back to Students', (tester) async {
    final router = _router()..go('/teacher/students/report/ghost');
    await tester.pumpWidget(_app(router, nonMember: true));
    await tester.pumpAndSettle();

    // Guard redirects — Students screen is back on top.
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Overall progress'), findsNothing);
  });

  test('buildReportCsv emits metrics, scores and lessons', () {
    final csv = buildReportCsv(
      studentName: 'student, jr',
      className: 'test classroom',
      progress: const {
        'lessons_pct': 100,
        'quizzes_pct': 80,
        'pre_score': 70,
        'post_score': 85,
      },
      assessments: const [
        {
          'title': 'Pre-test',
          'kind': 'pre_test',
          'score': 70,
          'released': true
        },
        {
          'title': 'Final challenge',
          'kind': 'final_challenge',
          'score': 60,
          'released': false
        },
        {
          'title': 'Exit quiz',
          'kind': 'topic_quiz',
          'score': null,
          'released': true
        },
      ],
      lessons: const [
        {'title': 'Projectile Motion', 'percent': 100},
        {'title': 'Climate Change', 'percent': 0},
      ],
    );

    expect(csv, contains('Student,"student, jr"'));
    expect(csv, contains('Quiz average,80%'));
    expect(csv, contains('Gain,+15%'));
    expect(csv, contains('Pre-test,70%,'));
    expect(csv, contains('Final challenge,60%,Not released'));
    expect(csv, contains('Exit quiz,Not taken,'));
    expect(csv, contains('Projectile Motion,100%'));
    expect(csv, contains('Climate Change,0%'));
  });
}
