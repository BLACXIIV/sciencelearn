import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/icons.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import 'lesson_activities_screen.dart';

/// Mirrors Manage Lessons on web: create form + publish/unpublish list.
/// Thumbnail/material file upload stays web-only (no file picker on mobile yet).
class TeacherLessonsScreen extends ConsumerStatefulWidget {
  const TeacherLessonsScreen({super.key});
  @override
  ConsumerState<TeacherLessonsScreen> createState() => _TeacherLessonsState();
}

class _TeacherLessonsState extends ConsumerState<TeacherLessonsScreen> {
  static const _subjects = ['Physics', 'Chemistry', 'Earth Science'];
  final _title = TextEditingController();
  final _objectives = TextEditingController();
  String _subject = _subjects.first;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _objectives.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(repoProvider).createLesson(_title.text.trim(), _subject, _objectives.text.trim());
      _title.clear();
      _objectives.clear();
      ref.invalidate(allLessonsProvider);
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(allLessonsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Lessons')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
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
              onPressed: _busy ? null : _create,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create lesson'),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
        const SizedBox(height: 16),
        lessons.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(onRetry: () => ref.invalidate(allLessonsProvider)),
          data: (rows) => Column(children: [
            if (rows.isEmpty)
              const AppCard(child: EmptyState(icon: AppIcons.lessons, title: 'No lessons yet',
                  message: 'Create the first one above.')),
            for (final l in rows)
              AppCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LessonActivitiesScreen(lesson: l))),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${l['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${l['subject']}${l['is_published'] == true ? ' · published' : ' · draft'}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ])),
                  TextButton(
                    onPressed: () async {
                      await ref.read(repoProvider).setPublished('${l['id']}', l['is_published'] != true);
                      ref.invalidate(allLessonsProvider);
                    },
                    child: Text(l['is_published'] == true ? 'Unpublish' : 'Publish'),
                  ),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}
