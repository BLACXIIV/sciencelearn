import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';
import '../../core/text_clean.dart';
import 'class_portal_header.dart';
import 'release_settings_sheet.dart';

/// Quiz modes offered when creating a part. Modes missing from
/// [_modeToQtype] aren't supported by the runner yet and show "(soon)".
const _modes = {
  'multiple_choice': 'Multiple Choice',
  'true_false': 'True or False',
  'fill_blank': 'Fill in the Blank',
  'identification': 'Identification',
  'enumeration': 'Enumeration',
  'multi_select': 'Multi-Select',
  'classification': 'Classification',
  'matching': 'Matching',
  'ordering': 'Ordering',
  'table_fill': 'Table Fill-in',
  'hotspot': 'Spot the Item',
  'scenario': 'Scenario / Decision',
};

/// Activity mode -> question type used as the editor default.
const _modeToQtype = {
  'multiple_choice': 'multiple_choice',
  'multi_select': 'multi_select',
  'true_false': 'true_false',
  'fill_blank': 'fill_blank',
  'identification': 'identification',
  'enumeration': 'enumeration',
  'classification': 'classification',
  'matching': 'classification',
  'ordering': 'ordering',
};

/// Question type -> student/editor label, mirrors web QTYPES.
const _qtypeLabel = {
  'multiple_choice': 'Multiple Choice',
  'multi_select': 'Multi-Select',
  'true_false': 'True or False',
  'fill_blank': 'Fill in the Blank',
  'identification': 'Identification',
  'enumeration': 'Enumeration',
  'classification': 'Classification',
  'ordering': 'Ordering',
};

/// One-line summary of a question's answer key (row hint, mirrors web).
String _answerHint(Json q) {
  switch ('${q['qtype']}') {
    case 'multiple_choice':
    case 'fill_blank':
      final chs = q['choices'] as List? ?? const [];
      final ci = q['correct_index'] as int? ?? -1;
      return ci >= 0 && ci < chs.length ? 'Answer: ${chs[ci]}' : 'No key set';
    case 'true_false':
      return 'Answer: ${q['answer']?['correct'] == true ? 'True' : 'False'}';
    case 'identification':
      final acc = q['answer']?['accepted'] as List? ?? const [];
      return acc.isNotEmpty
          ? 'Answer: ${acc[0]}${acc.length > 1 ? ' +${acc.length - 1}' : ''}'
          : 'No key set';
    case 'multi_select':
      return '${(q['answer']?['indexes'] as List? ?? const []).length} correct';
    case 'enumeration':
      return '${(q['answer']?['items'] as List? ?? const []).length} items';
    case 'classification':
      return '${(q['answer']?['buckets'] as List? ?? const []).length} zones';
    case 'ordering':
      return '${(q['choices'] as List? ?? const []).length} steps';
    default:
      return '';
  }
}

/// "Activity n — title" option label for the part picker.
String _partOptionLabel(Json p, int index) {
  final t = '${p['title']}';
  return 'Activity ${index + 1}${t.isEmpty ? '' : ' — $t'}';
}

/// One row inside a bottom-sheet action menu.
Widget _sheetAction(
  BuildContext ctx, {
  required DSIconName icon,
  required String label,
  bool danger = false,
  VoidCallback? onTap,
}) {
  final color = danger ? DSColors.error : DSColors.navy;
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        DSIcon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: DSText.title.copyWith(color: color)),
        ),
      ]),
    ),
  );
}

/// The activity builder — navy header (title+desc pencil, counts, release
/// chip, teal publish switch), part chips, the selected part's card, a
/// long-press reorderable question list, and a sticky bottom bar
/// (Preview outline + "+ Add question" primary).
class ActivityBuilderScreen extends ConsumerStatefulWidget {
  final String assessmentId;
  const ActivityBuilderScreen({super.key, required this.assessmentId});
  @override
  ConsumerState<ActivityBuilderScreen> createState() => _BuilderState();
}

class _BuilderState extends ConsumerState<ActivityBuilderScreen> {
    String? _selPart;
  /// Last loaded snapshot — kept on screen during refetches so CRUD
  /// updates don't flash the loading spinner (it only shows on first load).
  List<Object>? _lastData;

  Repo get _repo => ref.read(repoProvider);
  void _reload() => setState(() {});

  /// Dense position rewrite after a reorder — scoped to one part (or the
  /// ungrouped set when [partId] is null).
  Future<void> _persistOrder(List<Json> scope) async {
    await _repo.reorderQuestionPositions(
        [for (final q in scope) '${q['id']}']);
    _reload();
  }

