import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Shared navy header for the 4 class-portal tabs: class name on the left,
/// Switch class + Account on the right. Mirrors the web AppLayout header.
class ClassPortalHeader extends StatelessWidget {
  const ClassPortalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final cls = currentClass.value;
    return DSPageHeader(
      compact: true,
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          Expanded(
            child: Text(
              '${cls?['name'] ?? 'Class'}',
              style: DSText.h2.copyWith(color: DSColors.surface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DSIconButton(
            icon: DSIconName.school,
            label: 'Switch class',
            onPressed: () {
              // Clearing the notifier re-gates the router back to the picker.
              currentClass.value = null;
              classPicked.value = false;
              context.go('/select-class');
            },
          ),
          const SizedBox(width: 8),
          DSIconButton(
            icon: DSIconName.account,
            label: 'Account',
            onPressed: () => context.push('/teacher/account'),
          ),
        ]),
      ),
    );
  }
}
