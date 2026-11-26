import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'class_portal_header.dart';
import 'lesson_activities_screen.dart';

/// Subjects come from [subjectsN] (repository.dart) — built-ins plus
/// teacher-added customs, synced via profiles.settings.subjects.
const _statusOptions = ['All status', 'Published', 'Drafts'];

/// The class curriculum: subject-filtered lesson cards + a "+ New lesson"
/// bottom sheet. Publish switch, edit and delete live on each card.
class ClassLessonsScreen extends ConsumerStatefulWidget {
  const ClassLessonsScreen({super.key});
  @override
  ConsumerState<ClassLessonsScreen> createState() => _LessonsState();
}

class _LessonsState extends ConsumerState<ClassLessonsScreen> {
  String _subject = 'all';
  String _status = 'All status';

  @override
  void initState() {
    super.initState();
    loadSubjects();
  }

  String get _classId => '${currentClass.value?['id']}';

  void _invalidate() {
    ref.invalidate(classLessonsProvider(_classId));
    ref.invalidate(lessonActivityCountsProvider(_classId));
    ref.invalidate(lessonAttemptCountsProvider(_classId));
  }

  /// Activities live on a pushed route — refresh counts when we pop back
  /// so "N activities" reflects anything built in the builder.
  Future<void> _openActivities(Json lesson) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LessonActivitiesScreen(lesson: lesson)));
    if (mounted) _invalidate();
  }

  Future<void> _openSheet({Json? lesson}) async {
    // Refresh the synced subject list each open — the tab stays alive in the
    // IndexedStack, so initState alone would go stale across devices.
    loadSubjects();
    await showDSBottomSheet<void>(
      context,
      // Deep-navy scrim for this sheet only (mockup: #07124A at 60%).
      barrierColor: DSColors.navyDeep.withValues(alpha: 0.6),
      child: _LessonSheet(classId: _classId, lesson: lesson),
    );
    _invalidate();
  }

  Future<void> _togglePublish(Json lesson) async {
    final turningOff = lesson['is_published'] == true;
    final attempts =
        ref.read(lessonAttemptCountsProvider(_classId)).valueOrNull?[
                '${lesson['id']}'] ??
            0;
    if (turningOff && attempts > 0) {
      // Students already took it — confirm before hiding the lesson.
      final ok = await showDSModal<bool>(
        context,
        title: 'Unpublish this lesson?',
        body: Text(
            'Students have already submitted attempts in “${lesson['title']}”. '
            'Unpublishing hides the lesson but keeps their scores.'),
        actions: [
          DSButton(
              variant: DSButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          DSButton(
              variant: DSButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unpublish')),
        ],
      );
      if (ok != true) return;
    }
    try {
      await ref
          .read(repoProvider)
          .setPublished('${lesson['id']}', lesson['is_published'] != true);
      _invalidate();
    } catch (e) {
      if (mounted) {
        DSToast.show(context, message: '$e', tone: DSToastTone.error);
      }
    }
  }

  Future<void> _openMenu(Json lesson, int activities) async {
    final act = await showDSBottomSheet<String>(
      context,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading:
              const DSIcon(DSIconName.edit, size: 22, color: DSColors.navy),
          title: Text('Edit', style: DSText.title),
          shape:
              RoundedRectangleBorder(borderRadius: DSRadii.inputBr),
          onTap: () => Navigator.of(context).pop('edit'),
        ),
        ListTile(
          leading: const DSIcon(DSIconName.delete,
              size: 22, color: DSColors.error),
          title: Text('Delete',
              style: DSText.title.copyWith(color: DSColors.error)),
          shape:
              RoundedRectangleBorder(borderRadius: DSRadii.inputBr),
          onTap: () => Navigator.of(context).pop('delete'),
        ),
      ]),
    );
    if (!mounted) return;
    if (act == 'edit') {
      _openSheet(lesson: lesson);
    } else if (act == 'delete') {
      if (activities > 0) {
        // Assessments detach on delete — block instead of orphaning them.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Delete or move its activities first.')));
        return;
      }
      _confirmDelete(lesson);
    }
  }

  Future<void> _confirmDelete(Json lesson) async {
    final ok = await showDSModal<bool>(
      context,
      title: 'Delete this lesson?',
      body: Text(
          'This also removes students’ progress for “${lesson['title']}”.'),
      actions: [
        DSButton(
            variant: DSButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        DSButton(
            variant: DSButtonVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete')),
      ],
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(repoProvider).deleteLesson('${lesson['id']}');
      _invalidate();
    } catch (e) {
      if (mounted) {
        DSToast.show(context, message: '$e', tone: DSToastTone.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = currentClass.value;
    if (cls == null) return const Scaffold(body: SizedBox.shrink());
    final lessons = ref.watch(classLessonsProvider(_classId));
    final counts = ref.watch(lessonActivityCountsProvider(_classId));

    final rows = lessons.valueOrNull ?? const <Json>[];
    // A custom subject deleted elsewhere falls back to 'all' rather than
    // filtering everything out.
    final activeSub =
        _subject != 'all' && !subjectsN.value.contains(_subject)
            ? 'all'
            : _subject;
    final filtered = rows.where((l) {
      if (activeSub != 'all' && '${l['subject']}' != activeSub) return false;
      if (_status != 'All status' &&
          (l['is_published'] == true) != (_status == 'Published')) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      body: Column(children: [
        ClassHeroHeader(cls: cls),
        Expanded(
            child: MaxWidth(
                child: ListView(padding: const EdgeInsets.all(16), children: [
          // Wrap, not Row — on narrow screens / large text scale the button
          // drops to its own line instead of overflowing the right edge.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Lessons', style: DSText.h3),
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                      color: DSColors.pastelBlue,
                      borderRadius: DSRadii.pillBr),
                  alignment: Alignment.center,
                  child: Text('${filtered.length}',
                      style: DSText.label.copyWith(fontSize: 12)),
                ),
              ]),
              DSButton(
                variant: DSButtonVariant.mint,
                size: DSButtonSize.sm,
                leadingIcon: DSIconName.add,
                onPressed: () => _openSheet(),
                child: const Text('New lesson'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ValueListenableBuilder<List<String>>(
              valueListenable: subjectsN,
              builder: (_, subs, __) => Row(children: [
                for (final s in ['all', ...subs])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: s == 'all' ? 'All' : s,
                      selected: activeSub == s,
                      onTap: () => setState(() => _subject = s),
                    ),
                  ),
                _StatusChip(
                  value: _status,
                  onChanged: (v) => setState(() => _status = v),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          lessons.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: DSLoadingIndicator())),
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
            data: (_) {
              if (filtered.isEmpty) {
                return DSCard(
                    child: DSEmptyState(
                  art: 'assets/illustrations/lessons_empty.png',
                  title: rows.isEmpty
                      ? 'No lessons yet'
                      : 'No lessons match these filters',
                  body: rows.isEmpty
                      ? 'Create the first one — it starts as a draft.'
                      : 'Try a different subject or status.',
                ));
              }
              return Column(children: [
                for (final l in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LessonCard(
                      lesson: l,
                      activities:
                          counts.valueOrNull?['${l['id']}'] ?? 0,
                      onTogglePublish: () => _togglePublish(l),
                      onOpen: () => _openActivities(l),
                      onMenu: () => _openMenu(
                          l, counts.valueOrNull?['${l['id']}'] ?? 0),
                    ),
                  ),
              ]);
            },
          ),
        ]))),
      ]),
    );
  }
}

/// White pill chip — navy fill when selected. Used for subject filters and
/// the status dropdown trigger.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? DSColors.navy : DSColors.surface,
            borderRadius: DSRadii.pillBr,
            border:
                Border.all(color: selected ? DSColors.navy : DSColors.line),
            boxShadow:
                selected ? const [] : dsEdge(DSColors.edgeSoft, h: 3),
          ),
          child: Center(
            child: Text(
              label,
              style: DSText.label.copyWith(
                fontSize: 14,
                color: selected ? DSColors.surface : DSColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status filter — last item in the chip row; opens a small picker sheet.
class _StatusChip extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _StatusChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final v = await showDSBottomSheet<String>(
          context,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final o in _statusOptions)
              ListTile(
                title: Text(o, style: DSText.title),
                trailing: value == o
                    ? const DSIcon(DSIconName.check,
                        size: 20, color: DSColors.blue)
                    : null,
                shape: RoundedRectangleBorder(
                    borderRadius: DSRadii.inputBr),
                onTap: () => Navigator.of(context).pop(o),
              ),
          ]),
        );
        if (v != null) onChanged(v);
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: DSRadii.pillBr,
          border: Border.all(color: DSColors.line),
          boxShadow: dsEdge(DSColors.edgeSoft, h: 3),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: DSText.label.copyWith(fontSize: 14)),
          const SizedBox(width: 4),
          const DSIcon(DSIconName.chevron, size: 16, color: DSColors.navy),
        ]),
      ),
    );
  }
}

