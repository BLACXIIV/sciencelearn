import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

final teacherClassesProvider = FutureProvider.autoDispose((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).myClasses();
});

/// Teacher class list + create. join_policy: 'open' = instant, 'approval' = teacher confirms.
class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});
  @override
  ConsumerState<ClassesScreen> createState() => _ClassesState();
}

class _ClassesState extends ConsumerState<ClassesScreen> {
  final _name = TextEditingController();
  String _policy = 'open';
  bool _busy = false;

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(repoProvider).createClass(_name.text.trim(), _policy);
      _name.clear();
      ref.invalidate(teacherClassesProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(teacherClassesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      body: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('New class', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(controller: _name,
              decoration: const InputDecoration(hintText: 'Class name, e.g. Grade 7 - Diamond')),
          const SizedBox(height: 12),
          Text('How do students join?', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'open', label: Text('Instant'), icon: Icon(AppIcons.login)),
                ButtonSegment(value: 'approval', label: Text('Approval'), icon: Icon(AppIcons.students)),
              ],
              selected: {_policy},
              onSelectionChanged: (s) => setState(() => _policy = s.first),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _policy == 'open'
                ? 'Anyone with the code joins immediately.'
                : 'You confirm each request before they see class content.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create class'),
          ),
        ])),
        const SizedBox(height: 16),
        classes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(onRetry: () => ref.invalidate(teacherClassesProvider)),
          data: (rows) {
            if (rows.isEmpty) {
              return const AppCard(child: EmptyState(icon: AppIcons.students,
                  title: 'No classes yet', message: 'Create one above and share its join code.'));
            }
            return Column(children: [
              for (final c in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => context.push('/teacher/class/${c['id']}', extra: c),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${c['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(_subtitle(c),
                            style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ])),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '${c['code']}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied')));
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(AppIcons.copy, size: 14, color: AppColors.muted),
                            const SizedBox(width: 5),
                            Text('${c['code']}', style: const TextStyle(
                                fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                          ]),
                        ),
                      ),
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

  String _subtitle(Json c) {
    final enr = (c['enrollments'] as List?) ?? const [];
    final active = enr.where((e) => e['status'] == 'active').length;
    final pending = enr.where((e) => e['status'] == 'pending').length;
    final bits = <String>[
      '$active student${active == 1 ? '' : 's'}',
      if (pending > 0) '$pending pending',
      if (c['join_policy'] == 'approval') 'Approval required',
    ];
    return bits.join(' Â· ');
  }
}
