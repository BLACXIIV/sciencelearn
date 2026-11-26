// Widget tests for the class-level teacher report: aggregates, roster
// tap-through to the student report, owner guard and the CSV export shape.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sciencelearn/data/repository.dart';
import 'package:sciencelearn/features/teacher/class_report_screen.dart';
import 'package:sciencelearn/features/teacher/student_report_screen.dart';

final _cls = <String, dynamic>{
  'id': 'c1',
  'name': 'test classroom',
  'code': 'WYR5V2',
  'teacher_id': 't1',
  'join_policy': 'approval',
};

List<Override> _overrides({String meId = 't1'}) => [
      meProvider.overrideWith(
          (ref) => {'id': meId, 'role': 'teacher', 'full_name': 'adrian'}),
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
      classAssessmentsProvider.overrideWith((ref, id) => [
            {
              'id': 'a1',
              'title': 'Pre-test',
              'kind': 'pre_test',
              'avg': 70,
              'attempts': 1,
              'released': true
            },
            {
              'id': 'a3',
              'title': 'Final challenge',
              'kind': 'final_challenge',
              'avg': null,
              'attempts': 0,
              'released': true
            },
          ]),
      classLessonAvgsProvider.overrideWith((ref, id) => [
            {'id': 'l1', 'title': 'Projectile Motion', 'avg': 50},
          ]),
      classMembershipProvider.overrideWith((ref, ids) => {
            'student_id': ids.$2,
            'status': 'active',
            'profiles': {'full_name': 'student'}
          }),
      studentAssessmentsProvider.overrideWith((ref, ids) => const []),
      studentLessonsProvider.overrideWith((ref, ids) => const []),
    ];

GoRouter _router() => GoRouter(routes: [
      GoRoute(
          path: '/teacher/students',
          builder: (_, __) => const Scaffold(body: Text('Students list'))),
      GoRoute(
          path: '/teacher/reports',
          builder: (_, __) => const ClassReportScreen()),
      GoRoute(
          path: '/teacher/students/report/:id',
          builder: (_, s) =>
              StudentReportScreen(studentId: s.pathParameters['id']!)),
    ]);

Widget _app(GoRouter router, {String meId = 't1'}) => ProviderScope(
      overrides: _overrides(meId: meId),
      child: MaterialApp.router(routerConfig: router),
    );

void main() {
  setUp(() => currentClass.value = _cls);
  tearDown(() => currentClass.value = null);

  testWidgets('Class report renders aggregates and sections', (tester) async {
    final router = _router()..go('/teacher/reports');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.text('Class report'), findsWidgets);
    expect(find.text('Class pre-test to post-test'), findsOneWidget);
    expect(find.text('Class averages'), findsOneWidget);
    // Aggregates: 1 active student at quiz 80, gain +15.
    expect(find.text('80%'), findsWidgets);
    expect(find.text('+15%'), findsWidgets);
    // Scroll for the below-fold sections — ListView builds lazily.
    await tester.scrollUntilVisible(find.text('Assessment averages'), 150,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('1 student attempted'), findsOneWidget);
    expect(find.text('No attempts'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Projectile Motion'), 150,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Projectile Motion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping a student row opens that student\'s report',
      (tester) async {
    final router = _router()..go('/teacher/reports');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('student'), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('student'));
    await tester.pumpAndSettle();

    expect(find.text('Pre-test to post-test'), findsOneWidget);
    expect(find.text('Overall progress'), findsOneWidget);
  });

  testWidgets('A non-owner is bounced off the class report', (tester) async {
    final router = _router()..go('/teacher/students');
    await tester.pumpWidget(_app(router, meId: 'someone-else'));
    await tester.pumpAndSettle();
    router.push('/teacher/reports');
    await tester.pumpAndSettle();

    expect(find.text('Students list'), findsOneWidget);
    expect(find.text('Class averages'), findsNothing);
  });

  test('buildClassReportCsv emits aggregates, assessments and roster', () {
    final csv = buildClassReportCsv(
      className: 'test, classroom',
      students: 1,
      lessonsAvg: 100,
      quizAvg: 80,
      preAvg: 70,
      postAvg: 85,
      gain: 15,
      assessments: const [
        {'title': 'Pre-test', 'avg': 70, 'attempts': 1, 'released': true},
        {
          'title': 'Final challenge',
          'avg': null,
          'attempts': 0,
          'released': false
        },
      ],
      lessons: const [
        {'title': 'Projectile Motion', 'avg': 50},
      ],
      roster: const [
        {
          'full_name': 'student',
          'lessons_pct': 100,
          'quizzes_pct': 80,
          'pre_score': 70,
          'post_score': 85,
        },
      ],
    );

    expect(csv, contains('Class,"test, classroom"'));
    expect(csv, contains('Students,1'));
    expect(csv, contains('Gain,+15%'));
    expect(csv, contains('Pre-test,70%,1,'));
    expect(csv, contains('Final challenge,No attempts,0,'));
    expect(csv, contains('Projectile Motion,50%'));
    expect(csv, contains('student,100%,80%,70%,85%,+15%'));
  });
}