/// Subject → (icon, pastel tile color) for the card thumb.
(DSIconName, Color) _subjectTile(String subject) => switch (subject) {
      'Physics' => (DSIconName.atom, DSColors.pastelBlue),
      'Chemistry' => (DSIconName.science, DSColors.pastelPurple),
      'Earth Science' => (DSIconName.globe, DSColors.pastelMint),
      _ => (DSIconName.lessons, DSColors.pastelYellow),
    };

/// 84px thumb: uploaded thumbnail (R2 signed URL) or subject pastel + icon.
class _LessonThumb extends ConsumerWidget {
  final Json lesson;
  const _LessonThumb({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = lesson['thumbnail_key'] as String?;
    final (icon, bg) = _subjectTile('${lesson['subject'] ?? ''}');
    Widget tile(String? url) => Container(
          width: 84,
          height: 84,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: DSRadii.tileBr,
          ),
          child: url != null
              ? Image.network(url,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Center(child: DSIcon(icon, size: 26, color: DSColors.ink)))
              : Center(child: DSIcon(icon, size: 26, color: DSColors.ink)),
        );
    if (key == null || key.isEmpty) return tile(null);
    return FutureBuilder<String?>(
      future: ref.read(repoProvider).signedUrl(key),
      builder: (_, s) => tile(s.data),
    );
  }
}

