import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/icons.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

/// Teacher/admin shell. Branch indexes are fixed in the router:
/// 0 dashboard, 1 lessons, 2 students, 3 users (admin), 4 account.
/// Teachers hide branch 3; visible tabs map onto the same branches.
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
      return Scaffold(body: ErrorState(onRetry: () => ref.invalidate(meProvider)));
    }
    final role = me.valueOrNull?['role'];
    if (role == 'student') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) GoRouter.maybeOf(context)?.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Branch indexes visible as tabs; admins also get Users.
    final visible = role == 'admin' ? const [0, 1, 2, 3, 4] : const [0, 1, 2, 4];
    const items = [
      (icon: AppIcons.dashboard, label: 'Dashboard'),
      (icon: AppIcons.lessons, label: 'Lessons'),
      (icon: AppIcons.students, label: 'Students'),
      (icon: AppIcons.userAdmin, label: 'Users'),
      (icon: AppIcons.account, label: 'Account'),
    ];

    return Scaffold(
      body: shell,
      bottomNavigationBar: IslandNavBar(
        currentIndex: visible.indexOf(shell.currentIndex).clamp(0, visible.length - 1),
        onSelect: (i) => shell.goBranch(visible[i], initialLocation: visible[i] == shell.currentIndex),
        items: [for (final b in visible) items[b]],
      ),
    );
  }
}
