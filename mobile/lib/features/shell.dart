import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/icons.dart';
import '../core/widgets.dart';
import '../data/repository.dart';

class Shell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const Shell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) => RoleGate(
        child: Scaffold(
          body: shell,
          bottomNavigationBar: IslandNavBar(
            currentIndex: shell.currentIndex,
            onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            items: const [
              (icon: AppIcons.home, label: 'Home'),
              (icon: AppIcons.lessons, label: 'Lessons'),
              (icon: AppIcons.progress, label: 'Progress'),
              (icon: AppIcons.account, label: 'Account'),
            ],
          ),
        ),
      );
}

/// Student-side role gate: staff roles are routed to the /teacher portal.
/// Mirrors RequireStudent on web (role check is async, so gate here).
/// Fails closed: an unloadable or missing profile never shows the student app.
class RoleGate extends ConsumerWidget {
  final Widget child;
  const RoleGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    if (me.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (me.hasError) {
      return Scaffold(body: ErrorState(onRetry: () => ref.invalidate(meProvider)));
    }
    if (me.valueOrNull?['role'] != 'student') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) GoRouter.maybeOf(context)?.go('/teacher');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child;
  }
}