/// Compact lesson card: 84px thumb left; status/PDF chips, title and
/// objectives right; footer row with Activities, publish switch and "···".
class _LessonCard extends StatelessWidget {
  final Json lesson;
  final int activities;
  final VoidCallback onTogglePublish;
  final VoidCallback onOpen;
  final VoidCallback onMenu;
  const _LessonCard({
    required this.lesson,
    required this.activities,
    required this.onTogglePublish,
    required this.onOpen,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final title = '${lesson['title'] ?? ''}';
    final objectives = '${lesson['objectives'] ?? ''}';
    final subject = '${lesson['subject'] ?? ''}';
    final pub = lesson['is_published'] == true;
    final hasMaterial = (lesson['content_key'] as String?) != null;
    return Material(
      color: DSColors.surface,
      borderRadius: DSRadii.cardBr,
      child: InkWell(
        borderRadius: DSRadii.cardBr,
        onTap: onOpen,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Fill is required — without it the solid edge shadow shows
            // through the transparent interior and tints the whole card.
            color: DSColors.surface,
            borderRadius: DSRadii.cardBr,
            border: Border.all(color: DSColors.pastelBlue, width: 3),
            boxShadow: dsEdge(DSColors.edgeSoft, h: 4),
          ),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _LessonThumb(lesson: lesson),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _StatusPill(published: pub),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(subject,
                          style: DSText.label.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (hasMaterial) ...[
                      const SizedBox(width: 6),
                      const _PdfPill(),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Text(title,
                      style: DSText.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (objectives.isNotEmpty)
                    Text(objectives,
                        style: DSText.caption.copyWith(color: DSColors.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                ],
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              DSButton(
                variant: DSButtonVariant.primary,
                size: DSButtonSize.sm,
                onPressed: onOpen,
                child: const Text('Activities'),
              ),
              const SizedBox(width: 10),
              DSSwitch(
                value: pub,
                activeColor: DSColors.teal,
                onChanged: (_) => onTogglePublish(),
              ),
              const SizedBox(width: 6),
              Text(pub ? 'Published' : 'Draft',
                  style: DSText.label
                      .copyWith(fontSize: 12, color: DSColors.muted)),
              const Spacer(),
              Semantics(
                button: true,
                label: 'More actions for $title',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onMenu,
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
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Mint / yellow status chip (top of the card's text column).
class _StatusPill extends StatelessWidget {
  final bool published;
  const _StatusPill({required this.published});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: published ? DSColors.mint : DSColors.pastelYellow,
        borderRadius: DSRadii.pillBr,
      ),
      child: Text(
        published ? 'Published' : 'Draft',
        style: DSText.label.copyWith(fontSize: 11),
      ),
    );
  }
}

/// White "PDF" chip shown when the lesson has attached material.
class _PdfPill extends StatelessWidget {
  const _PdfPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSRadii.pillBr,
        border: Border.all(color: DSColors.line),
      ),
      child: Text('PDF', style: DSText.label.copyWith(fontSize: 11)),
    );
  }
}

/// Create/edit lesson sheet — fields mirror the web panel: title, subject
/// cards, objectives, thumbnail + material pickers (file_selector → R2),
/// Create/Save button with upload progress.
class _LessonSheet extends ConsumerStatefulWidget {
  final String classId;
  final Json? lesson;
  const _LessonSheet({required this.classId, this.lesson});

  @override
  ConsumerState<_LessonSheet> createState() => _LessonSheetState();
}

class _LessonSheetState extends ConsumerState<_LessonSheet> {
  late final TextEditingController _title =
      TextEditingController(text: '${widget.lesson?['title'] ?? ''}');
  late final TextEditingController _objectives =
      TextEditingController(text: '${widget.lesson?['objectives'] ?? ''}');
  late String _subject =
      '${widget.lesson?['subject'] ?? subjectsN.value.first}';
  final _subjSearch = TextEditingController();
  XFile? _thumb;
  XFile? _material;
  bool _busy = false;
  String? _error;

  bool get _editing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    _subjSearch.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _objectives.dispose();
    _subjSearch.dispose();
    super.dispose();
  }

  String _mime(XFile f) {
    final ext = f.name.split('.').last.toLowerCase();
    return const {
          'png': 'image/png',
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'webp': 'image/webp',
          'pdf': 'application/pdf',
          'mp4': 'video/mp4',
          'mov': 'video/quicktime',
        }[ext] ??
        'application/octet-stream';
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(repoProvider);
      String? thumbKey, contentKey;
      if (_thumb != null) {
        thumbKey = await repo.uploadToR2(
            await _thumb!.readAsBytes(), _thumb!.name, _mime(_thumb!),
            'thumbnails');
      }
      if (_material != null) {
        contentKey = await repo.uploadToR2(await _material!.readAsBytes(),
            _material!.name, _mime(_material!), 'lessons');
      }
      if (_editing) {
        await repo.updateLesson('${widget.lesson!['id']}',
            title: _title.text.trim(),
            subject: _subject,
            objectives: _objectives.text.trim(),
            thumbnailKey: thumbKey,
            contentKey: contentKey);
      } else {
        await repo.createLesson(widget.classId, _title.text.trim(), _subject,
            _objectives.text.trim(),
            thumbnailKey: thumbKey, contentKey: contentKey);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
              child: Text(_editing ? 'Edit lesson' : 'New lesson',
                  style: DSText.h3)),
          DSIconButton(
              icon: DSIconName.close,
              label: 'Close',
              onPressed: () => Navigator.of(context).pop()),
        ]),
        const SizedBox(height: 4),
        Text(
          _editing
              ? 'Update the details — files only replace if you pick new ones.'
              : 'Lessons start as drafts — publish when students should see them.',
          style: DSText.caption.copyWith(color: DSColors.muted),
        ),
        const SizedBox(height: 12),
        DSTextField(label: 'Title', controller: _title),
        const SizedBox(height: 10),
        Text('Subject', style: DSText.label),
        const SizedBox(height: 6),
        DSTextField(
            label: 'Search subject',
            hint: 'Type to filter',
            controller: _subjSearch),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<String>>(
          valueListenable: subjectsN,
          builder: (_, subs, __) {
            final q = _subjSearch.text.trim().toLowerCase();
            final shown = q.isEmpty
                ? subs
                : subs
                    .where((s) => s.toLowerCase().contains(q))
                    .toList();
            return SizedBox(
              height: 88,
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final s in shown)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                            width: 96,
                            child: _SubjectCard(
                              subject: s,
                              selected: _subject == s,
                              onTap: () =>
                                  setState(() => _subject = s),
                            )),
                      ),
                    const SizedBox(width: 96, child: _AddSubjectCard()),
                  ]),
            );
          },
        ),
        const SizedBox(height: 10),
        DSTextArea(label: 'Objectives', controller: _objectives, minLines: 2),
        const SizedBox(height: 10),
        DSFilePicker(
          icon: DSIconName.camera,
          label: 'Thumbnail',
          hint: 'PNG or JPG',
          fileName: _thumb?.name,
          onTap: () async {
            const group = XTypeGroup(
                label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']);
            final f = await openFile(acceptedTypeGroups: [group]);
            if (f != null) setState(() => _thumb = f);
          },
          onClear: () => setState(() => _thumb = null),
        ),
        const SizedBox(height: 8),
        DSFilePicker(
          icon: DSIconName.inbox,
          label: 'Material',
          hint: 'PDF or video',
          fileName: _material?.name,
          onTap: () async {
            const group = XTypeGroup(label: 'Files', extensions: [
              'pdf', 'mp4', 'mov', 'webm', 'pptx', 'docx',
            ]);
            final f = await openFile(acceptedTypeGroups: [group]);
            if (f != null) setState(() => _material = f);
          },
          onClear: () => setState(() => _material = null),
        ),
        const SizedBox(height: 14),
        DSButton(
          onPressed: _busy ? null : _submit,
          loading: _busy,
          leadingIcon: _editing ? DSIconName.check : DSIconName.add,
          child: Text(_editing ? 'Save changes' : 'Create lesson'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: DSText.caption.copyWith(color: DSColors.error)),
        ],
      ],
    );
  }
}

