import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repository.dart';

class Shell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const Shell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mobile is the student app — staff roles go to the web Teacher Portal.
    // Mirrors RequireTeacher on web (role check is async, so gate here).
    final me = ref.watch(meProvider);
    if (me.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final role = me.valueOrNull?['role'];
    if (role != null && role != 'student') return const _StaffGate();

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Lessons'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

class _StaffGate extends StatelessWidget {
  const _StaffGate();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.co_present_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('This app is for students',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Teachers use the ScienceLearn Teacher Portal on the web.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                onPressed: () => Supabase.instance.client.auth.signOut(),
              ),
            ]),
          ),
        ),
      );
}
