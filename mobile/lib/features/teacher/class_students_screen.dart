import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'class_portal_header.dart';

/// Roster + access control + per-student progress, all scoped to this class.
/// The class's danger zone (delete) lives at the bottom.
class ClassStudentsScreen extends ConsumerWidget {
  const ClassStudentsScreen({super.key});

  void _refresh(WidgetRef ref, String classId) {
    ref.invalidate(classMembersProvider(classId));
    ref.invalidate(classProgressProvider(classId));
  }

  Future<void> _deleteClass(BuildContext context, WidgetRef ref, Json cls) async {
    final ok = await showDSModal<bool>(
      context,
      title: 'Delete this class?',
      body: Text(
        'This removes "${cls['name']}" and its lessons. Students lose access.',
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
    if (ok != true || !context.mounted) return;
    await ref.read(repoProvider).deleteClass('${cls['id']}');
    if (!context.mounted) return;
    currentClass.value = null;
    classPicked.value = false;
    context.go('/select-class');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cls = currentClass.value;
    if (cls == null) return const Scaffold(body: SizedBox.shrink());
    final classId = '${cls['id']}';
    final members = ref.watch(classMembersProvider(classId));
    final progress = ref.watch(classProgressProvider(classId));
    final approval = cls['join_policy'] == 'approval';
    final progById = {
      for (final p in progress.valueOrNull ?? []) '${p['student_id']}': p,
    };

    return Scaffold(
      body: Column(children: [
        const ClassPortalHeader(),
        Expanded(child: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
          DSCard(child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Join code', style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 4),
              DSChip(child: Text('${cls['code']}',
                  style: DSText.label.copyWith(letterSpacing: 1.5))),
              Text(approval ? 'Students request to join' : 'Students join instantly',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
            ])),
            DSIconButton(
              icon: DSIconName.copy,
              label: 'Copy code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${cls['code']}'));
                DSToast.show(context, message: 'Code copied', tone: DSToastTone.success);
              },
            ),
          ])),
          const SizedBox(height: 16),
          members.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => DSEmptyState(
              icon: DSIconName.offline,
              title: "Couldn't load this right now",
              body: 'Check your connection and try again.',
              action: DSButton(
                variant: DSButtonVariant.outline,
                size: DSButtonSize.sm,
                leadingIcon: DSIconName.retry,
                onPressed: () => _refresh(ref, classId),
                child: const Text('Try again'),
              ),
            ),
            data: (rows) {
              final pending = rows.where((r) => r['status'] == 'pending').toList();
              final active = rows.where((r) => r['status'] == 'active').toList();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (pending.isNotEmpty) ...[
                  Text('Requests (${pending.length})', style: DSText.title),
                  const SizedBox(height: 8),
                  for (final m in pending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DSListItemCard(
                        leading: const DSIcon(DSIconName.pending, size: 20),
                        title: Text('${m['profiles']?['full_name'] ?? '(no name)'}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          DSButton(
                            variant: DSButtonVariant.mint,
                            size: DSButtonSize.sm,
                            onPressed: () async {
                              await ref.read(repoProvider).approveMember(classId, '${m['student_id']}');
                              _refresh(ref, classId);
                            },
                            child: const Text('Approve'),
                          ),
                          DSIconButton(
                            icon: DSIconName.delete,
                            label: 'Decline',
                            size: 36,
                            onPressed: () async {
                              await ref.read(repoProvider).removeMember(classId, '${m['student_id']}');
                              _refresh(ref, classId);
                            },
                          ),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                Text('Students (${active.length})', style: DSText.title),
                const SizedBox(height: 8),
                if (active.isEmpty)
                  const DSCard(child: DSEmptyState(icon: DSIconName.students, title: 'No students yet',
                      body: 'Share the join code with your class.')),
                for (final m in active)
                  Builder(builder: (_) {
                    final p = progById['${m['student_id']}'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DSListItemCard(
                        leading: DSAvatar(name: '${m['profiles']?['full_name'] ?? '?'}'),
                        title: Text('${m['profiles']?['full_name'] ?? '(no name)'}'),
                        subtitle: Text(p == null
                            ? 'No progress yet'
                            : 'Lessons ${(p['lessons_pct'] as num?)?.round() ?? 0}%'
                                ' · Quiz ${p['quizzes_pct'] ?? '–'}%'
                                ' · Pre ${p['pre_score'] ?? '–'} → Post ${p['post_score'] ?? '–'}'),
                        trailing: DSIconButton(
                          icon: DSIconName.delete,
                          label: 'Remove from class',
                          size: 36,
                          onPressed: () async {
                            await ref.read(repoProvider).removeMember(classId, '${m['student_id']}');
                            _refresh(ref, classId);
                          },
                        ),
                      ),
                    );
                  }),
              ]);
            },
          ),
          const SizedBox(height: 24),
          Text('Danger zone', style: DSText.title),
          const SizedBox(height: 8),
          DSCard(child: Row(children: [
            Expanded(child: Text(
              'Deleting removes the class, its lessons and activities for everyone.',
              style: DSText.caption.copyWith(color: DSColors.muted),
            )),
            const SizedBox(width: 10),
            DSButton(
              variant: DSButtonVariant.danger,
              size: DSButtonSize.sm,
              leadingIcon: DSIconName.delete,
              onPressed: () => _deleteClass(context, ref, cls),
              child: const Text('Delete class'),
            ),
          ])),
        ]))),
      ]),
    );
  }
}