/// One selectable subject card inside the lesson sheet — pastel-blue with a
/// 3px blue border when selected (mirrors the web subject cards).
class _SubjectCard extends StatelessWidget {
  final String subject;
  final bool selected;
  final VoidCallback onTap;
  const _SubjectCard(
      {required this.subject, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, _) = _subjectTile(subject);
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        child: SizedBox(
          height: 88,
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? DSColors.pastelBlue : DSColors.surface,
              borderRadius: DSRadii.inputBr,
              border: Border.all(
                  color: selected ? DSColors.blue : DSColors.line,
                  width: 3),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DSIcon(icon, size: 22, color: DSColors.ink),
                  const SizedBox(height: 6),
                  Text(subject,
                      style: DSText.label.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
        ),
      ),
    );
  }
}

/// Dashed "+ Subject" card — same slot size as [_SubjectCard], broken
/// border via DSDashedBox. Opens the add/manage subjects modal.
class _AddSubjectCard extends StatelessWidget {
  const _AddSubjectCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDSModal<void>(context,
          title: 'Add subject', body: const _SubjectsModal()),
      child: Semantics(
        button: true,
        label: 'Add subject',
        child: SizedBox(
          height: 88,
          child: DSDashedBox(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: DSColors.surface,
                borderRadius: DSRadii.inputBr,
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DSIcon(DSIconName.add,
                        size: 22, color: DSColors.blue),
                    const SizedBox(height: 6),
                    Text('Subject',
                        style: DSText.label
                            .copyWith(fontSize: 12, color: DSColors.blue),
                        textAlign: TextAlign.center),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Body of the "Add subject" modal — name field on top, every subject as a
/// uniform card with a centered × (tap asks to confirm), and a Save button
/// at the bottom that adds the typed name.
class _SubjectsModal extends StatefulWidget {
  const _SubjectsModal();

  @override
  State<_SubjectsModal> createState() => _SubjectsModalState();
}

class _SubjectsModalState extends State<_SubjectsModal> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: subjectsN,
      builder: (_, subs, __) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DSTextField(label: 'Subject name', controller: _name),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in subs)
              SizedBox(
                  width: 96, height: 88, child: _DelSubjectCard(subject: s)),
          ]),
          const SizedBox(height: 14),
          DSButton(
            leadingIcon: DSIconName.check,
            onPressed: () async {
              final n = _name.text.trim();
              if (n.isEmpty) {
                Navigator.of(context).pop();
                return;
              }
              if (!subs.contains(n)) {
                final ok = await saveSubjects([...subs, n]);
                if (!context.mounted) return;
                DSToast.show(context,
                    message: ok
                        ? 'Subject added'
                        : 'Saved on this device — couldn’t sync',
                    tone: ok ? DSToastTone.success : DSToastTone.error);
              }
              _name.clear();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Subject card with a centered × — tap asks to confirm, then removes the
/// subject. Lives inside the "Add subject" modal; fixed size so the cards
/// line up uniformly regardless of label length.
class _DelSubjectCard extends StatelessWidget {
  final String subject;
  const _DelSubjectCard({required this.subject});

  Future<void> _confirmRemove(BuildContext context) async {
    final ok = await showDSModal<bool>(
      context,
      title: 'Remove this subject?',
      body: Text('“$subject” will be removed from the subject picker. '
          'Lessons already tagged with it keep their subject.'),
      actions: [
        DSButton(
            variant: DSButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        DSButton(
            variant: DSButtonVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove')),
      ],
    );
    if (ok == true && context.mounted) {
      final synced = await saveSubjects(
          subjectsN.value.where((e) => e != subject).toList());
      if (!context.mounted) return;
      DSToast.show(context,
          message: synced
              ? 'Subject removed'
              : 'Removed on this device — couldn’t sync',
          tone: synced ? DSToastTone.success : DSToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, _) = _subjectTile(subject);
    return GestureDetector(
      onTap: () => _confirmRemove(context),
      child: Semantics(
        button: true,
        label: 'Remove $subject',
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: DSRadii.inputBr,
              border: Border.all(color: DSColors.line, width: 3),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DSIcon(icon, size: 22, color: DSColors.ink),
                  const SizedBox(height: 6),
                  Text(subject,
                      style: DSText.label.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: DSColors.errorSurface,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: DSIcon(DSIconName.close,
                  size: 14, color: DSColors.error),
            ),
          ),
        ]),
      ),
    );
  }
}

/// File pick rows in the sheet are the DS DSFilePicker component
/// (dashed 2px edge-white border via CustomPainter).
