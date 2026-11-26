import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/repository.dart';
import 'design_system/design_system.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/assessment/assessment_screen.dart';
import 'features/assessment/quiz_runner_screen.dart';
import 'features/classes/classes_screen.dart';
import 'features/classes/class_detail_screen.dart';
import 'features/classes/select_class_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/lessons/lesson_detail_screen.dart';
import 'features/account/account_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/review/review_screen.dart';
import 'features/shell.dart';
import 'features/teacher/teacher_shell.dart';
import 'features/teacher/coming_soon_screen.dart';
import 'features/teacher/class_dashboard_screen.dart';
import 'features/teacher/class_lessons_screen.dart';
import 'features/teacher/class_quiz_screen.dart';
import 'features/teacher/class_students_screen.dart';
import 'features/teacher/class_report_screen.dart';
import 'features/teacher/student_report_screen.dart';
import 'features/teacher/users_screen.dart';

// The defaults are the same public values web/.env ships in every build —
// protected by RLS, not secrets. Override with --dart-define if needed.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://rlhynigapsduxpyjikle.supabase.co');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJsaHluaWdhcHNkdXhweWppa2xlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTU0NDM4ODUsImV4cCI6MjExMTAxOTg4NX0.oVl-_uXTlqk9ivCTLnkA2rDjypoXb0T1qPPBoz_VG34');
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  runApp(const ProviderScope(child: ScienceLearnApp()));
}

class _AuthRefresh extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthRefresh() {
    _sub = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _router = GoRouter(
  refreshListenable:
      Listenable.merge([_AuthRefresh(), classPicked, currentClass]),
  redirect: (context, state) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    const publicPages = {'/welcome', '/login', '/signup'};
    final loc = state.matchedLocation;
    final onPublicPage = publicPages.contains(loc);
    if (!loggedIn) {
      // Signed out — drop the session's class context so the next login
      // always re-gates at the picker.
      classPicked.value = false;
      currentClass.value = null;
      return onPublicPage ? null : '/welcome';
    }
    if (onPublicPage) return '/select-class';
    // Classroom gate: first screen of every app run — bounce any in-app
    // route back to the picker until a class is opened.
    if (loc.startsWith('/teacher')) {
      // The whole teacher portal is scoped to currentClass; the global
      // admin Users tab is the only classless teacher route.
      if (loc != '/teacher/users' && currentClass.value == null) {
        return '/select-class';
      }
      return null;
    }
    if (!classPicked.value && loc != '/select-class') return '/select-class';
    return null;
  },
  routes: [
    GoRoute(path: '/welcome', builder: (_, __) => const LandingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    // Post-login gate: pick a classroom before entering the portal.
    GoRoute(
        path: '/select-class', builder: (_, __) => const SelectClassScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => Shell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/assessments',
              builder: (_, __) => const AssessmentScreen()),
          GoRoute(path: '/review', builder: (_, __) => const ReviewScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/classes', builder: (_, __) => const MyClassesScreen()),
          GoRoute(
            path: '/class/:id',
            builder: (_, s) => StudentClassScreen(
                classId: s.pathParameters['id']!,
                name: s.uri.queryParameters['name'] ?? 'Class'),
          ),
          GoRoute(
              path: '/lesson/:id',
              builder: (_, s) =>
                  LessonDetailScreen(id: s.pathParameters['id']!)),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/progress', builder: (_, __) => const ProgressScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
        ]),
      ],
    ),
    // Full-screen focused task — intentionally covers the tab bar.
    GoRoute(
      path: '/quiz/:id',
      builder: (_, s) => QuizRunnerScreen(
          id: s.pathParameters['id']!,
          title: s.uri.queryParameters['t'] ?? 'Quiz'),
    ),
    // Teacher/admin portal — class-scoped after /select-class.
    // Branch indexes: 0 dashboard, 1 lessons, 2 quiz, 3 students, 4 users (admin).
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => TeacherShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/teacher',
              builder: (_, __) => const ClassDashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/teacher/lessons',
              builder: (_, __) => const ClassLessonsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/teacher/quiz',
              builder: (_, __) => const ClassQuizScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/teacher/students',
              builder: (_, __) => const ClassStudentsScreen(),
              routes: [
                GoRoute(
                  path: 'report/:studentId',
                  builder: (_, s) => StudentReportScreen(
                      studentId: s.pathParameters['studentId']!),
                ),
              ]),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/teacher/users', builder: (_, __) => const UsersScreen()),
        ]),
      ],
    ),
    // Full-screen sub-pages pushed over the shell (class header avatar → account).
    GoRoute(
        path: '/teacher/account', builder: (_, __) => const AccountScreen()),
    // More-sheet destinations with no screen yet.
    GoRoute(
        path: '/teacher/review', builder: (_, __) => const ComingSoonScreen()),
    GoRoute(
        path: '/teacher/reports', builder: (_, __) => const ClassReportScreen()),
  ],
);

class ScienceLearnApp extends StatelessWidget {
  const ScienceLearnApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ScienceLearn',
      debugShowCheckedModeBanner: false,
      theme: buildDSTheme(),
      routerConfig: _router,
    );
  }
}
