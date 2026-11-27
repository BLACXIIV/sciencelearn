import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import 'class_portal_header.dart';
import 'release_settings_sheet.dart';

/// One lesson's activities — mockup layout: hero header, back + lesson
/// title row, "Activities n" section header with a teal "+ New activity"
/// button, then action-row cards (Questions / Preview / publish switch).
/// "..." keeps Rename, Release settings and the attempt-guarded Delete.
class LessonActivitiesScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final Json? lesson;
  const LessonActivitiesScreen(
      {super.key, required this.lessonId, this.lesson});
  @override
  ConsumerState<LessonActivitiesScreen> createState() => _ActivitiesState();
}

class _ActivitiesState extends ConsumerState<LessonActivitiesScreen> {
  /// "N questions" from the questions(count) embed on lessonAssessments.
  static int _qCount(Json a) {
    final l = a['questions'] as List?;
    return ((l == null || l.isEmpty ? 0 : l.first['count']) as num? ?? 0)
        .toInt();
  }

  
  Repo get _repo => ref.read(repoProvider);

  /// "+ New activity" — title + description sheet; a created activity goes
  /// straight into the builder (its empty state guides the next step).
  Future<void> _newActivitySheet() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    String? err;
    bool saving = false;
    final id = await showDSBottomSheet<String>(
      context,
      child: StatefulBuilder(builder: (ctx, setS) {
        Future<void> create() async {
          if (title.text.trim().isEmpty) {
            setS(() => err = 'Enter a title.');
            return;
          }
          setS(() {
            saving = true;
            err = null;
          });
          try {
            final a = await _repo.createAssessment(
                widget.lessonId, 'topic_quiz',
                title.text.trim(), desc.text.trim());
            if (ctx.mounted) Navigator.of(ctx).pop('${a['id']}');
          } catch (e) {
            setS(() {
              saving = false;
              err = '$e';
            });
          }
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('New activity', style: DSText.title),
            const SizedBox(height: 10),
            DSTextField(
                clean: true,
                label: 'Title',
                hint: 'e.g. ELABORATE — Reaction Detective',
                controller: title,
                onChanged: (_) => setS(() {})),
            const SizedBox(height: 10),
            DSTextField(
                clean: true,
                label: 'Description',
                hint: 'optional',
                controller: desc),
            const SizedBox(height: 12),
            DSButton(
                loading: saving,
                disabled: saving || title.text.trim().isEmpty,
                onPressed: create,
                child: const Text('Create activity')),
            const SizedBox(height: 8),
            DSButton(
              variant: DSButtonVariant.outline,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            if (err != null) ...[
              const SizedBox(height: 8),
              Text(err!, style: DSText.caption.copyWith(color: DSColors.error)),
            ],
          ]),
        );
      }),
    );
    title.dispose();
    desc.dispose();
    if (id != null && mounted) {
      await context.push('/teacher/quiz/builder/$id');
    }
    setState(() {});
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDSModal<bool>(
      context,
      title: title,
      body: Text(body, style: DSText.body),
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
    return ok == true;
  }

  /// Delete is guarded client-side too — the 0032 trigger blocks when
  /// attempts exist; pre-checking keeps the error friendly.
  Future<void> _deleteActivity(Json a) async {
    int attempts = 0;
    try {
      attempts = await _repo.assessmentAttemptCount('${a['id']}');
    } catch (_) {}
    if (!mounted) return;
    if (attempts > 0) {
      await showDSModal<void>(
        context,
        title: "Can't delete this",
        body: Text(
          'Students already took this — unpublish it instead of deleting.',
          style: DSText.body,
        ),
        actions: [
          DSButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }
    if (await _confirm('Delete activity?',
        'This removes "${a['title']}" and all its questions.')) {
      try {
        await _repo.deleteAssessment('${a['id']}');
      } catch (e) {
        if (mounted) {
          final m = '$e';
          DSToast.show(context,
              message: m.contains('Unpublish it instead')
                  ? 'Students already took this — unpublish it instead.'
                  : m,
              tone: DSToastTone.error);
        }
      }
      setState(() {});
    }
  }

  /// Title + description rename sheet (the "..." menu's Rename).
  Future<void> _renameActivity(Json a) async {
    final title = TextEditingController(text: '${a['title']}');
    final desc = TextEditingController(text: '${a['description'] ?? ''}');
    String? err;
    bool saving = false;
    final saved = await showDSBottomSheet<bool>(
      context,
      child: StatefulBuilder(builder: (ctx, setS) {
        Future<void> save() async {
          if (title.text.trim().isEmpty) {
            setS(() => err = 'Enter a title.');
            return;
          }
          setS(() {
            saving = true;
            err = null;
          });
          try {
            await _repo.renameAssessment('${a['id']}',
                title.text.trim(), desc.text.trim());
            if (ctx.mounted) Navigator.of(ctx).pop(true);
          } catch (e) {
            setS(() {
              saving = false;
              err = '$e';
            });
          }
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DSTextField(clean: true, label: 'Title', controller: title),
            const SizedBox(height: 10),
            DSTextField(
                clean: true,
                label: 'Description',
                hint: 'optional',
                controller: desc),
            const SizedBox(height: 12),
            DSButton(
                fullWidth: true,
                loading: saving,
                disabled: saving,
                onPressed: save,
                child: const Text('Save')),
            const SizedBox(height: 8),
            DSButton(
              fullWidth: true,
              variant: DSButtonVariant.outline,
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            if (err != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                  width: double.infinity,
                  child: Text(err!,
                      style:
                          DSText.caption.copyWith(color: DSColors.error))),
            ],
          ]),
        );
      }),
    );
    title.dispose();
    desc.dispose();
    if (saved == true) setState(() {});
  }

  /// "..." sheet on an activity card — Rename / Release settings / Delete.
  Future<void> _activityMenu(Json a) async {
    await showDSBottomSheet<void>(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _menuItem(
              icon: DSIconName.edit,
              label: 'Rename',
              onTap: () {
                Navigator.of(context).pop();
                _renameActivity(a);
              }),
          _menuItem(
              icon: DSIconName.award,
              label: 'Release settings',
              onTap: () async {
                Navigator.of(context).pop();
                await showReleaseSettingsSheet(context, _repo, a);
                setState(() {});
              }),
          _menuItem(
              icon: DSIconName.delete,
              label: 'Delete',
              danger: true,
              onTap: () {
                Navigator.of(context).pop();
                _deleteActivity(a);
              }),
        ]),
      ),
    );
  }

  Widget _menuItem(
      {required DSIconName icon,
      required String label,
      bool danger = false,
      VoidCallback? onTap}) {
    final color = danger ? DSColors.error : DSColors.navy;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          DSIcon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label, style: DSText.title.copyWith(color: color))),
        ]),
      ),
    );
  }

  /// Publish switch on the card — teal when on, disabled at 0 questions
  /// (the 0032 guard's friendly client-side twin).
  Future<void> _togglePublished(Json a, bool v) async {
    try {
      await _repo.setAssessmentPublished('${a['id']}', v);
    } catch (e) {
      if (mounted) {
        final m = '$e';
        DSToast.show(context,
            message: m.contains('Add questions')
                ? 'Add questions to publish'
                : m,
            tone: DSToastTone.error);
      }
    }
    setState(() {});
  }

  /// Pastel chip (mockup): Lexend 800 13 navy on pastel, padding 6 12,
  /// radius 99 — optional leading icon.
  Widget _chip(Color bg, String label, double maxW,
      {DSIconName? icon}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: DSRadii.pillBr),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child:
              Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              DSIcon(icon, size: 14, color: DSColors.navy),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: DSText.label
                    .copyWith(fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }

  /// Publish toggle (mockup): shared DSCompactSwitch — 44x26 pill, teal
  /// published / off-track draft, 20px white knob, no Material halo.
  Widget _pubSwitch(bool published, bool disabled, Json a) {
    return DSCompactSwitch(
      value: published,
      disabled: disabled,
      semanticsLabel: published ? 'Published' : 'Draft',
      onChanged: (v) => _togglePublished(a, v),
    );
  }

  /// Activity card per the mockup: title + "...", description, chips
  /// ("N questions", release mode, publish hint), footer divider, then the
  /// action row — Questions filled, Preview outline, publish switch right.
  Widget _activityCard(Json a) {
    final n = _qCount(a);
    final released = a['scores_released'] == true;
    final manual = '${a['release_scores'] ?? 'immediate'}' == 'manual';
    final published = a['is_published'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: DSRadii.cardBr,
          boxShadow: dsEdge(DSColors.edgeSoft, h: 6),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('${a['title']}',
                                style: DSText.title.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.25),
                                maxLines: 2,
                                overflow: TextOverflow.clip),
                            if ('${a['description'] ?? ''}'.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 2),
                                child: Text('${a['description']}',
                                    style: DSText.caption.copyWith(
                                        color: DSColors.note)),
                              ),
                          ]),
                    ),
                    Semantics(
                      button: true,
                      label: 'Activity actions',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _activityMenu(a),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: DSIcon(DSIconName.more,
                                size: 22, color: DSColors.note),
                          ),
                        ),
                      ),
                    ),
                  ]),
              const SizedBox(height: 10),
              LayoutBuilder(builder: (_, c) {
                final w = c.maxWidth;
                return Wrap(spacing: 6, runSpacing: 6, children: [
                  _chip(DSColors.track,
                      '$n ${n == 1 ? 'question' : 'questions'}', w),
                  if (!manual)
                    _chip(DSColors.pastelMint, 'Instant scores', w,
                        icon: DSIconName.check)
                  else
                    _chip(
                        DSColors.pastelYellow,
                        released
                            ? 'Scores released'
                            : 'Manual release',
                        w),
                  if (n == 0)
                    _chip(DSColors.pastelYellow,
                        'Add questions to publish', w),
                ]);
              }),
              const SizedBox(height: 10),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: DSColors.divider, width: 2)),
                ),
                padding: const EdgeInsets.only(top: 10),
                child: Row(children: [
                  // The whole group — Questions, Preview, publish switch —
                  // shrinks as a unit on narrow phones.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                await context.push(
                                    '/teacher/quiz/builder/${a['id']}');
                                setState(() {});
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10),
                                decoration: BoxDecoration(
                                  color: DSColors.blue,
                                  borderRadius: DSRadii.inputBr,
                                  boxShadow: dsEdge(
                                      DSColors.edgeBlue, h: 4),
                                ),
                                child: Text('Questions',
                                    style: DSText.label.copyWith(
                                        fontWeight:
                                            FontWeight.w800,
                                        color: DSColors.surface)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.push(
                                  '/teacher/quiz/preview/${a['id']}'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9),
                                decoration: BoxDecoration(
                                  color: DSColors.surface,
                                  borderRadius: DSRadii.inputBr,
                                  border: Border.all(
                                      color: DSColors.pastelBlue,
                                      width: 2),
                                ),
                                child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      const DSIcon(
                                          DSIconName.show,
                                          size: 16,
                                          color: DSColors.navy),
                                      const SizedBox(width: 6),
                                      Text('Preview',
                                          style: DSText.bodySm
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight
                                                          .w600)),
                                    ]),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _pubSwitch(published, n == 0, a),
                            const SizedBox(width: 8),
                            Text(
                                published
                                    ? 'Published'
                                    : 'Draft',
                                style: DSText.bodySm.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: DSColors.note)),
                          ]),
                    ),
                  ),
                ]),
              ),
            ]),
      ),
    );
  }

  /// Navy header — this screen only (per mockup): "Activities" title + the
  /// school/account hero tiles, then a second row with the back tile and the
  /// lesson name in soft on-navy text (up to 2 lines, never ellipsized).
  Widget _header() {
    final lessonTitle = widget.lesson != null
        ? Text('${widget.lesson!['title']}',
            style: DSText.bodySm
                .copyWith(color: DSColors.onNavy, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.clip)
        : KeepDataFutureBuilder<Json>(
            future: _repo.lesson(widget.lessonId),
            builder: (_, s) => Text('${s.data?['title'] ?? ''}',
                style: DSText.bodySm
                    .copyWith(color: DSColors.onNavy, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.clip));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DSColors.navyDeep, DSColors.navy],
          ),
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(DSRadii.sheet)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.paddingOf(context).top + 20, 20, 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text('Activities',
                        style: DSText.h1.copyWith(
                            fontSize: 28, color: DSColors.surface)),
                  ),
                  HeroTile(
                    icon: DSIconName.school,
                    label: 'Switch class',
                    onTap: () {
                      currentClass.value = null;
                      classPicked.value = false;
                      context.go('/select-class');
                    },
                  ),
                  const SizedBox(width: 10),
                  HeroTile(
                    icon: DSIconName.account,
                    label: 'Account',
                    onTap: () => context.push('/teacher/account'),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  HeroTile(
                    icon: DSIconName.chevronBack,
                    label: 'Back',
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: lessonTitle),
                ]),
              ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        _header(),
        Expanded(
            child: MaxWidth(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
              KeepDataFutureBuilder<List<Json>>(
                future: _repo.lessonAssessments(widget.lessonId),
                builder: (context, snap) {
                  final rows = snap.data ?? const <Json>[];
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          // scaleDown keeps the group on one line on
                          // narrow phones instead of overflowing.
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Activities',
                                        style: DSText.h3.copyWith(
                                            fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6),
                                      decoration: BoxDecoration(
                                        color: DSColors.pastelBlue,
                                        borderRadius:
                                            DSRadii.pillBr,
                                      ),
                                      child: Text('${rows.length}',
                                          style: DSText.label
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight
                                                          .w800)),
                                    ),
                                  ]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _newActivitySheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 11),
                              decoration: BoxDecoration(
                                color: DSColors.mint,
                                borderRadius: DSRadii.inputBr,
                                boxShadow:
                                    dsEdge(DSColors.edgeMint, h: 4),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const DSIcon(DSIconName.add,
                                        size: 18, color: DSColors.navy),
                                    const SizedBox(width: 6),
                                    Text('New activity',
                                        style: DSText.label.copyWith(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w800)),
                                  ]),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        if (snap.hasError)
                          Text('${snap.error}',
                              style: DSText.caption
                                  .copyWith(color: DSColors.error))
                        else if (!snap.hasData)
                          const Padding(
                              padding: EdgeInsets.all(24),
                              child:
                                  Center(child: DSLoadingIndicator()))
                        else if (rows.isEmpty)
                          const DSDashedBox(
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 20),
                                child: DSEmptyState(
                                  icon: DSIconName.quiz,
                                  title: 'No activities yet',
                                  body:
                                      'Tap "New activity" to build the first one.',
                                ),
                              ),
                            ),
                          )
                        else
                          ...[for (final a in rows) _activityCard(a)],
                      ]);
                },
              ),
            ]))),
      ]),
    );
  }
}
