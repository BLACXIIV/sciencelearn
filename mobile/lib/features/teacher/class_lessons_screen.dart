import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'class_portal_header.dart';
import 'lesson_activities_screen.dart';

/// The class curriculum: create lessons, publish/unpublish, drill into
/// each lesson's activity builder.
class ClassLessonsScreen extends ConsumerStatefulWidget {
  const ClassLessonsScreen({super.key});
  @override
  ConsumerState<ClassLessonsScreen> createState() => _LessonsState();
}

class _LessonsState extends ConsumerState<ClassLessonsScreen> {
  static const _subjects = ['Physics', 'Chemistry', 'Earth Science'];
  final _title = TextEditingController();
  final _objectives = TextEditingController();
  String _subject = _subjects.first;
  bool _busy = false;
  String? _error;

  String get _classId => '${currentClass.value?['id']}';

  @override
  void dispose() { _title.dispose(); _objectives.dispose(); super.dispose(); }

  Future<void> _createLesson() async {
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(repoProvider).createLesson(
          _classId, _title.text.trim(), _subject, _objectives.text.trim());
      _title.clear();
      _objectives.clear();
      ref.invalidate(classLessonsProvider(_classId));
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = currentClass.value;
    if (cls == null) return const Scaffold(body: SizedBox.shrink());
    final lessons = ref.watch(classLessonsProvider(_classId));

    return Scaffold(
      body: Column(children: [
        const ClassPortalHeader(),
        Expanded(child: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
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
          const SizedBox(height: 16),
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
                onPressed: () => ref.invalidate(classLessonsProvider(_classId)),
                child: const Text('Try again'),
              ),
            ),
            data: (rows) => Column(children: [
              if (rows.isEmpty)
                const DSCard(child: DSEmptyState(icon: DSIconName.lessons, title: 'No lessons yet',
                    body: 'Add the first one above.')),
              for (final l in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
                          ref.invalidate(classLessonsProvider(_classId));
                        },
                        child: Text(l['is_published'] == true ? 'Unpublish' : 'Publish'),
                      ),
                      const SizedBox(width: 8),
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