  Future<bool> _confirm(String title, String body,
      {String okLabel = 'Delete'}) async {
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
          child: Text(okLabel),
        ),
      ],
    );
    return ok == true;
  }

  /// Rename sheet — title + description (per the mockup's pencil affordance).
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
            await _repo.renameAssessment(widget.assessmentId,
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
            DSTextField(
                clean: true, label: 'Title', controller: title),
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
    if (saved == true) _reload();
  }

  /// Release chip — opens the shared release-settings sheet (req 9).
  Future<void> _releaseSheet(Json a) async {
    await showReleaseSettingsSheet(context, _repo, a);
    _reload();
  }

  /// Part editor sheet: title + directions + mode + scored + points.
  /// [position] is where a new part lands; ignored when editing.
  Future<void> _editPart(String assessmentId, int position, [Json? p]) async {
    final title = TextEditingController(text: '${p?['title'] ?? ''}');
    final dirs = TextEditingController(text: '${p?['directions'] ?? ''}');
    final pts = TextEditingController(text: '${p?['points'] ?? 1}');
    String mode = '${p?['mode'] ?? 'multiple_choice'}';
    bool scored = p?['scored'] != false;

    String? err;
    bool saving = false;
    final saved = await showDSBottomSheet<bool>(
      context,
      child: StatefulBuilder(builder: (ctx, setS) {
        Future<void> save() async {
          if (title.text.trim().isEmpty) {
            setS(() => err = 'Enter a part title.');
            return;
          }
          setS(() {
            saving = true;
            err = null;
          });
          try {
            await _repo.upsertPart({
              if (p != null) 'id': p['id'],
              'assessment_id': assessmentId,
              'title': title.text.trim(),
              'directions': dirs.text.trim(),
              'mode': mode,
              'scored': scored,
              'points': () {
                final v = double.tryParse(pts.text.trim()) ?? 1;
                return v < 0 ? 0 : v;
              }(),
              'position': p?['position'] ?? position,
            });
            // Keep positions dense after an insert — heals any gaps left
            // by older writes so a future insert can never tie.
            final now = await _repo.parts(assessmentId);
            await _repo.reorderPartPositions(
                [for (final x in now) '${x['id']}']);
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
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            DSTextField(
                clean: true,
                label: 'Part title',
                hint: 'e.g. Activity 1 — Reaction Detective',
                controller: title),
            const SizedBox(height: 10),
            DSTextArea(
                clean: true,
                label: 'Directions',
                hint:
                    'e.g. Read each situation carefully and select the correct answer.',
                controller: dirs,
                minLines: 2),
            const SizedBox(height: 10),
            DSSelect(
              label: 'Quiz mode',
              value: mode,
              options: [
                for (final e in _modes.entries)
                  DSSelectOption(
                      e.key,
                      _modeToQtype.containsKey(e.key)
                          ? e.value
                          : '${e.value} (soon)')
              ],
              onChanged: (v) => setS(() => mode = v ?? mode),
            ),
            if (!_modeToQtype.containsKey(mode))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '"${_modes[mode] ?? mode}" isn\'t supported by the runner yet — items in this part default to Multiple Choice for now.',
                  style: DSText.caption.copyWith(color: DSColors.muted),
                ),
              ),
            const SizedBox(height: 8),
            DSCheckbox(
              label:
                  'Scored — items in this part count toward the activity score',
              value: scored,
              onChanged: (v) => setS(() => scored = v),
            ),
            if (scored) ...[
              const SizedBox(height: 10),
              DSTextField(
                label: 'Points per item',
                controller: pts,
                helper: 'Each item in this part is worth this many points.',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 12),
            DSButton(
              fullWidth: true,
              loading: saving,
              disabled: saving,
              onPressed: save,
              child: const Text('Save part'),
            ),
            const SizedBox(height: 8),
            DSButton(
              fullWidth: true,
              variant: DSButtonVariant.outline,
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            if (err != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                  width: double.infinity,
                  child: Text(err!,
                      style: DSText.caption.copyWith(color: DSColors.error))),
            ],
          ])),
        );
      }),
    );
    if (saved == true) _reload();
  }

  /// Per-type question editor sheet. Writes choices/correct_index or answer
  /// jsonb. [partId] is the part the item is filed under (selectable in the
  /// sheet when [parts] is non-empty); [qs] locates move-to-part positions.
  /// [preset] pins the starting qtype (the "+ Add question" type chips).
  Future<void> _editQuestion(
      String assessmentId, List<Json> parts, String? partId, String partMode,
      List<Json> qs,
      [Json? q, int position = 0, String? preset]) async {
    String qtype =
        preset ?? '${q?['qtype'] ?? _modeToQtype[partMode] ?? 'multiple_choice'}';
    String? selPart = q?['part_id'] as String? ?? partId;
    // Mode of the currently selected part — drives the "not supported" note.
    String curMode() {
      for (final p in parts) {
        if ('${p['id']}' == selPart) return '${p['mode']}';
      }
      return partMode;
    }

    final prompt = TextEditingController(text: '${q?['prompt'] ?? ''}');
    // Legacy fill_blank (accepted-answer key) seeds its accepted items as
    // options so editing converts instead of losing them.
    final choiceSeed = <dynamic>[
      ...(q?['choices'] as List? ??
          (q?['qtype'] == 'fill_blank'
              ? (q?['answer']?['accepted'] as List? ?? const [])
              : const [])),
    ];
    // New questions (and choice-less types) start with four blank rows; an
    // existing choice list is shown as stored, mirroring the web editor.
    if (q?['choices'] == null) {
      while (choiceSeed.length < 4) {
        choiceSeed.add('');
      }
    }
    final choices = [
      for (final c in choiceSeed) TextEditingController(text: '$c')
    ];
    int correct = (q?['correct_index'] as num?)?.toInt() ?? 0;
    var sel = <int>{
      for (final i in (q?['answer']?['indexes'] as List? ?? const []))
        (i as num).toInt()
    };
    final minCtrl = TextEditingController(text: '${q?['answer']?['min'] ?? 1}');
    final maxCtrl = TextEditingController(
        text:
            '${q?['answer']?['max'] ?? (q == null ? 2 : (sel.isEmpty ? 1 : sel.length))}');
    bool boolAnswer = q == null ? true : q['answer']?['correct'] == true;
    final accepted = [
      for (final a in (q?['answer']?['accepted'] as List? ?? ['']))
        TextEditingController(text: '$a')
    ];
    final items = [
      for (final i in (q?['answer']?['items'] as List? ?? ['', '', '']))
        TextEditingController(text: '$i')
    ];
    bool ordered = q?['answer']?['ordered'] == true;
    bool partial = q?['answer']?['partial'] != false;
    // classification: the two bucket names + items (from `choices`) with each
    // item's correct bucket index (zones parallel to clsItems).
    final buckets = [
      for (final b in (q?['answer']?['buckets'] as List? ?? ['', '']))
        TextEditingController(text: '$b')
    ];
    while (buckets.length < 2) {
      buckets.add(TextEditingController());
    }
    final clsItems = [
      for (final i in (q?['qtype'] == 'classification'
          ? (q?['choices'] as List? ?? const ['', '', ''])
          : const ['', '', '']))
        TextEditingController(text: '$i')
    ];
    while (clsItems.length < 3) {
      clsItems.add(TextEditingController());
    }
    final zonesRaw = q?['answer']?['zones'] as List? ?? const [];
    final zones = List<int>.generate(clsItems.length,
        (i) => i < zonesRaw.length ? (zonesRaw[i] as num? ?? 0).toInt() : 0);
    final clsContext =
        TextEditingController(text: '${q?['answer']?['context'] ?? ''}');
    // ordering: items entered in CORRECT order — choices are stored
    // scrambled, answer.correct maps each position back to a choice.
    final ordKey = q?['qtype'] == 'ordering' &&
            q?['answer']?['correct'] is List &&
            (q?['answer']?['correct'] as List).isNotEmpty
        ? (q?['answer']?['correct'] as List)
        : const [];
    final ordSrc = q?['choices'] as List? ?? const ['', '', ''];
    final ordItems = [
      for (var p = 0;
          p < (ordKey.isNotEmpty ? ordKey.length : ordSrc.length);
          p++)
        TextEditingController(
            text: ordKey.isNotEmpty
                ? '${(ordKey[p] as num).toInt() < ordSrc.length ? ordSrc[(ordKey[p] as num).toInt()] : ''}'
                : '$ordSrc[p]')
    ];
    while (ordItems.length < 3) {
      ordItems.add(TextEditingController());
    }
    bool ordShuffle = q?['answer']?['shuffle'] != false;

    String? err;
    bool saving = false;
    // "Question N" — position inside its part for edits, next slot for new.
    final partQs = [for (final x in qs) if (x['part_id'] == selPart) x];
    final qIdx = partQs.indexWhere((x) => x['id'] == q?['id']);
    final qNum = q == null ? partQs.length + 1 : (qIdx >= 0 ? qIdx + 1 : 1);
    final saved = await showDSBottomSheet<bool>(
      context,
      child: StatefulBuilder(builder: (ctx, setS) {
        /// Answer-key pill for True/False — navy fill when picked.
        Widget tfPill(String label, bool v) => GestureDetector(
              onTap: () => setS(() => boolAnswer = v),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: boolAnswer == v ? DSColors.navy : DSColors.track,
                  borderRadius: DSRadii.pillBr,
                ),
                child: Text(label,
                    style: DSText.label.copyWith(
                        color:
                            boolAnswer == v ? DSColors.surface : DSColors.navy)),
              ),
            );

        /// Move a list item to FINAL index [t]; [remapIdx] converts an index
        /// under the same move (correct / sel / zones bookkeeping).
        void relocate(List l, int f, int t) {
          final v = l.removeAt(f);
          l.insert(t, v);
        }

        int remapIdx(int i, int f, int t) => i == f
            ? t
            : (f < i && i <= t ? i - 1 : (t <= i && i < f ? i + 1 : i));

        /// Radio marker — tap marks the single correct choice (MC/fill).
        Widget radioMarker(int i) => Padding(
            padding: const EdgeInsets.only(top: 1),
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setS(() => correct = i),
                child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                        child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == correct
                                    ? DSColors.mint
                                    : DSColors.surface,
                                border: Border.all(
                                    color: i == correct
                                        ? DSColors.teal
                                        : DSColors.switchOff,
                                    width: 2)),
                            child: i == correct
                                ? const Center(
                                    child: DSIcon(DSIconName.check,
                                        size: 14, color: DSColors.navy))
                                : null)))));

        /// Square marker — tap toggles a correct answer (multi-select).
        Widget squareMarker(int i) {
          final on = sel.contains(i);
          return Padding(
              padding: const EdgeInsets.only(top: 1),
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setS(() {
                        on ? sel.remove(i) : sel.add(i);
                      }),
                  child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                          child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  color:
                                      on ? DSColors.mint : DSColors.surface,
                                  borderRadius: DSRadii.br(8),
                                  border: Border.all(
                                      color: on
                                          ? DSColors.teal
                                          : DSColors.switchOff,
                                      width: 2)),
                              child: on
                                  ? const Center(
                                      child: DSIcon(DSIconName.check,
                                          size: 14, color: DSColors.navy))
                                  : null)))));
        }

        /// Shared answer-row chrome: [grip][marker][auto-grow field + remove
        /// "x" inside its trailing edge]. Reorder = long-press drag on the
        /// grip (ReorderableDelayedDragStartListener); Semantics "Move
        /// up/down" keeps reordering accessible. The field wraps instead of
        /// clipping (minLines 1 / maxLines null). [belowFor] renders under the
        /// field — used for the classification zone picker.
        Widget ansRows(List<TextEditingController> ctrls,
                {required String keyPrefix,
                required String hintBase,
                required bool letters,
                required int minItems,
                required void Function(int f, int t) applyMove,
                required void Function(int i) onRemove,
                Widget Function(int i)? markerFor,
                bool Function(int i)? isCorrect,
                Widget Function(int i)? belowFor,
                void Function(int i)? onChanged}) =>
            ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                // Lift + grow the dragged row so the hold reads as a
                // real "picked up" card instead of a silent jump.
                proxyDecorator: (child, index, animation) =>
                    AnimatedBuilder(
                        animation: animation,
                        builder: (ctx, child) {
                          final t = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic)
                              .value;
                          return Transform.scale(
                              scale: 1 + 0.03 * t,
                              child: Material(
                                  color: DSColors.surface,
                                  borderRadius: DSRadii.br(14),
                                  elevation: 12 * t,
                                  shadowColor: DSColors.navy
                                      .withValues(alpha: 0.35),
                                  child: child));
                        },
                        child: child),
                onReorderItem: (f, t) => setS(() => applyMove(f, t)),
                children: [
                  for (var i = 0; i < ctrls.length; i++)
                    Padding(
                        key: ValueKey(ctrls[i]),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Semantics(
                            customSemanticsActions: {
                              if (i > 0)
                                const CustomSemanticsAction(
                                        label: 'Move up'):
                                    () => setS(() => applyMove(i, i - 1)),
                              if (i < ctrls.length - 1)
                                const CustomSemanticsAction(
                                        label: 'Move down'):
                                    () => setS(() => applyMove(i, i + 1)),
                            },
                            child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  ReorderableDragStartListener(
                                      index: i,
                                      child: const Padding(
                                          padding:
                                              EdgeInsets.only(top: 12),
                                          child: DSIcon(DSIconName.grip,
                                              size: 20,
                                              color: DSColors.navDim))),
                                  markerFor?.call(i) ??
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              top: 10),
                                          child: SizedBox(
                                              width: 44,
                                              child: Center(
                                                  child: SizedBox(
                                                      width: 26,
                                                      child: Center(
                                                          child: Text(
                                                              '${i + 1}',
                                                              style: DSText
                                                                  .label
                                                                  .copyWith(
                                                                      color:
                                                                          DSColors.note))))))),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Container(
                                            key: ValueKey(
                                                '$keyPrefix-$i'),
                                            decoration: BoxDecoration(
                                                color: DSColors.surface,
                                                borderRadius:
                                                    DSRadii.inputBr,
                                                border: Border.all(
                                                    color: (isCorrect
                                                                ?.call(i) ??
                                                            false)
                                                        ? DSColors.teal
                                                        : DSColors.edgeSoft,
                                                    width: 2)),
                                            padding: const EdgeInsets
                                                .fromLTRB(14, 11, 8, 11),
                                            child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Expanded(
                                                      child: TextField(
                                                          controller:
                                                              ctrls[i],
                                                          minLines: 1,
                                                          maxLines: null,
                                                          style: DSText
                                                              .bodySm
                                                              .copyWith(
                                                                  color:
                                                                      DSColors
                                                                          .navy,
                                                                  height:
                                                                      1.4),
                                                          decoration:
                                                              InputDecoration(
                                                                  isCollapsed:
                                                                      true,
                                                                  border: InputBorder
                                                                      .none,
                                                                  enabledBorder:
                                                                      InputBorder
                                                                          .none,
                                                                  focusedBorder:
                                                                      InputBorder
                                                                          .none,
                                                                  disabledBorder:
                                                                      InputBorder
                                                                          .none,
                                                                  errorBorder:
                                                                      InputBorder
                                                                          .none,
                                                                  filled:
                                                                      false,
                                                                  hintText: letters
                                                                      ? '$hintBase ${String.fromCharCode(65 + i)}'
                                                                      : '$hintBase ${i + 1}',
                                                                  hintStyle: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: DSColors
                                                                          .hint)),
                                                          onChanged: onChanged ==
                                                                  null
                                                              ? null
                                                              : (_) => setS(
                                                                  () => onChanged(
                                                                      i)),
                                                          inputFormatters: const [
                                                            CleanTextFormatter()
                                                          ])),
                                                  SizedBox(
                                                      width: 44,
                                                      height: 20,
                                                      child: OverflowBox(
                                                          maxWidth: 44,
                                                          maxHeight: 44,
                                                          child:
                                                              GestureDetector(
                                                                  behavior:
                                                                      HitTestBehavior
                                                                          .opaque,
                                                                  onTap: ctrls.length <=
                                                                          minItems
                                                                      ? null
                                                                      : () => setS(() =>
                                                                          onRemove(
                                                                              i)),
                                                                  child: SizedBox(
                                                                      width: 44,
                                                                      height: 44,
                                                                      child: Center(
                                                                          child: DSIcon(
                                                                              DSIconName.close,
                                                                              size: 18,
                                                                              color: ctrls.length <= minItems ? DSColors.line : DSColors.navDim)))))),
                                                ])),
                                        if (belowFor != null) ...[
                                          const SizedBox(height: 6),
                                          belowFor(i),
                                        ],
                                      ])),
                                ]))),
                ]);

        /// Compact zone dropdown for classification items — styled like the
        /// answer field (2px edge, r14).
        Widget zonePicker(int i) => Container(
            height: 40,
            decoration: BoxDecoration(
                color: DSColors.surface,
                border: Border.all(color: DSColors.edgeSoft, width: 2),
                borderRadius: DSRadii.inputBr),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                    value: zones[i],
                    isExpanded: true,
                    isDense: true,
                    icon: const DSIcon(DSIconName.chevronDown,
                        size: 16, color: DSColors.navDim),
                    style: DSText.bodySm.copyWith(color: DSColors.navy),
                    dropdownColor: DSColors.surface,
                    items: [
                      for (var b = 0; b < buckets.length; b++)
                        DropdownMenuItem(
                            value: b,
                            child: Text(
                                buckets[b].text.trim().isEmpty
                                    ? 'Zone ${b + 1}'
                                    : buckets[b].text.trim(),
                                overflow: TextOverflow.ellipsis))
                    ],
                    onChanged: (v) => setS(() => zones[i] = v ?? 0))));

        /// Section header — left-aligned label (Inter 600 13 navy) with an
        /// optional note-color helper line underneath.
        Widget secHead(String label, [String? helper]) => Align(
            alignment: Alignment.centerLeft,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: DSText.label
                          .copyWith(fontSize: 13, color: DSColors.navy)),
                  if (helper != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(helper,
                            style: DSText.caption
                                .copyWith(color: DSColors.note))),
                ]));

        /// "+ Add …" text link — aligns under the fields per mockup.
        Widget addLink(String label, VoidCallback onTap) => Padding(
            padding: const EdgeInsets.only(left: 34, top: 2),
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setS(onTap),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('+ $label',
                        style: DSText.bodySm.copyWith(
                            color: DSColors.blue,
                            fontWeight: FontWeight.w600)))));

        /// Insert the [blank] gap marker at the caret (end if unfocused).
        void insertBlank() {
          final t = prompt.text;
          final at = prompt.selection.isValid
              ? prompt.selection.baseOffset.clamp(0, t.length)
              : t.length;
          prompt.value = TextEditingValue(
            text: '${t.substring(0, at)}[blank]${t.substring(at)}',
            selection: TextSelection.collapsed(offset: at + 7),
          );
        }

        /// First blocking validation error, mirroring web draftValid().
        String? qValid() {
          if (prompt.text.trim().isEmpty) {
            return 'Enter the question prompt.';
          }
          final filled = choices.where((c) => c.text.trim().isNotEmpty).length;
          switch (qtype) {
            case 'multiple_choice':
              if (filled < 2) return 'Add at least two choices.';
              if (correct >= choices.length ||
                  choices[correct].text.trim().isEmpty) {
                return 'Pick which choice is correct.';
              }
              return null;
            case 'multi_select':
              if (filled < 2) return 'Add at least two choices.';
              if (!sel.any((i) =>
                  i < choices.length && choices[i].text.trim().isNotEmpty)) {
                return 'Tick at least one correct choice.';
              }
              final mn = int.tryParse(minCtrl.text.trim()) ?? -1;
              final mx = int.tryParse(maxCtrl.text.trim()) ?? -1;
              if (mn < 0 || mn > mx) {
                return 'Required selections: min must be 0 or more and no more than max.';
              }
              if (mx < 1 || mx > filled) {
                return 'Max selections must be between 1 and $filled.';
              }
              return null;
            case 'fill_blank':
              if (!prompt.text.contains('[blank]')) {
                return 'Insert [blank] where the gap is.';
              }
              if (filled < 2) return 'Add at least two options.';
              if (correct >= choices.length ||
                  choices[correct].text.trim().isEmpty) {
                return 'Pick which option is correct.';
              }
              return null;
            case 'identification':
              return accepted.any((a) => a.text.trim().isNotEmpty)
                  ? null
                  : 'Add at least one accepted answer.';
            case 'enumeration':
              return items.where((i) => i.text.trim().isNotEmpty).length >= 2
                  ? null
                  : 'Add at least two expected items.';
            case 'classification':
              if (buckets.length < 2 ||
                  buckets.any((b) => b.text.trim().isEmpty)) {
                return 'Name every zone (at least two).';
              }
              if (clsItems.where((i) => i.text.trim().isNotEmpty).length < 2) {
                return 'Add at least two items.';
              }
              return null;
            case 'ordering':
              return ordItems.where((i) => i.text.trim().isNotEmpty).length >= 2
                  ? null
                  : 'Add at least two items to order.';
            default:
              return null;
          }
        }

        /// Validate -> upsert -> close on success, mirroring the web form
        /// staying open with the error shown under it on failure.
        Future<void> save() async {
          final v = qValid();
          if (v != null) {
            setS(() => err = v);
            return;
          }
          setS(() {
            saving = true;
            err = null;
          });
          final filled = choices
              .map((c) => c.text.trim())
              .where((c) => c.isNotEmpty)
              .toList();
          // ordering: scramble the stored order so public choices leak
          // nothing; correct[p] = index of the choice at correct position p.
          final ordTexts = [
            for (final c in ordItems)
              if (c.text.trim().isNotEmpty) c.text.trim()
          ];
          final perm = List<int>.generate(ordTexts.length, (i) => i)..shuffle();
          final ordChoices = [for (final k in perm) ordTexts[k]];
          final ordCorrect = [
            for (var p = 0; p < ordTexts.length; p++) perm.indexOf(p)
          ];
          // Move-to-part: a changed part lands at the end of its target list.
          final samePart = selPart == (q?['part_id'] as String? ?? partId);
          final movePos = samePart
              ? (q?['position'] ?? position)
              : qs.where((x) => x['part_id'] == selPart).length;
          try {
            await _repo.upsertQuestion({
              if (q != null) 'id': q['id'],
              'assessment_id': assessmentId,
              'part_id': selPart,
              'qtype': qtype,
              'prompt': prompt.text.trim(),
              'position': movePos,
              'choices': qtype == 'ordering'
                  ? ordChoices
                  : qtype == 'classification'
                      ? clsItems
                          .map((c) => c.text.trim())
                          .where((c) => c.isNotEmpty)
                          .toList()
                      : (qtype == 'multiple_choice' ||
                              qtype == 'multi_select' ||
                              qtype == 'fill_blank')
                          ? filled
                          : null,
              'correct_index':
                  qtype == 'multiple_choice' || qtype == 'fill_blank'
                      ? choices
                          .take(correct)
                          .where((c) => c.text.trim().isNotEmpty)
                          .length
                      : null,
              'answer': qtype == 'true_false'
                  ? {'correct': boolAnswer}
                  : qtype == 'identification'
                      ? {
                          'accepted': accepted
                              .map((a) => a.text.trim())
                              .where((a) => a.isNotEmpty)
                              .toList()
                        }
                      : qtype == 'enumeration'
                          ? {
                              'items': items
                                  .map((i) => i.text.trim())
                                  .where((i) => i.isNotEmpty)
                                  .toList(),
                              'ordered': ordered,
                              'partial': partial
                            }
                          : qtype == 'multi_select'
                              ? {
                                  'indexes': () {
                                    final l = <int>[
                                      for (final s in sel)
                                        if (choices[s].text.trim().isNotEmpty)
                                          choices
                                              .take(s)
                                              .where((c) =>
                                                  c.text.trim().isNotEmpty)
                                              .length
                                    ];
                                    l.sort();
                                    return l;
                                  }(),
                                  'min': int.tryParse(minCtrl.text.trim()) ?? 0,
                                  'max': int.tryParse(maxCtrl.text.trim()) ??
                                      filled.length,
                                  'partial': partial,
                                }
                              : qtype == 'classification'
                                  ? {
                                      'buckets': [
                                        for (final b in buckets) b.text.trim()
                                      ],
                                      'zones': [
                                        for (var i = 0;
                                            i < clsItems.length;
                                            i++)
                                          if (clsItems[i]
                                              .text
                                              .trim()
                                              .isNotEmpty)
                                            zones[i]
                                      ],
                                      if (clsContext.text.trim().isNotEmpty)
                                        'context': clsContext.text.trim(),
                                    }
                                  : qtype == 'ordering'
                                      ? {
                                          'correct': ordCorrect,
                                          'shuffle': ordShuffle
                                        }
                                      : null,
            });
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
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header — "Question N" + type chip + close. The part's mode
            // dictates the type; there is no type picker.
            Row(children: [
              Expanded(
                  child: Row(children: [
                Text('Question $qNum',
                    style: DSText.title
                        .copyWith(fontSize: 20, color: DSColors.navy)),
                const SizedBox(width: 8),
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: DSColors.pastelBlue,
                        borderRadius: DSRadii.pillBr),
                    child: Text(
                        (_qtypeLabel[qtype] ??
                                qtype.replaceAll('_', ' '))
                            .toUpperCase(),
                        style: DSText.label.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: DSColors.navy))),
              ])),
              DSIconButton(
                icon: DSIconName.close,
                label: 'Close',
                size: 36,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ]),
            const DSDivider(),
            if (q == null && !_modeToQtype.containsKey(curMode()))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '"${_modes[curMode()] ?? curMode().replaceAll('_', ' ')}" activities aren\'t supported by the runner yet — add questions with a supported type for now.',
                  style: DSText.caption.copyWith(color: DSColors.muted),
                ),
              ),
            const SizedBox(height: 10),
            DSTextArea(
                clean: true, label: 'Prompt', controller: prompt, minLines: 2),
            const SizedBox(height: 12),
            if (qtype == 'multiple_choice') ...[
              secHead('Choices',
                  'Tap the circle for the correct answer. Hold the dots to reorder.'),
              const SizedBox(height: 8),
              ansRows(choices,
                  keyPrefix: 'ans-choice',
                  hintBase: 'Choice',
                  letters: true,
                  minItems: 2,
                  markerFor: radioMarker,
                  isCorrect: (i) => i == correct,
                  applyMove: (f, t) {
                    relocate(choices, f, t);
                    correct = remapIdx(correct, f, t);
                  },
                  onRemove: (i) {
                    choices.removeAt(i);
                    if (correct == i) {
                      correct = 0;
                    } else if (correct > i) {
                      correct -= 1;
                    }
                  }),
              if (choices.length < 6)
                addLink('Add choice',
                    () => choices.add(TextEditingController())),
            ],
            if (qtype == 'fill_blank') ...[
              Align(
                alignment: Alignment.centerLeft,
                child: DSButton(
                  variant: DSButtonVariant.outline,
                  size: DSButtonSize.sm,
                  leadingIcon: DSIconName.add,
                  onPressed: insertBlank,
                  child: const Text('Insert [blank]'),
                ),
              ),
              const SizedBox(height: 12),
              secHead('Options',
                  'Tap the circle for the correct answer. Hold the dots to reorder.'),
              const SizedBox(height: 8),
              ansRows(choices,
                  keyPrefix: 'ans-choice',
                  hintBase: 'Choice',
                  letters: true,
                  minItems: 2,
                  markerFor: radioMarker,
                  isCorrect: (i) => i == correct,
                  applyMove: (f, t) {
                    relocate(choices, f, t);
                    correct = remapIdx(correct, f, t);
                  },
                  onRemove: (i) {
                    choices.removeAt(i);
                    if (correct == i) {
                      correct = 0;
                    } else if (correct > i) {
                      correct -= 1;
                    }
                  }),
              if (choices.length < 6)
                addLink('Add choice',
                    () => choices.add(TextEditingController())),
            ],
            if (qtype == 'multi_select') ...[
              secHead('Choices',
                  'Tap the squares for the correct answers. Hold the dots to reorder.'),
              const SizedBox(height: 8),
              ansRows(choices,
                  keyPrefix: 'ans-choice',
                  hintBase: 'Choice',
                  letters: true,
                  minItems: 2,
                  markerFor: squareMarker,
                  isCorrect: (i) => sel.contains(i),
                  applyMove: (f, t) {
                    relocate(choices, f, t);
                    sel = {for (final s in sel) remapIdx(s, f, t)};
                  },
                  onRemove: (i) {
                    choices.removeAt(i);
                    sel = {
                      for (final s in sel)
                        if (s != i) s > i ? s - 1 : s
                    };
                  }),
              if (choices.length < 8)
                addLink('Add choice',
                    () => choices.add(TextEditingController())),
              const SizedBox(height: 12),
              secHead('Required selections'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: DSTextField(
                  clean: true,
                  label: 'Min',
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: DSTextField(
                  clean: true,
                  label: 'Max',
                  controller: maxCtrl,
                  keyboardType: TextInputType.number,
                )),
              ]),
              DSCheckbox(
                label:
                    'Partial credit — correct picks minus wrong picks, otherwise all-or-nothing',
                value: partial,
                onChanged: (v) => setS(() => partial = v),
              ),
            ],
            if (qtype == 'true_false') ...[
              secHead('Answer key'),
              const SizedBox(height: 8),
              Row(children: [
                tfPill('True', true),
                const SizedBox(width: 10),
                tfPill('False', false),
              ]),
            ],
            if (qtype == 'identification') ...[
              secHead('Accepted answers',
                  'Matching ignores case and surrounding spaces. Hold the dots to reorder.'),
              const SizedBox(height: 8),
              ansRows(accepted,
                  keyPrefix: 'ans-accept',
                  hintBase: 'Answer',
                  letters: false,
                  minItems: 1,
                  applyMove: (f, t) => relocate(accepted, f, t),
                  onRemove: (i) => accepted.removeAt(i)),
              addLink('Add accepted answer',
                  () => accepted.add(TextEditingController())),
            ],
            if (qtype == 'enumeration') ...[
              secHead('Expected items', 'Hold the dots to reorder.'),
              const SizedBox(height: 8),
              ansRows(items,
                  keyPrefix: 'ans-item',
                  hintBase: 'Item',
                  letters: false,
                  minItems: 2,
                  applyMove: (f, t) => relocate(items, f, t),
                  onRemove: (i) => items.removeAt(i)),
              addLink('Add item',
                  () => items.add(TextEditingController())),
              DSCheckbox(
                label: 'Order matters — items must appear in this order',
                value: ordered,
                onChanged: (v) => setS(() => ordered = v),
              ),
              DSCheckbox(
                label:
                    'Partial credit — score each correct item, otherwise all-or-nothing',
                value: partial,
                onChanged: (v) => setS(() => partial = v),
              ),
            ],
            if (qtype == 'classification') ...[
              DSTextArea(
                clean: true,
                label: 'Context shown to students (optional)',
                controller: clsContext,
                minLines: 3,
              ),
              const SizedBox(height: 12),
              secHead('Zones', 'Hold the dots to reorder.'),
              const SizedBox(height: 8),
              ansRows(buckets,
                  keyPrefix: 'ans-zone',
                  hintBase: 'Zone',
                  letters: false,
                  minItems: 2,
                  applyMove: (f, t) {
                    relocate(buckets, f, t);
                    zones.setAll(
                        0, [for (final z in zones) remapIdx(z, f, t)]);
                  },
                  onRemove: (i) {
                    buckets.removeAt(i);
                    for (var zi = 0; zi < zones.length; zi++) {
                      if (zones[zi] == i) {
                        zones[zi] = 0;
                      } else if (zones[zi] > i) {
                        zones[zi] -= 1;
                      }
                    }
                  },
                  onChanged: (_) {}),
              if (buckets.length < 6)
                addLink('Add zone',
                    () => buckets.add(TextEditingController())),
              const SizedBox(height: 12),
              secHead('Items and their correct zone',
                  'Hold the dots to reorder.'),
              const SizedBox(height: 8),
              ansRows(clsItems,
                  keyPrefix: 'ans-clsitem',
                  hintBase: 'Item',
                  letters: false,
                  minItems: 2,
                  belowFor: zonePicker,
                  applyMove: (f, t) {
                    relocate(clsItems, f, t);
                    relocate(zones, f, t);
                  },
                  onRemove: (i) {
                    clsItems.removeAt(i);
                    zones.removeAt(i);
                  }),
              if (clsItems.length < 10)
                addLink('Add item', () {
                  clsItems.add(TextEditingController());
                  zones.add(0);
                }),
            ],
            if (qtype == 'ordering') ...[
              secHead('Items — enter in the CORRECT order',
                  'Hold the dots to reorder.'),
              const SizedBox(height: 8),
              ansRows(ordItems,
                  keyPrefix: 'ans-orditem',
                  hintBase: 'Item',
                  letters: false,
                  minItems: 2,
                  applyMove: (f, t) => relocate(ordItems, f, t),
                  onRemove: (i) => ordItems.removeAt(i)),
              if (ordItems.length < 10)
                addLink('Add item',
                    () => ordItems.add(TextEditingController())),
              DSCheckbox(
                label: 'Shuffle for students',
                value: ordShuffle,
                onChanged: (v) => setS(() => ordShuffle = v),
              ),
            ],
            const SizedBox(height: 12),
            if (parts.isNotEmpty)
              DSSelect(
                label: 'Move to part',
                value: selPart ?? '',
                options: [
                  for (var pi = 0; pi < parts.length; pi++)
                    DSSelectOption(
                        '${parts[pi]['id']}', _partOptionLabel(parts[pi], pi)),
                  const DSSelectOption('', 'Ungrouped'),
                ],
                onChanged: (v) => setS(() => selPart = v == '' ? null : v),
              ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: DSButton(
                variant: DSButtonVariant.outline,
                child: const FittedBox(
                    fit: BoxFit.scaleDown, child: Text('Cancel')),
                onPressed: () => Navigator.of(ctx).pop(false),
              )),
              const SizedBox(width: 10),
              Expanded(
                  flex: 2,
                  child: DSButton(
                    loading: saving,
                    disabled: saving,
                    onPressed: save,
                    child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Save question')),
                  )),
            ]),
            if (err != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                  width: double.infinity,
                  child: Text(err!,
                      style: DSText.caption.copyWith(color: DSColors.error))),
            ],
          ])),
        );
      }),
    );
    if (saved == true) _reload();
  }

  /// "..." sheet on a question row: Edit / Move up / Move down / Delete.
  Future<void> _questionMenu(
      Json q, List<Json> scope, int index, String? pid, String pmode,
      List<Json> parts, List<Json> qs) async {
    await showDSBottomSheet<void>(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetAction(context,
              icon: DSIconName.edit,
              label: 'Edit',
              onTap: () {
                Navigator.of(context).pop();
                _editQuestion(widget.assessmentId, parts, pid, pmode, qs, q);
              }),
          _sheetAction(context,
              icon: DSIconName.up,
              label: 'Move up',
              onTap: index == 0
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      final next = [...scope];
                      final t = next.removeAt(index);
                      next.insert(index - 1, t);
                      _persistOrder(next);
                    }),
          _sheetAction(context,
              icon: DSIconName.down,
              label: 'Move down',
              onTap: index == scope.length - 1
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      final next = [...scope];
                      final t = next.removeAt(index);
                      next.insert(index + 1, t);
                      _persistOrder(next);
                    }),
          _sheetAction(context,
              icon: DSIconName.delete,
              label: 'Delete',
              danger: true,
              onTap: () async {
                Navigator.of(context).pop();
                final p = '${q['prompt']}';
                if (await _confirm('Delete question?',
                    '"${p.length > 80 ? p.substring(0, 80) : p}"')) {
                  try {
                    await _repo.deleteQuestion('${q['id']}');
                  } catch (e) {
                    if (mounted) {
                      DSToast.show(context,
                          message: '$e', tone: DSToastTone.error);
                    }
                  }
                  _reload();
                }
              }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    return Scaffold(
      body: Column(children: [
        KeepDataFutureBuilder<List<Object>>(
          future: Future.wait([
            _repo.assessment(widget.assessmentId),
            repo.parts(widget.assessmentId),
            repo.questionsFull(widget.assessmentId),
          ]),
          builder: (context, snap) {
            if (snap.hasError) {
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${snap.error}',
                        style:
                            DSText.caption.copyWith(color: DSColors.error)),
                  ),
                ),
              );
            }
            // Stale data stays on screen while a refetch runs — the
            // spinner only shows when nothing has loaded yet.
            if (snap.hasData) _lastData = snap.data;
            final data = snap.data ?? _lastData;
            if (data == null) {
              return const Expanded(
                  child: Center(child: DSLoadingIndicator()));
            }
            final a = data[0] as Json;
            final parts = data[1] as List<Json>;
            final qs = sortQuestionsByPart(
                data[2] as List<Json>, parts);
            // Default the selection to the first part once parts load.
            if (_selPart == null && parts.isNotEmpty) {
              _selPart = '${parts[0]['id']}';
            }
            final selIndex =
                parts.indexWhere((p) => '${p['id']}' == _selPart);
            final part = selIndex >= 0 ? parts[selIndex] : null;
            final scope = _selPart == null
                ? [for (final q in qs) if (q['part_id'] == null) q]
                : [for (final q in qs) if ('${q['part_id']}' == _selPart) q];
            final ungrouped =
                [for (final q in qs) if (q['part_id'] == null) q];
            final pmode =
                part == null ? 'multiple_choice' : '${part['mode']}';
            // Bottom bar lives inside this subtree so "+ Add question"
            // always opens the sheet with fresh parts/questions — as a
            // Scaffold bottomNavigationBar it would capture the empty
            // pre-load snapshot.
            final bottom = _BottomData(parts, qs, pmode, scope.length);

            return Expanded(
              child: Column(children: [
                Expanded(
                  child: Column(children: [
                    _buildHeader(a, parts, qs),
                  Expanded(
                    child: MaxWidth(
                      child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Always rendered — with zero parts the chips list
                        // is empty and only "+ Add part" shows, which is the
                        // only entry point for creating the first part.
                        const SizedBox(height: 14),
                        _partChips(parts),
                        if (part != null) _partCard(part, selIndex, parts, qs),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 18, 20, 10),
                          child: Row(children: [
                            Text('Questions',
                                style: DSText.h3.copyWith(fontSize: 18)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: DSColors.pastelBlue,
                                borderRadius: DSRadii.pillBr,
                              ),
                              child: Text('${scope.length}',
                                  style: DSText.label.copyWith(
                                      fontWeight: FontWeight.w800)),
                            ),
                            Flexible(
                              child: Text('Hold and drag',
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  style: DSText.caption
                                      .copyWith(color: DSColors.note)),
                            ),
                          ]),
                        ),
                        _questionList(scope, parts, qs, pmode),
                        if (ungrouped.isNotEmpty && _selPart != null) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            child: Text(
                              'Ungrouped questions — pick a Part inside each item to file it.',
                              style: DSText.caption
                                  .copyWith(color: DSColors.muted),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _questionList(
                              ungrouped, parts, qs, 'multiple_choice',
                              ungroupedScope: true),
                        ],
                        const SizedBox(height: 80), // clears the bottom bar
                      ],
                    ),
                  ),
                ),
              ]),
                  ),
                _bottomBar(bottom),
              ]),
            );
          },
        ),
      ]),
    );
  }

  /// Splits "EVALUATE - ASSESSING YOUR LEARNING" on the first ' - ' or
  /// en dash → (Title-Case part, uppercase subtitle). No separator → the
  /// whole title stays.
  (String, String?) _splitTitle(String raw) {
    for (final sep in [' - ', ' – ']) {
      final i = raw.indexOf(sep);
      if (i > 0) {
        final head = raw.substring(0, i).trim();
        final titleCase = head.isEmpty
            ? head
            : head[0].toUpperCase() +
                head.substring(1).toLowerCase();
        return (titleCase, raw.substring(i + sep.length).trim());
      }
    }
    return (raw.trim(), null);
  }

  /// Navy header (mockup): gradient, r30 bottom, gap 14 —
  /// row1 title+inline pencil + hero tiles; row2 back tile + subtitle/
  /// counts + publish switch cluster; row3 tappable release chip.
  Widget _buildHeader(Json a, List<Json> parts, List<Json> qs) {
    final manual = '${a['release_scores'] ?? 'immediate'}' == 'manual';
    final published = a['is_published'] == true;
    final (title, subtitle) = _splitTitle('${a['title']}');
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
          borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(DSRadii.sheet)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.paddingOf(context).top + 20, 20, 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _renameActivity(a),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(title,
                                  style: DSText.h1.copyWith(
                                      fontSize:
                                          subtitle == null ? 24 : 28,
                                      color: DSColors.surface),
                                  maxLines: subtitle == null ? 2 : 1,
                                  overflow: TextOverflow.clip),
                            ),
                            const SizedBox(width: 8),
                            const DSIcon(DSIconName.edit,
                                size: 18, color: DSColors.edgeWhite),
                          ]),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subtitle != null)
                            Text(subtitle.toUpperCase(),
                                style: DSText.bodySm.copyWith(
                                    color: DSColors.onNavy,
                                    height: 1.3)),
                          Text(
                            '${parts.length} ${parts.length == 1 ? 'part' : 'parts'} · '
                            '${qs.length} ${qs.length == 1 ? 'question' : 'questions'}',
                            style: DSText.bodySm.copyWith(
                                color: DSColors.onNavy, height: 1.3),
                          ),
                        ]),
                  ),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        DSCompactSwitch(
                          value: published,
                          semanticsLabel:
                              published ? 'Published' : 'Draft',
                          disabled: qs.isEmpty,
                          onChanged: (v) async {
                            try {
                              await _repo.setAssessmentPublished(
                                  widget.assessmentId, v);
                            } catch (e) {
                              if (mounted) {
                                DSToast.show(context,
                                    message: '$e',
                                    tone: DSToastTone.error);
                              }
                            }
                            _reload();
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(published ? 'Published' : 'Draft',
                            style: DSText.label.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: DSColors.surface)),
                      ]),
                ]),
                const SizedBox(height: 14),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _releaseSheet(a),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DSColors.surface.withValues(alpha: 0.14),
                      borderRadius: DSRadii.pillBr,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            manual ? 'Manual release' : 'Instant scores',
                            style: DSText.label.copyWith(
                                fontWeight: FontWeight.w800,
                                color: DSColors.surface),
                          ),
                          const SizedBox(width: 4),
                          const DSIcon(DSIconName.chevronDown,
                              size: 14, color: DSColors.surface),
                        ]),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  /// Next insert slot for a new part — max(position)+1, not parts.length:
  /// deleting a part leaves gaps, and a length-based slot can tie with an
  /// existing position and sort first.
  int _nextPartPos(List<Json> parts) {
    var m = -1;
    for (final p in parts) {
      final pos = (p['position'] as num?)?.toInt() ?? 0;
      if (pos > m) m = pos;
    }
    return m + 1;
  }

  /// "Part N" chips + dashed "+ Add part" — horizontal scroll with
  /// 20px end padding so nothing clips.
  Widget _partChips(List<Json> parts) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (var pi = 0; pi < parts.length; pi++) _partChip(parts[pi], pi),
          GestureDetector(
            onTap: () => _editPart(widget.assessmentId, _nextPartPos(parts)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DSDashedBox(
                color: DSColors.pastelBlue,
                strokeWidth: 3,
                radius: DSRadii.pill,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Center(
                  child: Text('+ Add part',
                      style: DSText.bodySm
                          .copyWith(color: DSColors.blue)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One chip — always "Part N"; navy fill when selected, white +
  /// edgeSoft under-edge otherwise.
  Widget _partChip(Json p, int index) {
    final on = '${p['id']}' == _selPart;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selPart = '${p['id']}'),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: on ? DSColors.navy : DSColors.surface,
            borderRadius: DSRadii.pillBr,
            boxShadow:
                on ? null : dsEdge(DSColors.edgeSoft, h: 3),
          ),
          child: Text(
            'Part ${index + 1}',
            style: DSText.label.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: on ? DSColors.surface : DSColors.ink),
          ),
        ),
      ),
    );
  }

  /// Selected part card — inline edit form (title/points/mode/
  /// directions) + "Scored" switch + "..." menu with Delete part.
  Widget _partCard(Json p, int index, List<Json> parts, List<Json> qs) {
    final partQs = [
      for (final q in qs) if ('${q['part_id']}' == '${p['id']}') q
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: DSRadii.cardBr,
          boxShadow: dsEdge(DSColors.edgeSoft, h: 6),
        ),
        child: _PartForm(
          key: ValueKey('${p['id']}'),
          part: p,
          index: index,
          questionCount: partQs.length,
          onModeWillChange: (newMode) async {
            if (partQs.isEmpty) return true;
            // Mode drives the question type — incompatible items are
            // removed so nothing half-valid is left behind.
            final ok = await _confirm(
              'Change mode?',
              'Changing to "${_modes[newMode] ?? newMode}" removes the '
                  '${partQs.length} question${partQs.length == 1 ? '' : 's'} '
                  'already in this part.',
              okLabel: 'Change mode',
            );
            if (!ok) return false;
            try {
              for (final q in partQs) {
                await _repo.deleteQuestion('${q['id']}');
              }
              return true;
            } catch (e) {
              if (mounted) {
                DSToast.show(context,
                    message: '$e', tone: DSToastTone.error);
              }
              return false;
            }
          },
          onSave: (fields) async {
            try {
              await _repo.upsertPart({
                'id': p['id'],
                'assessment_id': widget.assessmentId,
                ...fields,
                'position': p['position'],
              });
              _reload();
            } catch (e) {
              if (mounted) {
                DSToast.show(context,
                    message: '$e', tone: DSToastTone.error);
              }
            }
          },
          onScoredChanged: (v) async {
            try {
              await _repo.upsertPart({'id': p['id'], 'scored': v});
              _reload();
            } catch (e) {
              if (mounted) {
                DSToast.show(context,
                    message: '$e', tone: DSToastTone.error);
              }
            }
          },
          onDelete: () async {
            final items =
                await _repo.questionsFull(widget.assessmentId);
            final n =
                items.where((q) => q['part_id'] == p['id']).length;
            if (!mounted) return;
            if (await _confirm('Delete part?',
                'This removes "${'${p['title']}'.isEmpty ? 'this part' : p['title']}" and its $n question(s).')) {
              try {
                await _repo.deletePart('${p['id']}');
                // Close the gap so positions stay dense — a later
                // insert can never tie.
                final now = await _repo.parts(widget.assessmentId);
                await _repo.reorderPartPositions(
                    [for (final x in now) '${x['id']}']);
                _selPart = null;
              } catch (e) {
                if (mounted) {
                  DSToast.show(context,
                      message: '$e', tone: DSToastTone.error);
                }
              }
              _reload();
            }
          },
        ),
      ),
    );
  }

  /// The selected scope's question rows — long-press drag reorders and
  /// persists dense positions.
  Widget _questionList(List<Json> scope, List<Json> parts, List<Json> qs,
      String pmode,
      {bool ungroupedScope = false}) {
    final pid = ungroupedScope ? null : _selPart;
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      buildDefaultDragHandles: false,
      // Lift + grow the dragged card so the hold reads as a real
      // "picked up" item instead of a silent jump.
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          builder: (ctx, child) {
            final t = CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)
                .value;
            return Transform.scale(
                scale: 1 + 0.03 * t,
                child: Material(
                    color: Colors.transparent,
                    borderRadius: DSRadii.tileBr,
                    elevation: 14 * t,
                    shadowColor:
                        DSColors.navy.withValues(alpha: 0.35),
                    child: child));
          },
          child: child),
      // onReorderItem's newIndex is already adjusted for the removal.
      onReorderItem: (oldIndex, newIndex) {
        final next = [...scope];
        final t = next.removeAt(oldIndex);
        next.insert(newIndex, t);
        _persistOrder(next);
      },
      children: [
        for (var i = 0; i < scope.length; i++)
          _questionRow(scope[i], i, scope, pid, pmode, parts, qs,
              key: ValueKey('${scope[i]['id']}')),
      ],
    );
  }

  /// One question row — white card, 3px track border, r18; grip (navDim)
  /// is the long-press drag handle; 28px number badge; uppercase type
  /// chip; bare "..." target (no tile).
  Widget _questionRow(Json q, int i, List<Json> scope, String? pid,
      String pmode, List<Json> parts, List<Json> qs,
      {required Key key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: DSRadii.tileBr,
          border: Border.all(color: DSColors.track, width: 3),
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ReorderableDragStartListener(
                index: i,
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                  child: DSIcon(DSIconName.grip,
                      size: 18, color: DSColors.navDim),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: DSColors.track,
                  shape: BoxShape.circle,
                ),
                child: Text('${i + 1}',
                    style: DSText.label.copyWith(
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: DSColors.pastelBlue,
                            borderRadius: DSRadii.pillBr,
                          ),
                          child: Text(
                            (_qtypeLabel['${q['qtype']}'] ??
                                    '${q['qtype']}'
                                        .replaceAll('_', ' '))
                                .toUpperCase(),
                            style: DSText.label.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: DSColors.navy),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('${q['prompt']}',
                          style: DSText.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: DSColors.ink,
                              height: 1.35),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                      if (_answerHint(q).isNotEmpty)
                        Text(_answerHint(q),
                            style: DSText.caption
                                .copyWith(color: DSColors.note),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ]),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    _questionMenu(q, scope, i, pid, pmode, parts, qs),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: DSIcon(DSIconName.more,
                        size: 20, color: DSColors.note),
                  ),
                ),
              ),
            ]),
      ),
    );
  }

  /// Latest fetched data for the bottom bar — set inside the builder.
  /// Sticky bottom bar — white, upward shadow; outline Preview +
  /// flex-1 blue "+ Add question" that never wraps.
  Widget _bottomBar(_BottomData d) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: DSColors.surface,
          boxShadow: dsBarLift(),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => context
                .push('/teacher/quiz/preview/${widget.assessmentId}'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: DSColors.surface,
                borderRadius: DSRadii.buttonBr,
                border: Border.all(color: DSColors.pastelBlue, width: 2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const DSIcon(DSIconName.show,
                    size: 18, color: DSColors.navy),
                const SizedBox(width: 6),
                Text('Preview',
                    style: DSText.bodySm.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: DSColors.navy)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Questions live inside parts — with none yet, nudge the
                // teacher to "+ Add part" instead of filing an ungrouped item.
                if (d.parts.isEmpty) {
                  DSToast.show(context,
                      message:
                          'Add a part first — questions live inside parts.',
                      tone: DSToastTone.info);
                  return;
                }
                _editQuestion(
                    widget.assessmentId, d.parts, _selPart, d.pmode,
                    d.questions, null, d.position, null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 14),
                decoration: BoxDecoration(
                  color: DSColors.blue,
                  borderRadius: DSRadii.buttonBr,
                  boxShadow: dsEdge(DSColors.edgeBlue, h: 4),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const DSIcon(DSIconName.add,
                            size: 18, color: DSColors.surface),
                        const SizedBox(width: 6),
                        Text('Add question',
                            style: DSText.label.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: DSColors.surface)),
                      ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The last-loaded data snapshot for the sticky bottom bar.
class _BottomData {
  final List<Json> parts;
  final List<Json> questions;
  final String pmode;
  final int position;
  const _BottomData(this.parts, this.questions, this.pmode, this.position);
}

/// Inline part form inside the part card — the mockup replaces the
/// summary + edit tiles with live fields. Text fields save on focus-out;
/// mode/scored save on change. [onSave] gets the upsertable field map
/// (the parent adds id/assessment_id/position).
class _PartForm extends StatefulWidget {
  final Json part;
  final int index;
  final Future<void> Function(Map<String, Object?> fields) onSave;
  final Future<void> Function(bool scored) onScoredChanged;
  final Future<void> Function() onDelete;

  /// Questions currently filed under this part — a mode change wipes
  /// them, so [onModeWillChange] must approve first.
  final int questionCount;
  final Future<bool> Function(String newMode) onModeWillChange;

  const _PartForm({
    super.key,
    required this.part,
    required this.index,
    required this.onSave,
    required this.onScoredChanged,
    required this.onDelete,
    required this.questionCount,
    required this.onModeWillChange,
  });

  @override
  State<_PartForm> createState() => _PartFormState();
}

class _PartFormState extends State<_PartForm> {
  late final TextEditingController _title =
      TextEditingController(text: '${widget.part['title'] ?? ''}');
  late final TextEditingController _pts =
      TextEditingController(text: '${widget.part['points'] ?? 1}');
  late final TextEditingController _dirs =
      TextEditingController(text: '${widget.part['directions'] ?? ''}');
  late String _mode = '${widget.part['mode'] ?? 'multiple_choice'}';
  late bool _scored = widget.part['scored'] != false;

  Map<String, Object?> _fields() => {
        'title': _title.text.trim(),
        'directions': _dirs.text.trim(),
        'mode': _mode,
        'scored': _scored,
        'points': () {
          final v = double.tryParse(_pts.text.trim()) ?? 1;
          return v < 0 ? 0 : v;
        }(),
      };

  /// Saves whatever the fields currently hold — called on focus-out.
  void _commit() => widget.onSave(_fields());

  @override
  void dispose() {
    _title.dispose();
    _pts.dispose();
    _dirs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text('Part ${widget.index + 1}',
              style: DSText.h3.copyWith(fontSize: 18)),
        ),
        Text('Scored',
            style: DSText.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: DSColors.navy)),
        const SizedBox(width: 6),
        DSCompactSwitch(
          value: _scored,
          semanticsLabel: 'Scored',
          onChanged: (v) {
            setState(() => _scored = v);
            widget.onScoredChanged(v);
          },
        ),
        Builder(builder: (btnCtx) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final overlay = Overlay.of(btnCtx)
                  .context
                  .findRenderObject() as RenderBox;
              final btn = btnCtx.findRenderObject() as RenderBox;
              final pos = RelativeRect.fromRect(
                btn.localToGlobal(Offset.zero, ancestor: overlay) &
                    btn.size,
                Offset.zero & overlay.size,
              );
              final pick = await showMenu<String>(
                context: btnCtx,
                position: pos,
                items: const [
                  PopupMenuItem(
                      value: 'delete', child: Text('Delete part')),
                ],
              );
              if (pick == 'delete') widget.onDelete();
            },
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                  child: DSIcon(DSIconName.more,
                      size: 22, color: DSColors.note)),
            ),
          );
        }),
      ]),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 2,
          child: _Field(
              label: 'Title',
              hint: 'e.g. Reaction Detective',
              controller: _title,
              onSaved: _commit),
        ),
        if (_scored) ...[
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: _Field(
              label: 'Points',
              hint: '1',
              controller: _pts,
              onSaved: _commit,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 12),
      _fieldLabel('Mode'),
      Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _fieldDeco,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _mode,
            isExpanded: true,
            isDense: true,
            icon: const DSIcon(DSIconName.chevronDown,
                size: 18, color: DSColors.navDim),
            style:
                DSText.bodySm.copyWith(color: DSColors.navy),
            items: [
              for (final e in _modes.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(_modeToQtype.containsKey(e.key)
                      ? e.value
                      : '${e.value} (soon)'),
                ),
            ],
            onChanged: (v) async {
              if (v == null || v == _mode) return;
              // A mode change wipes this part's questions — the parent's
              // confirm+delete gate decides whether it applies.
              if (widget.questionCount > 0 &&
                  !(await widget.onModeWillChange(v))) {
                return;
              }
              if (!mounted) return;
              setState(() => _mode = v);
              _commit();
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      _fieldLabel('Directions'),
      Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: _fieldDeco,
        child: Focus(
          onFocusChange: (has) {
            if (!has) _commit();
          },
          child: TextField(
            controller: _dirs,
            minLines: 2,
            maxLines: null,
            style: DSText.bodySm.copyWith(color: DSColors.navy),
            decoration: const InputDecoration(
              isCollapsed: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText:
                  'e.g. Read each situation carefully and select the correct answer.',
              hintStyle: TextStyle(
                  fontSize: 14, color: DSColors.hint),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _fieldLabel(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s,
            style: DSText.caption.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DSColors.ink)),
      );

  BoxDecoration get _fieldDeco => BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSRadii.inputBr,
        border: Border.all(color: DSColors.edgeSoft, width: 2),
      );
}

/// One labeled input row — label Inter 600 13 mb6, input h46 border 2px
/// edgeSoft r14 pad 12/14 Inter 14 navy, hint #6B7BB8. Saves on blur.
class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onSaved;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onSaved,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: DSText.caption.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DSColors.ink)),
      ),
      Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: DSRadii.inputBr,
          border: Border.all(color: DSColors.edgeSoft, width: 2),
        ),
        child: Focus(
          onFocusChange: (has) {
            if (!has) onSaved();
          },
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onEditingComplete: onSaved,
            style: DSText.bodySm.copyWith(color: DSColors.navy),
            decoration: InputDecoration(
              isCollapsed: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 14, color: DSColors.hint),
            ),
          ),
        ),
      ),
    ]);
  }
}
