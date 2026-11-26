// Responsive audit: pump every teacher-portal screen at small (320pt) and
// standard (390pt) widths. Any RenderFlex overflow is a test failure.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sciencelearn/data/repository.dart';
import 'package:sciencelearn/features/account/account_screen.dart';
import 'package:sciencelearn/features/classes/classes_screen.dart';
import 'package:sciencelearn/features/classes/select_class_screen.dart';
import 'package:sciencelearn/features/dashboard/dashboard_screen.dart';
import 'package:sciencelearn/features/progress/progress_screen.dart';
import 'package:sciencelearn/features/teacher/class_dashboard_screen.dart';
import 'package:sciencelearn/features/teacher/class_report_screen.dart';
import 'package:sciencelearn/features/teacher/class_lessons_screen.dart';
import 'package:sciencelearn/features/teacher/class_quiz_screen.dart';
import 'package:sciencelearn/features/teacher/class_students_screen.dart';
import 'package:sciencelearn/features/teacher/student_report_screen.dart';
import 'package:sciencelearn/features/teacher/users_screen.dart';

final _cls = <String, dynamic>{
  'id': 'c1',
  'name': 'test classroom',
  'code': 'WYR5V2',
  'teacher_id': 't1',
  'join_policy': 'approval',
};

List<Override> _overrides() => [
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
      classCompletedProvider.overrideWith((ref, id) => 3),
      classLessonsProvider.overrideWith((ref, id) => const []),
      classMembershipProvider.overrideWith((ref, ids) => {
            'student_id': ids.$2,
            'status': 'active',
            'profiles': {'full_name': 'student'}
          }),
      studentAssessmentsProvider.overrideWith((ref, ids) => const []),
      studentLessonsProvider.overrideWith((ref, ids) => const []),
      classAssessmentsProvider.overrideWith((ref, id) => const []),
      classLessonAvgsProvider.overrideWith((ref, id) => const []),
      // student-side screens
      progressProvider.overrideWith((ref) => <String, dynamic>{
            'lessons_pct': 50,
            'quizzes_pct': 80,
            'pre_score': 70,
            'post_score': 85,
          }),
      recentProvider.overrideWith((ref) => const <Json>[]),
      enrolledClassesProvider.overrideWith((ref) => const <Json>[]),
      awaitingProvider.overrideWith((ref) => const <String, int>{}),
      teacherClassesProvider.overrideWith((ref) => const <Json>[]),
      profilesProvider.overrideWith((ref) => const <Json>[]),
    ];

Widget _app(Widget child) => ProviderScope(
      overrides: _overrides(),
      // Material ancestor: some screens return a bare ListView (they live
      // inside a shell Scaffold in production) — DSCodeInput's TextField
      // needs one.
      child: MaterialApp(home: Material(child: child)),
    );

Future<void> _pumpAt(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(screen));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => currentClass.value = _cls);
  tearDown(() => currentClass.value = null);

  final screens = <String, Widget>{
    'dashboard': const ClassDashboardScreen(),
    'students': const ClassStudentsScreen(),
    'report': const StudentReportScreen(studentId: 's1'),
    'class report': const ClassReportScreen(),
    'lessons': const ClassLessonsScreen(),
    'quiz': const ClassQuizScreen(),
    'admin users': const UsersScreen(),
    'student dashboard': const DashboardScreen(),
    'student progress': const ProgressScreen(),
    'student account': const AccountScreen(),
    'student classes': const MyClassesScreen(),
    'select class': const SelectClassScreen(),
  };
  final sizes = <String, Size>{
    '320x568': const Size(320, 568),
    '390x844': const Size(390, 844),
  };

  for (final s in screens.entries) {
    for (final sz in sizes.entries) {
      testWidgets('${s.key} fits ${sz.key} without overflow', (tester) async {
        final orig = FlutterError.onError;
        FlutterError.onError = (d) {
          debugPrint('ERR ${s.key} ${sz.key}: '
              '${d.toDiagnosticsNode(style: DiagnosticsTreeStyle.sparse).toStringDeep()}');
          orig?.call(d);
        };
        addTearDown(() => FlutterError.onError = orig);
        await _pumpAt(tester, s.value, sz.value);
        // Scroll to the bottom too — lazy children can overflow offscreen.
        final list = find.byType(ListView);
        if (list.evaluate().isNotEmpty) {
          for (var i = 0; i < 6; i++) {
            await tester.fling(list.first, const Offset(0, -600), 3000);
            await tester.pumpAndSettle();
          }
        }
        final e = tester.takeException();
        expect(e, isNull, reason: '${s.key} at ${sz.key} overflowed or threw');
      });
    }
  }
}
