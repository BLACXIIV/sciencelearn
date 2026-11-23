import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'data/settings.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/assessment/assessment_screen.dart';
import 'features/assessment/quiz_runner_screen.dart';
import 'features/classes/classes_screen.dart';
import 'features/classes/class_detail_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/lessons/lesson_detail_screen.dart';
import 'features/account/account_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/review/review_screen.dart';
import 'features/shell.dart';
import 'features/teacher/teacher_shell.dart';
import 'features/teacher/teacher_dashboard_screen.dart';
import 'features/teacher/classes_screen.dart';
import 'features/teacher/class_detail_screen.dart';
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
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

final _router = GoRouter(
  refreshListenable: _AuthRefresh(),
  redirect: (context, state) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    const publicPages = {'/welcome', '/login', '/signup'};
    final onPublicPage = publicPages.contains(state.matchedLocation);
    if (!loggedIn) return onPublicPage ? null : '/welcome';
    if (onPublicPage) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/welcome', builder: (_, __) => const LandingScreen()),
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
          GoRoute(path: '/classes', builder: (_, __) => const MyClassesScreen()),
          GoRoute(
            path: '/class/:id',
            builder: (_, s) => StudentClassScreen(
                classId: s.pathParameters['id']!,
                name: s.uri.queryParameters['name'] ?? 'Class'),
          ),
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
    // Branch indexes: 0 dashboard, 1 classes, 2 users (admin), 3 account.
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => TeacherShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/teacher', builder: (_, __) => const TeacherDashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/teacher/classes', builder: (_, __) => const ClassesScreen()),
          GoRoute(
            path: '/teacher/class/:id',
            builder: (_, s) => ClassDetailScreen(
                cls: s.extra as Map<String, dynamic>? ?? {'id': s.pathParameters['id']}),
          ),
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

class ScienceLearnApp extends ConsumerWidget {
  const ScienceLearnApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ap = ref.watch(appearanceProvider);
    // Rebuild on OS dark/light flips so "system" mode re-applies AppColors.
    MediaQuery.platformBrightnessOf(context);
    AppColors.apply(palette: ap.palette, accent: ap.accent, surface: ap.surface);
    return MaterialApp.router(
      title: 'ScienceLearn',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette: lightPalette, accent: ap.accent),
      darkTheme: buildTheme(palette: darkPalette, accent: ap.accent),
      themeMode: switch (ap.mode) {
        AppMode.system => ThemeMode.system,
        AppMode.dark => ThemeMode.dark,
        AppMode.light => ThemeMode.light,
      },
      routerConfig: _router,
    );
  }
}
