import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'class_portal_header.dart';

bool _needsAttention(Json? p) =>
    p == null || p['quizzes_pct'] == null || (p['quizzes_pct'] as num) < 70;

/// Roster + access control + per-student progress, all scoped to this class.
/// Navy edge-bleeding header carries the join code; the class's danger zone
/// (delete) lives at the bottom.
class ClassStudentsScreen extends ConsumerStatefulWidget {
  const ClassStudentsScreen({super.key});

  @override
  ConsumerState<ClassStudentsScreen> createState() =>
      _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends ConsumerState<ClassStudentsScreen> {
  bool _attentionOnly = false;
  String _query = '';

  void _refresh(String classId) {
    ref.invalidate(classMembersProvider(classId));
    ref.invalidate(classProgressProvider(classId));
  }

  Future<void> _deleteClass(BuildContext context, Json cls) async {
    final ok = await showDSModal<bool>(
      context,
      title: 'Delete this class?',
      body: Text(
          'This removes "${cls['name']}" and its lessons. Students lose access.',
          style: DSText.body),
      actions: [
        DSButton(
          variant: DSButtonVariant.outline,
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

  Future<void> _removeStudent(
      BuildContext context, String classId, Json m) async {
    final ok = await showDSModal<bool>(
      context,
      title: 'Remove from class?',
      body: Text(
          '"${m['profiles']?['full_name'] ?? 'This student'}" loses access to this class.',
          style: DSText.body),
      actions: [
        DSButton(
          variant: DSButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        DSButton(
          variant: DSButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
      ],
    );
    if (ok != true) return;
    await ref.read(repoProvider).removeMember(classId, '${m['student_id']}');
    _refresh(classId);
  }

  @override
  Widget build(BuildContext context) {
    final cls = currentClass.value;
    if (cls == null) return const Scaffold(body: SizedBox.shrink());
    final classId = '${cls['id']}';
    final members = ref.watch(classMembersProvider(classId));
    final progress = ref.watch(classProgressProvider(classId));
    final progById = {
      for (final p in progress.valueOrNull ?? []) '${p['student_id']}': p,
    };

    return Scaffold(
      body: Column(children: [
        ClassHeroHeader(cls: cls),
        Expanded(
          child: MaxWidth(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                members.when(skipLoadingOnRefresh: true, 
                  loading: () => const Center(child: DSLoadingIndicator()),
                  error: (e, _) => DSEmptyState(
                    icon: DSIconName.offline,
                    title: "Couldn't load this right now",
                    body: 'Check your connection and try again.',
                    action: DSButton(
                      variant: DSButtonVariant.outline,
                      size: DSButtonSize.sm,
                      leadingIcon: DSIconName.retry,
                      onPressed: () => _refresh(classId),
                      child: const Text('Try again'),
                    ),
                  ),
                  data: (rows) {
                    final pending =
                        rows.where((r) => r['status'] == 'pending').toList();
                    final active =
                        rows.where((r) => r['status'] == 'active').toList();
                    final shown = active.where((m) {
                      if (_attentionOnly &&
                          !_needsAttention(progById['${m['student_id']}'])) {
                        return false;
                      }
                      if (_query.isNotEmpty &&
                          !('${m['profiles']?['full_name'] ?? ''}')
                              .toLowerCase()
                              .contains(_query.toLowerCase())) {
                        return false;
                      }
                      return true;
                    }).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pending.isNotEmpty) ...[
                          Row(children: [
                            Text('Requests', style: DSText.title),
                            const SizedBox(width: 8),
                            _CountPill(count: pending.length, sun: true),
                          ]),
                          const SizedBox(height: 10),
                          for (final m in pending)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RequestCard(
                                member: m,
                                className: '${cls['name']}',
                                onApprove: () async {
                                  await ref.read(repoProvider).approveMember(
                                      classId, '${m['student_id']}');
                                  _refresh(classId);
                                },
                                onDecline: () async {
                                  await ref.read(repoProvider).removeMember(
                                      classId, '${m['student_id']}');
                                  _refresh(classId);
                                },
                              ),
                            ),
                          const SizedBox(height: 10),
                        ],
                        Row(children: [
                          Text('Students', style: DSText.title),
                          const SizedBox(width: 8),
                          _CountPill(count: active.length),
                        ]),
                        const SizedBox(height: 10),
                        _FilterChips(
                          attentionOnly: _attentionOnly,
                          onChanged: (v) => setState(() => _attentionOnly = v),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Search students',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: DSIcon(DSIconName.search,
                                    size: 18, color: DSColors.muted),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 42, minHeight: 42),
                              isDense: true,
                              filled: true,
                              fillColor: DSColors.surface,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: DSRadii.inputBr,
                                borderSide:
                                    const BorderSide(color: DSColors.line),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: DSRadii.inputBr,
                                borderSide:
                                    const BorderSide(color: DSColors.line),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (active.isEmpty)
                          const _RosterEmpty()
                        else if (shown.isEmpty)
                          Text('No students match this filter.',
                              style:
                                  DSText.body.copyWith(color: DSColors.muted)),
                        for (final m in shown)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RosterCard(
                              member: m,
                              progress: progById['${m['student_id']}'],
                              onOpen: () => context.push(
                                  '/teacher/students/report/${m['student_id']}'),
                              onRemove: () =>
                                  _removeStudent(context, classId, m),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('Danger zone', style: DSText.title),
                const SizedBox(height: 10),
                DSCard(
                    child: Row(children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Danger zone',
                          style: DSText.label.copyWith(color: DSColors.navy)),
                      const SizedBox(height: 4),
                      Text(
                        'Deletes the class, its lessons and activities.',
                        style: DSText.caption.copyWith(color: DSColors.muted),
                      ),
                    ],
                  )),
                  const SizedBox(width: 10),
                  DSButton(
                    variant: DSButtonVariant.danger,
                    size: DSButtonSize.sm,
                    onPressed: () => _deleteClass(context, cls),
                    child: const Text('Delete'),
                  ),
                ])),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

/// Navy edge-bleeding header: class name + switch/account tiles, then the
class _CountPill extends StatelessWidget {
  final int count;
  final bool sun;
  const _CountPill({required this.count, this.sun = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: sun ? DSColors.sun : DSColors.pastelBlue,
        borderRadius: DSRadii.pillBr,
      ),
      child: Center(
        child: Text('$count',
            style: DSText.label.copyWith(fontSize: 12, color: DSColors.navy)),
      ),
    );
  }
}

/// Join-request card: avatar + name on top, Decline / Approve buttons under.
class _RequestCard extends StatelessWidget {
  final Json member;
  final String className;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  const _RequestCard({
    required this.member,
    required this.className,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${member['profiles']?['full_name'] ?? '(no name)'}';
    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            DSAvatar(name: name, size: 40, pastel: DSAvatarPastel.yellow),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: DSText.title)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: DSButton(
                variant: DSButtonVariant.outline,
                size: DSButtonSize.sm,
                onPressed: onDecline,
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DSButton(
                variant: DSButtonVariant.mint,
                size: DSButtonSize.sm,
                onPressed: onApprove,
                child: const Text('Approve'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// All / Needs attention filter chips — active chip is navy with white text.
class _FilterChips extends StatelessWidget {
  final bool attentionOnly;
  final ValueChanged<bool> onChanged;
  const _FilterChips({required this.attentionOnly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool on, VoidCallback tap) {
      return GestureDetector(
        onTap: tap,
        child: Semantics(
          selected: on,
          button: true,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: on ? DSColors.navy : DSColors.surface,
              borderRadius: DSRadii.pillBr,
              border: Border.all(color: on ? DSColors.navy : DSColors.line),
            ),
            child: Center(
              child: Text(
                label,
                style: DSText.label.copyWith(
                  fontSize: 14,
                  color: on ? DSColors.surface : DSColors.navy,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Wrap: "Needs attention" drops under "All" on narrow screens instead
    // of overflowing the row.
    return Wrap(spacing: 8, runSpacing: 8, children: [
      chip('All', !attentionOnly, () => onChanged(false)),
      chip('Needs attention', attentionOnly, () => onChanged(true)),
    ]);
  }
}

/// One tappable roster card: pastel-blue border, avatar + name, mini stat
/// bars, chevron to the report and a "···" menu (doesn't navigate).
class _RosterCard extends StatelessWidget {
  final Json member;
  final Json? progress;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  const _RosterCard({
    required this.member,
    required this.progress,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${member['profiles']?['full_name'] ?? '(no name)'}';
    final p = progress;
    return Material(
      color: DSColors.surface,
      borderRadius: DSRadii.rowBr,
      child: InkWell(
        borderRadius: DSRadii.rowBr,
        onTap: onOpen,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Fill is required — without it the solid edge shadow shows
            // through the transparent interior and tints the whole card.
            color: DSColors.surface,
            borderRadius: DSRadii.rowBr,
            border: Border.all(color: DSColors.pastelBlue, width: 3),
            boxShadow: dsEdge(DSColors.edgeSoft, h: 4),
          ),
          child: Column(children: [
            Row(children: [
              DSAvatar(name: name, size: 40),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: DSText.title),
                  Text('Tap to open report',
                      style: DSText.caption.copyWith(color: DSColors.muted)),
                ],
              )),
              Semantics(
                button: true,
                label: 'More actions for $name',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    // Menu — not a direct remove: keeps the tap target an
                    // affordance and leaves room for future row actions.
                    final act = await showDSBottomSheet<String>(
                      context,
                      child: ListTile(
                        leading: const DSIcon(DSIconName.delete,
                            size: 22, color: DSColors.error),
                        title: Text('Remove from class',
                            style:
                                DSText.title.copyWith(color: DSColors.error)),
                        shape: RoundedRectangleBorder(
                            borderRadius: DSRadii.inputBr),
                        onTap: () => Navigator.of(context).pop('remove'),
                      ),
                    );
                    if (act == 'remove') onRemove();
                  },
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: DSIcon(DSIconName.more,
                          size: 20, color: DSColors.muted),
                    ),
                  ),
                ),
              ),
              const DSIcon(DSIconName.chevron, size: 20, color: DSColors.muted),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _MiniStat(
                  label: 'Lessons',
                  value: p == null
                      ? '—'
                      : '${(p['lessons_pct'] as num?)?.round() ?? 0}%',
                  bar: ((p?['lessons_pct'] as num?)?.toDouble() ?? 0) / 100,
                  tone: DSProgressBarTone.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Quiz',
                  value:
                      p?['quizzes_pct'] == null ? '—' : '${p!['quizzes_pct']}%',
                  bar: ((p?['quizzes_pct'] as num?)?.toDouble() ?? 0) / 100,
                  tone: DSProgressBarTone.blue,
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final double bar;
  final DSProgressBarTone tone;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.bar,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: DSText.caption.copyWith(color: DSColors.muted)),
      const SizedBox(height: 2),
      Text(value,
          style: DSText.label.copyWith(fontSize: 13, color: DSColors.navy)),
      const SizedBox(height: 5),
      DSProgressBar(value: bar, size: DSProgressBarSize.sm, tone: tone),
    ]);
  }
}

/// Dashed roster-empty slot — SVG C lands here when supplied.
class _RosterEmpty extends StatelessWidget {
  const _RosterEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: DSRadii.rowBr,
        border: Border.all(color: DSColors.pastelBlue, width: 2),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/illustrations/roster_empty.png',
            width: 120, height: 90),
        const SizedBox(height: 8),
        Text('No students yet — share the join code with your class.',
            textAlign: TextAlign.center,
            style: DSText.body.copyWith(color: DSColors.muted)),
      ]),
    );
  }
}
