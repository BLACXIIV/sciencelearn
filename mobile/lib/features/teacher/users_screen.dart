import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Admin-only: list all profiles and change roles.
/// Writes need the "profiles admin write" policy (migration 0004).
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersState();
}

class _UsersState extends ConsumerState<UsersScreen> {
  static const _roleTones = {
    'student': DSBadgeTone.blue,
    'teacher': DSBadgeTone.mint,
    'admin': DSBadgeTone.sun,
  };
  final _search = TextEditingController();

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _pickRole(Json u) async {
    final role = await showDSModal<String>(
      context,
      title: 'Change role',
      body: _RolePicker(current: '${u['role']}'),
      actions: [
        DSButton(
          variant: DSButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
    if (role == null || role == u['role']) return;
    try {
      await ref.read(repoProvider).setRole('${u['id']}', role);
      ref.invalidate(profilesProvider);
    } catch (e) {
      if (mounted) DSToast.show(context, message: '$e', tone: DSToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final users = ref.watch(profilesProvider);

    if (me.valueOrNull?['role'] != 'admin') {
      return const Scaffold(
        body: DSEmptyState(icon: DSIconName.lock, title: 'Admins only'),
      );
    }

    final needle = _search.text.trim().toLowerCase();
    return Scaffold(
      body: Column(children: [
        DSPageHeader(
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Users', style: DSText.h2),
            ),
          ),
        ),
        Expanded(child: users.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => DSEmptyState(
            icon: DSIconName.offline,
            title: "Couldn't load this right now",
            body: 'Check your connection and try again.',
            action: DSButton(
              variant: DSButtonVariant.outline,
              size: DSButtonSize.sm,
              leadingIcon: DSIconName.retry,
              onPressed: () => ref.invalidate(profilesProvider),
              child: const Text('Try again'),
            ),
          ),
          data: (rows) {
            final filtered = rows.where((u) =>
                needle.isEmpty ||
                '${u['full_name'] ?? ''}'.toLowerCase().contains(needle) ||
                '${u['id']}'.toLowerCase().startsWith(needle)).toList();
            return MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
              DSSearchField(
                label: 'Search',
                hint: 'Name or ID',
                controller: _search,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                DSCard(child: DSEmptyState(
                  icon: DSIconName.students,
                  title: rows.isEmpty ? 'No users yet' : 'No matches',
                )),
              for (final u in filtered) ...[
                if (u != filtered.first) const SizedBox(height: 10),
                () {
                  final isSelf = u['id'] == me.valueOrNull?['id'];
                  return DSListItemCard(
                    leading: DSAvatar(name: '${u['full_name'] ?? ''}'.isEmpty ? '?' : '${u['full_name']}'),
                    title: Text('${u['full_name'] ?? ''}'.isEmpty ? '(no name)' : '${u['full_name']}'),
                    subtitle: Row(children: [
                      DSBadge(tone: _roleTones['${u['role']}'] ?? DSBadgeTone.blue,
                          child: Text('${u['role']}')),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Text('you', style: DSText.caption.copyWith(color: DSColors.muted)),
                      ],
                    ]),
                    trailing: DSIconButton(
                      icon: DSIconName.edit,
                      label: 'Change role',
                      size: 36,
                      onPressed: isSelf ? null : () => _pickRole(u),
                    ),
                  );
                }(),
              ],
            ]));
          },
        )),
      ]),
    );
  }
}

/// Segmented role picker used inside the change-role modal.
class _RolePicker extends StatefulWidget {
  final String current;
  const _RolePicker({required this.current});
  @override
  State<_RolePicker> createState() => _RolePickerState();
}

class _RolePickerState extends State<_RolePicker> {
  late String _role = widget.current;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      DSSegmentedControl(
        options: const [
          DSSegment('student', 'Student'),
          DSSegment('teacher', 'Teacher'),
          DSSegment('admin', 'Admin'),
        ],
        value: _role,
        onChanged: (v) => setState(() => _role = v),
      ),
      const SizedBox(height: 12),
      DSButton(
        fullWidth: true,
        onPressed: () => Navigator.of(context).pop(_role),
        child: const Text('Save role'),
      ),
    ]);
  }
}
