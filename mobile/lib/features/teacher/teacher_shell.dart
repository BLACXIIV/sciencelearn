import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Teacher/admin shell — class-scoped portal. Branch indexes are fixed in the
/// router: 0 dashboard, 1 lessons, 2 quiz, 3 students, 4 users (admin).
/// Teachers hide branch 4; visible tabs map onto the same branches.
/// Account lives outside the shell (pushed over it from the class header).
class TeacherShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const TeacherShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    if (me.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (me.hasError) {
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
    final role = me.valueOrNull?['role'];
    if (role == 'student') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) GoRouter.maybeOf(context)?.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Branch indexes visible as tabs; admins also get Users.
    final visible = role == 'admin' ? const [0, 1, 2, 3, 4] : const [0, 1, 2, 3];
    const items = [
      DSNavItem('0', 'Dashboard', DSIconName.dashboard),
      DSNavItem('1', 'Lessons', DSIconName.lessons),
      DSNavItem('2', 'Quiz', DSIconName.quiz),
      DSNavItem('3', 'Students', DSIconName.students),
      DSNavItem('4', 'Users', DSIconName.userAdmin),
    ];
    final active =
        visible.indexOf(shell.currentIndex).clamp(0, visible.length - 1);

    return Scaffold(
      body: shell,
      bottomNavigationBar: DSIslandNavBar(
        active: '${visible[active]}',
        onSelect: (key) {
          final b = int.parse(key);
          shell.goBranch(b, initialLocation: b == shell.currentIndex);
        },
        items: [for (final b in visible) items[b]],
      ),
    );
  }
}
