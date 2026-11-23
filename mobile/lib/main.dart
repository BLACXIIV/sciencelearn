import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/assessment/assessment_screen.dart';
import 'features/assessment/quiz_runner_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/lessons/lesson_detail_screen.dart';
import 'features/lessons/lessons_screen.dart';
import 'features/account/account_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/review/review_screen.dart';
import 'features/shell.dart';
import 'features/teacher/teacher_shell.dart';
import 'features/teacher/teacher_dashboard_screen.dart';
import 'features/teacher/teacher_lessons_screen.dart';
import 'features/teacher/students_screen.dart';
import 'features/teacher/users_screen.dart';

// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
// (same project as web/.env's VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
        'Missing SUPABASE_URL / SUPABASE_ANON_KEY — run with '
        '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ProviderScope(child: ScienceLearnApp()));
}

class _AuthRefresh extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthRefresh() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

final _router = GoRouter(
  refreshListenable: _AuthRefresh(),
  redirect: (context, state) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    final onAuthPage = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    if (!loggedIn) return onAuthPage ? null : '/login';
    if (onAuthPage) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => Shell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/assessments', builder: (_, __) => const AssessmentScreen()),
          GoRoute(path: '/review', builder: (_, __) => const ReviewScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/lessons', builder: (_, __) => const LessonsScreen()),
          GoRoute(path: '/lesson/:id', builder: (_, s) => LessonDetailScreen(id: s.pathParameters['id']!)),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
        ]),
      ],
    ),
    // Full-screen focused task — intentionally covers the tab bar.
    GoRoute(
      path: '/quiz/:id',
      builder: (_, s) => QuizRunnerScreen(id: s.pathParameters['id']!, title: s.uri.queryParameters['t'] ?? 'Quiz'),
    ),
    // Teacher/admin portal — same features as the web staff portal.
    // Branch indexes: 0 dashboard, 1 lessons, 2 students, 3 users, 4 account.
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => TeacherShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/teacher', builder: (_, __) => const TeacherDashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/teacher/lessons', builder: (_, __) => const TeacherLessonsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/teacher/students', builder: (_, __) => const StudentsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/teacher/users', builder: (_, __) => const UsersScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/teacher/account', builder: (_, __) => const AccountScreen()),
        ]),
      ],
    ),
  ],
);

class ScienceLearnApp extends StatelessWidget {
  const ScienceLearnApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'ScienceLearn',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.dark),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      );
}
