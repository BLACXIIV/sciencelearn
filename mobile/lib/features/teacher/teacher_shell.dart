import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Teacher/admin shell — class-scoped portal. Branch indexes are fixed in the
/// router: 0 dashboard, 1 lessons, 2 quiz, 3 students, 4 users (admin).
/// The bar shows 5 slots: the four tabs plus "More", which opens a bottom
/// sheet (Review Content, Reports, Account, Switch class, Users, Sign out).
class TeacherShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const TeacherShell({super.key, required this.shell});

  void _openMore(BuildContext context, bool isAdmin) {
    showDSBottomSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _moreItem(context, DSIconName.review, 'Review Content',
              () => context.push('/teacher/review')),
          _moreItem(context, DSIconName.progress, 'Reports',
              () => context.push('/teacher/reports')),
          _moreItem(context, DSIconName.account, 'Account',
              () => context.push('/teacher/account')),
          _moreItem(context, DSIconName.school, 'Switch class', () {
            // Clearing the notifier re-gates the router back to the picker.
            currentClass.value = null;
            classPicked.value = false;
            context.go('/select-class');
          }),
          if (isAdmin)
            _moreItem(context, DSIconName.userAdmin, 'Users',
                () => shell.goBranch(4)),
          _moreItem(
              context, DSIconName.signOut, 'Sign out', () => sb.auth.signOut()),
        ],
      ),
    );
  }

  Widget _moreItem(
      BuildContext context, DSIconName icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: DSIcon(icon, size: 22, color: DSColors.navy),
      title: Text(label, style: DSText.title),
      shape: RoundedRectangleBorder(borderRadius: DSRadii.inputBr),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final meV = me.valueOrNull;
    // Gate on a missing VALUE, not isLoading: auth refresh emits AsyncLoading
    // with the previous value attached, and blanking the whole portal for a
    // frame on every token refresh is the scroll-time white blip.
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
    final role = me.valueOrNull?['role'];
    if (role == 'student') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) GoRouter.maybeOf(context)?.go('/');
      });
      return const Scaffold(body: Center(child: DSLoadingIndicator()));
    }

    // Ownership guard — every /teacher/* screen is scoped to currentClass;
    // a class the teacher doesn't own gets cleared and the router re-gates
    // to the picker. Admins pass. RLS blocks writes; this stops the
    // read-side leak (name, join code, counts).
    final cls = currentClass.value;
    if (cls != null &&
        '${cls['teacher_id']}' != '${meV?['id']}' &&
        role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        currentClass.value = null;
        classPicked.value = false;
        if (context.mounted) context.go('/select-class');
      });
      return const Scaffold(body: Center(child: DSLoadingIndicator()));
    }

    // Four tab branches + a 5th "More" slot that opens the sheet instead.
    const items = [
      DSNavItem('0', 'Dashboard', DSIconName.dashboard),
      DSNavItem('1', 'Lessons', DSIconName.lessons),
      DSNavItem('2', 'Quiz', DSIconName.quiz),
      DSNavItem('3', 'Students', DSIconName.students),
      DSNavItem('more', 'More', DSIconName.more),
    ];
    // The admin Users branch has no bar slot — keep the bar unlit there.
    final active = shell.currentIndex >= 0 && shell.currentIndex <= 3
        ? '${shell.currentIndex}'
        : null;

    return Scaffold(
      body: shell,
      bottomNavigationBar: DSIslandNavBar(
        active: active,
        onSelect: (key) {
          if (key == 'more') {
            _openMore(context, role == 'admin');
            return;
          }
          final b = int.parse(key);
          shell.goBranch(b, initialLocation: b == shell.currentIndex);
        },
        items: items,
      ),
    );
  }
}
