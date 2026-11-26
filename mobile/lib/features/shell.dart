import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/repository.dart';
import '../design_system/design_system.dart';

class Shell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const Shell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) => RoleGate(
        child: Scaffold(
          body: shell,
          bottomNavigationBar: DSIslandNavBar(
            active: '${shell.currentIndex}',
            onSelect: (key) {
              final i = int.parse(key);
              shell.goBranch(i, initialLocation: i == shell.currentIndex);
            },
            items: const [
              DSNavItem('0', 'Home', DSIconName.home),
              DSNavItem('1', 'Classes', DSIconName.students),
              DSNavItem('2', 'Progress', DSIconName.progress),
              DSNavItem('3', 'Account', DSIconName.account),
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
    final meV = me.valueOrNull;
    // Gate on a missing VALUE, not isLoading: auth refresh emits AsyncLoading
    // with the previous value attached — blanking on that flashes white.
    if (meV == null && me.isLoading) {
      return const Scaffold(body: Center(child: DSLoadingIndicator()));
    }
    if (meV == null && me.hasError) {
      return Scaffold(
        body: DSEmptyState(
          icon: DSIconName.offline,
          title: "Couldn't load this right now",
          body: 'Check your connection and try again.',
          action: DSButton(
            variant: DSButtonVariant.outline,
            size: DSButtonSize.sm,
            onPressed: () => ref.invalidate(meProvider),
            child: const Text('Try again'),
          ),
        ),
      );
    }
    if (me.valueOrNull?['role'] != 'student') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) GoRouter.maybeOf(context)?.go('/teacher');
      });
      return const Scaffold(body: Center(child: DSLoadingIndicator()));
    }
    return child;
  }
}
