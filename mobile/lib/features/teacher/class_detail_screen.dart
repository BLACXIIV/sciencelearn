import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'lesson_activities_screen.dart';

final _membersProvider = FutureProvider.autoDispose
    .family<List<Json>, String>((ref, id) => ref.read(repoProvider).classMembers(id));

final _classLessonsProvider = FutureProvider.autoDispose
    .family<List<Json>, String>((ref, id) => ref.read(repoProvider).classLessons(id));

/// One class: header (name, code, policy) -> pending requests -> roster -> lessons CRUD.
class ClassDetailScreen extends ConsumerStatefulWidget {
  final Json cls;
  const ClassDetailScreen({super.key, required this.cls});
  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailState();
}

class _ClassDetailState extends ConsumerState<ClassDetailScreen> {
  static const _subjects = ['Physics', 'Chemistry', 'Earth Science'];
  final _title = TextEditingController();
  final _objectives = TextEditingController();
  String _subject = _subjects.first;
  bool _busy = false;
  String? _error;

  String get _classId => '${widget.cls['id']}';

  @override
  void dispose() { _title.dispose(); _objectives.dispose(); super.dispose(); }

  void _refresh() {
    ref.invalidate(_membersProvider(_classId));
    ref.invalidate(_classLessonsProvider(_classId));
  }

  Future<void> _createLesson() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(repoProvider).createLesson(
          _classId, _title.text.trim(), _subject, _objectives.text.trim());
      _title.clear();
      _objectives.clear();
      _refresh();
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(_membersProvider(_classId));
    final lessons = ref.watch(_classLessonsProvider(_classId));
    final approval = widget.cls['join_policy'] == 'approval';
    return Scaffold(
      body: Column(children: [
        DSPageHeader(
          compact: true,
          child: SafeArea(
            bottom: false,
            child: Row(children: [
              DSIconButton(
                icon: DSIconName.back,
                label: 'Back',
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('${widget.cls['name']}', style: DSText.h2)),
            ]),
          ),
        ),
        Expanded(child: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
          DSCard(child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Join code', style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 4),
              DSChip(child: Text('${widget.cls['code']}',
                  style: DSText.label.copyWith(letterSpacing: 1.5))),
              Text(approval ? 'Students request to join' : 'Students join instantly',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
            ])),
            DSIconButton(
              icon: DSIconName.copy,
              label: 'Copy code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${widget.cls['code']}'));
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
                onPressed: _refresh,
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
                              await ref.read(repoProvider).approveMember(_classId, '${m['student_id']}');
                              _refresh();
                            },
                            child: const Text('Approve'),
                          ),
                          DSIconButton(
                            icon: DSIconName.delete,
                            label: 'Decline',
                            size: 36,
                            onPressed: () async {
                              await ref.read(repoProvider).removeMember(_classId, '${m['student_id']}');
                              _refresh();
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DSListItemCard(
                      leading: DSAvatar(name: '${m['profiles']?['full_name'] ?? '?'}'),
                      title: Text('${m['profiles']?['full_name'] ?? '(no name)'}'),
                      trailing: DSIconButton(
                        icon: DSIconName.delete,
                        label: 'Remove from class',
                        size: 36,
                        onPressed: () async {
                          await ref.read(repoProvider).removeMember(_classId, '${m['student_id']}');
                          _refresh();
                        },
                      ),
                    ),
                  ),
              ]);
            },
          ),
          const SizedBox(height: 16),
          Text('Lessons', style: DSText.title),
          const SizedBox(height: 8),
          DSCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('New lesson', style: DSText.title),
            const SizedBox(height: 10),
            DSTextField(label: 'Title', controller: _title),
            const SizedBox(height: 10),
            DSSelect(
              label: 'Subject',
              value: _subject,
              options: [for (final s in _subjects) DSSelectOption(s, s)],
              onChanged: (v) => setState(() => _subject = v ?? _subjects.first),
            ),
            const SizedBox(height: 10),
            DSTextArea(label: 'Objectives', controller: _objectives, minLines: 2),
            const SizedBox(height: 12),
            DSButton(
              onPressed: _busy ? null : _createLesson,
              loading: _busy,
              child: const Text('Add lesson'),
            ),
            if (_error != null)
              Text(_error!, style: DSText.caption.copyWith(color: DSColors.error)),
          ])),
          const SizedBox(height: 8),
          lessons.when(
            loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => DSEmptyState(
              icon: DSIconName.offline,
              title: "Couldn't load this right now",
              body: 'Check your connection and try again.',
              action: DSButton(
                variant: DSButtonVariant.outline,
                size: DSButtonSize.sm,
                leadingIcon: DSIconName.retry,
                onPressed: _refresh,
                child: const Text('Try again'),
              ),
            ),
            data: (rows) => Column(children: [
              if (rows.isEmpty)
                const DSCard(child: DSEmptyState(icon: DSIconName.lessons, title: 'No lessons yet',
                    body: 'Add the first one above.')),
              for (final l in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: DSListItemCard(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => LessonActivitiesScreen(lesson: l))),
                    title: Text('${l['title']}'),
                    subtitle: Text('${l['subject']}${l['is_published'] == true ? ' · published' : ' · draft'}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      DSButton(
                        variant: DSButtonVariant.outline,
                        size: DSButtonSize.sm,
                        onPressed: () async {
                          await ref.read(repoProvider).setPublished('${l['id']}', l['is_published'] != true);
                          _refresh();
                        },
                        child: Text(l['is_published'] == true ? 'Unpublish' : 'Publish'),
                      ),
                      const DSIcon(DSIconName.chevron, size: 20),
                    ]),
                  ),
                ),
            ]),
          ),
        ]))),
      ]),
    );
  }
}
