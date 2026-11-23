import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

/// Admin-only: list all profiles and change roles.
/// Writes need the "profiles admin write" policy (migration 0004).
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  static const _roles = ['student', 'teacher', 'admin'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final users = ref.watch(profilesProvider);

    if (me.valueOrNull?['role'] != 'admin') {
      return const Scaffold(
        appBar: null,
        body: EmptyState(icon: Icons.lock_outline, title: 'Admins only'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(onRetry: () => ref.invalidate(profilesProvider)),
        data: (rows) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final u = rows[i];
            final isSelf = u['id'] == me.valueOrNull?['id'];
            return AppCard(
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${u['full_name'] ?? ''}'.isEmpty ? '(no name)' : '${u['full_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${u['role']}${isSelf ? ' · you' : ''}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                PopupMenuButton<String>(
                  enabled: !isSelf,
                  onSelected: (role) async {
                    try {
                      await ref.read(repoProvider).setRole('${u['id']}', role);
                      ref.invalidate(profilesProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    for (final r in _roles)
                      PopupMenuItem(value: r, child: Text(r == u['role'] ? '$r ✓' : r)),
                  ],
                  child: const Icon(Icons.edit_outlined),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
