import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

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
      body: Column(children: [
        DSPageHeader(
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Classes', style: DSText.h2),
            ),
          ),
        ),
        Expanded(child: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
          DSCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('New class', style: DSText.title),
            const SizedBox(height: 10),
            DSTextField(
              label: 'Class name',
              hint: 'e.g. Grade 7 - Diamond',
              controller: _name,
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 12),
            DSSegmentedControl(
              options: const [
                DSSegment('open', 'Instant'),
                DSSegment('approval', 'Approval'),
              ],
              value: _policy,
              onChanged: (v) => setState(() => _policy = v),
            ),
            const SizedBox(height: 4),
            Text(
              _policy == 'open'
                  ? 'Anyone with the code joins immediately.'
                  : 'You confirm each request before they see class content.',
              style: DSText.caption.copyWith(color: DSColors.muted),
            ),
            const SizedBox(height: 12),
            DSButton(
              onPressed: _busy ? null : _create,
              loading: _busy,
              child: const Text('Create class'),
            ),
          ])),
          const SizedBox(height: 16),
          classes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => DSEmptyState(
              icon: DSIconName.offline,
              title: "Couldn't load this right now",
              body: 'Check your connection and try again.',
              action: DSButton(
                variant: DSButtonVariant.outline,
                size: DSButtonSize.sm,
                leadingIcon: DSIconName.retry,
                onPressed: () => ref.invalidate(teacherClassesProvider),
                child: const Text('Try again'),
              ),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const DSCard(child: DSEmptyState(icon: DSIconName.school,
                    title: 'No classes yet', body: 'Create one above and share its join code.'));
              }
              return Column(children: [
                for (final c in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DSListItemCard(
                      onTap: () => context.push('/teacher/class/${c['id']}', extra: c),
                      title: Text('${c['name']}'),
                      subtitle: Text(_subtitle(c)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        DSChip(child: Text('${c['code']}',
                            style: DSText.label.copyWith(letterSpacing: 1.5))),
                        const SizedBox(width: 4),
                        DSIconButton(
                          icon: DSIconName.copy,
                          label: 'Copy join code',
                          size: 36,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${c['code']}'));
                            DSToast.show(context, message: 'Code copied',
                                tone: DSToastTone.success);
                          },
                        ),
                        DSIconButton(
                          icon: DSIconName.delete,
                          label: 'Delete class',
                          size: 36,
                          onPressed: () => _confirmDelete(c),
                        ),
                        const DSIcon(DSIconName.chevron, size: 20),
                      ]),
                    ),
                  ),
              ]);
            },
          ),
        ]))),
      ]),
    );
  }

  Future<void> _confirmDelete(Json c) async {
    final ok = await showDSModal<bool>(
      context,
      title: 'Delete class?',
      body: Text('This removes "${c['name']}" and its lessons. Students lose access.',
          style: DSText.body),
      actions: [
        DSButton(
          variant: DSButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep it'),
        ),
        DSButton(
          variant: DSButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
    if (ok == true) {
      await ref.read(repoProvider).deleteClass('${c['id']}');
      ref.invalidate(teacherClassesProvider);
    }
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
    return bits.join(' · ');
  }
}
