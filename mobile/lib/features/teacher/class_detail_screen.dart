import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
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
      appBar: AppBar(title: Text('${widget.cls['name']}')),
      body: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Join code', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('${widget.cls['code']}', style: const TextStyle(
                  fontSize: 20, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 2)),
              Text(approval ? 'Students request to join' : 'Students join instantly',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ])),
            IconButton(
              icon: const Icon(AppIcons.copy),
              tooltip: 'Copy code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${widget.cls['code']}'));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
              },
            ),
          ]),
        ),
        const SizedBox(height: 16),
        members.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(onRetry: _refresh),
          data: (rows) {
            final pending = rows.where((r) => r['status'] == 'pending').toList();
            final active = rows.where((r) => r['status'] == 'active').toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (pending.isNotEmpty) ...[
                Text('Requests (${pending.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final m in pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(child: Column(children: [
                      Row(children: [
                        const Icon(AppIcons.pending, size: 18, color: AppColors.orange),
                        const SizedBox(width: 10),
                        Expanded(child: Text('${m['profiles']?['full_name'] ?? '(no name)'}',
                            style: const TextStyle(fontWeight: FontWeight.w600))),
                      ]),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(spacing: 4, children: [
                          TextButton(
                            onPressed: () async {
                              await ref.read(repoProvider).approveMember(_classId, '${m['student_id']}');
                              _refresh();
                            },
                            child: const Text('Approve'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await ref.read(repoProvider).removeMember(_classId, '${m['student_id']}');
                              _refresh();
                            },
                            child: Text('Decline', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ),
                        ]),
                      ),
                    ])),
                  ),
                const SizedBox(height: 8),
              ],
              Text('Students (${active.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (active.isEmpty)
                const AppCard(child: EmptyState(icon: AppIcons.students, title: 'No students yet',
                    message: 'Share the join code with your class.')),
              for (final m in active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(child: Row(children: [
                    Icon(AppIcons.account, size: 18, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${m['profiles']?['full_name'] ?? '(no name)'}',
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    IconButton(
                      icon: const Icon(AppIcons.delete, size: 18),
                      tooltip: 'Remove from class',
                      onPressed: () async {
                        await ref.read(repoProvider).removeMember(_classId, '${m['student_id']}');
                        _refresh();
                      },
                    ),
                  ])),
                ),
            ]);
          },
        ),
        const SizedBox(height: 16),
        const Text('Lessons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('New lesson', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _subject,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [for (final s in _subjects) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) => setState(() => _subject = v ?? _subjects.first),
            ),
            const SizedBox(height: 10),
            TextField(controller: _objectives, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Objectives')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _createLesson,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add lesson'),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
        lessons.when(
          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => ErrorState(onRetry: _refresh),
          data: (rows) => Column(children: [
            if (rows.isEmpty)
              const AppCard(child: EmptyState(icon: AppIcons.lessons, title: 'No lessons yet',
                  message: 'Add the first one above.')),
            for (final l in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LessonActivitiesScreen(lesson: l))),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${l['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${l['subject']}${l['is_published'] == true ? ' Â· published' : ' Â· draft'}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ])),
                    TextButton(
                      onPressed: () async {
                        await ref.read(repoProvider).setPublished('${l['id']}', l['is_published'] != true);
                        _refresh();
                      },
                      child: Text(l['is_published'] == true ? 'Unpublish' : 'Publish'),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ])),
    );
  }
}
