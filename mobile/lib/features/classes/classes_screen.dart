import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

final enrolledClassesProvider = FutureProvider.autoDispose((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).enrolledClasses();
});

/// Student class list: join by code + enrolled classes with status badges.
class MyClassesScreen extends ConsumerStatefulWidget {
  const MyClassesScreen({super.key});
  @override
  ConsumerState<MyClassesScreen> createState() => _MyClassesState();
}

class _MyClassesState extends ConsumerState<MyClassesScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _msg;
  bool _err = false;

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _join() async {
    setState(() { _busy = true; _msg = null; });
    try {
      final r = await ref.read(repoProvider).joinClass(_code.text.trim());
      _code.clear();
      _err = false;
      _msg = r['status'] == 'pending'
          ? 'Request sent to ${r['name']}, waiting for teacher approval'
          : 'Joined ${r['name']}';
      ref.invalidate(enrolledClassesProvider);
    } catch (e) {
      _msg = '$e'.replaceFirst('Exception: ', '');
      _err = true;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(enrolledClassesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Classes')),
      body: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Join a class', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'Enter class code', isDense: true),
              onChanged: (_) => setState(() {}),
            )),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy || _code.text.trim().isEmpty ? null : _join,
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Join'),
            ),
          ]),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_msg!, style: TextStyle(
                  fontSize: 12,
                  color: _err ? Theme.of(context).colorScheme.error : AppColors.success)),
            ),
        ])),
        const SizedBox(height: 16),
        classes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(onRetry: () => ref.invalidate(enrolledClassesProvider)),
          data: (rows) {
            if (rows.isEmpty) {
              return const AppCard(child: EmptyState(icon: AppIcons.students,
                  title: 'No classes yet', message: 'Get a class code from your teacher.'));
            }
            return Column(children: [
              for (final e in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: e['status'] == 'active'
                        ? () => context.push('/class/${e['class_id']}?name=${Uri.encodeComponent('${e['classes']?['name'] ?? 'Class'}')}')
                        : null,
                    child: Row(children: [
                      Icon(AppIcons.school, size: 20,
                          color: e['status'] == 'active' ? AppColors.blue : AppColors.muted),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${e['classes']?['name'] ?? 'Class'}',
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      if (e['status'] == 'pending')
                        const Text('Pending', style: TextStyle(fontSize: 12, color: AppColors.orange))
                      else
                        Icon(AppIcons.chevron, color: AppColors.muted),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      ])),
    );
  }
}
