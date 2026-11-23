import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/assessment/assessment_screen.dart';
import 'features/assessment/quiz_runner_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/lessons/lesson_detail_screen.dart';
import 'features/lessons/lessons_screen.dart';
import 'features/more/credits_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/review/review_screen.dart';
import 'features/shell.dart';

// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
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
    final atLogin = state.matchedLocation == '/login';
    if (!loggedIn) return atLogin ? null : '/login';
    if (atLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (_, __, child) => Shell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/lessons', builder: (_, __) => const LessonsScreen()),
        GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
        GoRoute(path: '/more', builder: (_, __) => const CreditsScreen()),
      ],
    ),
    GoRoute(path: '/lesson/:id', builder: (_, s) => LessonDetailScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/assessments', builder: (_, __) => const AssessmentScreen()),
    GoRoute(
      path: '/quiz/:id',
      builder: (_, s) => QuizRunnerScreen(id: s.pathParameters['id']!, title: s.uri.queryParameters['t'] ?? 'Quiz'),
    ),
    GoRoute(path: '/review', builder: (_, __) => const ReviewScreen()),
  ],
);

class ScienceLearnApp extends StatelessWidget {
  const ScienceLearnApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'ScienceLearn',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: _router,
      );
}
