import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Teacher activity builder for one lesson — mirrors web LessonActivities.
/// Manage assessments (quiz mode, publish, delete) and per-type questions.
class LessonActivitiesScreen extends ConsumerStatefulWidget {
  final Json lesson;
  const LessonActivitiesScreen({super.key, required this.lesson});
  @override
  ConsumerState<LessonActivitiesScreen> createState() => _ActivitiesState();
}

class _ActivitiesState extends ConsumerState<LessonActivitiesScreen> {
  /// Quiz modes offered when creating an activity. Modes missing from
  /// [_modeToQtype] aren't supported by the runner yet and show "(soon)".
  static const _modes = {
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
  static const _modeToQtype = {
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

  /// "N parts" caption from the assessment_parts(count) embed.
  static String _partCountLabel(Json a) {
    final l = a['assessment_parts'] as List?;
    final n = (l == null || l.isEmpty ? 0 : l.first['count']) as num? ?? 0;
    return '$n ${n == 1 ? 'part' : 'parts'}';
  }

  final _title = TextEditingController();
  final _desc = TextEditingController();
  String? _open; // expanded assessment id
  int _refresh = 0;
  bool _creating = false;
  String? _createErr;

  /// Question type -> student/editor label, mirrors web QTYPES.
  static const _qtypeLabel = {
    'multiple_choice': 'Multiple Choice',
    'multi_select': 'Multi-Select',
    'true_false': 'True or False',
    'fill_blank': 'Fill in the Blank',
    'identification': 'Identification',
    'enumeration': 'Enumeration',
    'classification': 'Classification',
    'ordering': 'Ordering',
  };

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _createAssessment() async {
    setState(() {
      _creating = true;
      _createErr = null;
    });
    try {
      final a = await ref.read(repoProvider).createAssessment(
          '${widget.lesson['id']}',
          'topic_quiz',
          _title.text.trim(),
          _desc.text.trim());
      _title.clear();
      _desc.clear();
      _open = '${a['id']}';
    } catch (e) {
      _createErr = '$e';
    }
    setState(() {
      _creating = false;
      _refresh++;
    });
  }

  /// Per-part editor sheet: title + directions + mode + scored flag.
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
            await ref.read(repoProvider).upsertPart({
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
    if (saved != true) return;
    setState(() => _refresh++);
  }

  /// Per-type question editor sheet. Writes choices/correct_index or answer jsonb.
  /// [partMode] presets qtype for new items; [partId] is the part the item is
  /// filed under (selectable in the sheet when [parts] is non-empty).
  Future<void> _editQuestion(
      String assessmentId, List<Json> parts, String? partId, String partMode,
      [Json? q, int position = 0]) async {
    String qtype =
        '${q?['qtype'] ?? _modeToQtype[partMode] ?? 'multiple_choice'}';
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
    final saved = await showDSBottomSheet<bool>(
      context,
      child: StatefulBuilder(builder: (ctx, setS) {
        /// Dynamic short-answer list (accepted answers / enumeration items).
        /// Remove stays visible but disabled at the [minItems] floor — same
        /// as the web ListInput.
        Widget listRows(List<TextEditingController> ctrls, String hint,
                {required int minItems, required String addLabel}) =>
            Column(children: [
              for (var i = 0; i < ctrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(
                        child: DSTextField(
                      clean: true,
                      label: '$hint ${i + 1}',
                      controller: ctrls[i],
                    )),
                    const SizedBox(width: 8),
                    DSIconButton(
                      icon: DSIconName.delete,
                      label: 'Remove',
                      size: 36,
                      disabled: ctrls.length <= minItems,
                      onPressed: () => setS(() => ctrls.removeAt(i)),
                    ),
                  ]),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: DSButton(
                  variant: DSButtonVariant.outline,
                  size: DSButtonSize.sm,
                  leadingIcon: DSIconName.add,
                  onPressed: () =>
                      setS(() => ctrls.add(TextEditingController())),
                  child: Text(addLabel),
                ),
              ),
            ]);

        /// Answer-key pill for True/False — navy fill when picked.
        Widget tfPill(String label, bool v) => GestureDetector(
              onTap: () => setS(() => boolAnswer = v),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: boolAnswer == v ? DSColors.navy : DSColors.track,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(label,
                    style: DSText.label.copyWith(
                        color: boolAnswer == v ? Colors.white : DSColors.navy)),
              ),
            );

        /// Radio dot for single-correct option lists (MC + fill_blank).
        Widget radioDot(int i) => GestureDetector(
              onTap: () => setS(() => correct = i),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: correct == i ? DSColors.blue : DSColors.line,
                      width: 2),
                ),
                child: correct == i
                    ? Center(
                        child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: DSColors.blue)))
                    : null,
              ),
            );

        /// Option row shared by MC / fill_blank: marker + field +
        /// move/delete buttons.
        Widget choiceRow(int i, Widget marker) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                marker,
                const SizedBox(width: 8),
                Expanded(
                    child: DSTextField(
                  clean: true,
                  label: 'Choice ${i + 1}',
                  controller: choices[i],
                )),
                const SizedBox(width: 8),
                DSIconButton(
                  icon: DSIconName.up,
                  label: 'Move up',
                  size: 36,
                  onPressed: i == 0
                      ? null
                      : () => setS(() {
                            final c = choices.removeAt(i);
                            choices.insert(i - 1, c);
                            if (correct == i) {
                              correct = i - 1;
                            } else if (correct == i - 1) {
                              correct = i;
                            }
                          }),
                ),
                const SizedBox(width: 8),
                DSIconButton(
                  icon: DSIconName.down,
                  label: 'Move down',
                  size: 36,
                  onPressed: i == choices.length - 1
                      ? null
                      : () => setS(() {
                            final c = choices.removeAt(i);
                            choices.insert(i + 1, c);
                            if (correct == i) {
                              correct = i + 1;
                            } else if (correct == i + 1) {
                              correct = i;
                            }
                          }),
                ),
                const SizedBox(width: 8),
                DSIconButton(
                  icon: DSIconName.delete,
                  label: 'Remove',
                  size: 36,
                  disabled: choices.length <= 2,
                  onPressed: () => setS(() {
                    choices.removeAt(i);
                    if (correct == i) {
                      correct = 0;
                    } else if (correct > i) {
                      correct -= 1;
                    }
                  }),
                ),
              ]),
            );

        /// Left-aligned "Add choice" outline pill — hidden at the cap,
        /// same as the web editor (6 for MC/fill-blank, 8 for multi-select).
        Widget addChoiceBtn(int cap) => choices.length >= cap
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.centerLeft,
                child: DSButton(
                  variant: DSButtonVariant.outline,
                  size: DSButtonSize.sm,
                  leadingIcon: DSIconName.add,
                  onPressed: () =>
                      setS(() => choices.add(TextEditingController())),
                  child: const Text('Add choice'),
                ),
              );

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
          try {
            await ref.read(repoProvider).upsertQuestion({
              if (q != null) 'id': q['id'],
              'assessment_id': assessmentId,
              'part_id': selPart,
              'qtype': qtype,
              'prompt': prompt.text.trim(),
              'position': q?['position'] ?? position,
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
            DSSelect(
              label: 'Question type',
              value: qtype,
              options: const [
                DSSelectOption('multiple_choice', 'Multiple Choice'),
                DSSelectOption('multi_select', 'Multi-Select'),
                DSSelectOption('true_false', 'True or False'),
                DSSelectOption('fill_blank', 'Fill in the Blank'),
                DSSelectOption('identification', 'Identification'),
                DSSelectOption('enumeration', 'Enumeration'),
                DSSelectOption('classification', 'Classification'),
                DSSelectOption('ordering', 'Ordering'),
              ],
              onChanged: (v) => setS(() => qtype = v ?? qtype),
            ),
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
              Text('Choices — select the correct one:',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              for (var i = 0; i < choices.length; i++)
                choiceRow(i, radioDot(i)),
              addChoiceBtn(6),
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
              Text('Options — select the correct one:',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              for (var i = 0; i < choices.length; i++)
                choiceRow(i, radioDot(i)),
              addChoiceBtn(6),
            ],
            if (qtype == 'multi_select') ...[
              Text('Choices — tick every correct one:',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              for (var i = 0; i < choices.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setS(() =>
                              sel.contains(i) ? sel.remove(i) : sel.add(i)),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: sel.contains(i)
                                  ? DSColors.blue
                                  : DSColors.track,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: sel.contains(i)
                                      ? DSColors.blue
                                      : DSColors.line,
                                  width: 2),
                            ),
                            child: sel.contains(i)
                                ? const Center(
                                    child: DSIcon(DSIconName.check,
                                        size: 14, color: Colors.white))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: DSTextField(
                          clean: true,
                          label: 'Choice ${i + 1}',
                          controller: choices[i],
                        )),
                        const SizedBox(width: 8),
                        DSIconButton(
                          icon: DSIconName.up,
                          label: 'Move up',
                          size: 36,
                          onPressed: i == 0
                              ? null
                              : () => setS(() {
                                    final c = choices.removeAt(i);
                                    choices.insert(i - 1, c);
                                    sel = {
                                      for (final s in sel)
                                        s == i
                                            ? i - 1
                                            : s == i - 1
                                                ? i
                                                : s
                                    };
                                  }),
                        ),
                        const SizedBox(width: 8),
                        DSIconButton(
                          icon: DSIconName.down,
                          label: 'Move down',
                          size: 36,
                          onPressed: i == choices.length - 1
                              ? null
                              : () => setS(() {
                                    final c = choices.removeAt(i);
                                    choices.insert(i + 1, c);
                                    sel = {
                                      for (final s in sel)
                                        s == i
                                            ? i + 1
                                            : s == i + 1
                                                ? i
                                                : s
                                    };
                                  }),
                        ),
                        const SizedBox(width: 8),
                        DSIconButton(
                          icon: DSIconName.delete,
                          label: 'Remove',
                          size: 36,
                          disabled: choices.length <= 2,
                          onPressed: () => setS(() {
                            choices.removeAt(i);
                            sel = {
                              for (final s in sel)
                                if (s != i) s > i ? s - 1 : s
                            };
                          }),
                        ),
                      ]),
                ),
              addChoiceBtn(8),
              const SizedBox(height: 12),
              Text('Required selections',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
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
              Text('Answer key',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              Row(children: [
                tfPill('True', true),
                const SizedBox(width: 10),
                tfPill('False', false),
              ]),
            ],
            if (qtype == 'identification') ...[
              Text(
                  'Accepted answers — matching ignores case and surrounding spaces:',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              listRows(accepted, 'Answer',
                  minItems: 1, addLabel: 'Add accepted answer'),
            ],
            if (qtype == 'enumeration') ...[
              Text('Expected items:',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              listRows(items, 'Item', minItems: 2, addLabel: 'Add item'),
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
              Text('Zones',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              for (var bi = 0; bi < buckets.length; bi++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(
                        child: DSTextField(
                      clean: true,
                      label: 'Zone ${bi + 1}',
                      controller: buckets[bi],
                      onChanged: (_) => setS(() {}),
                    )),
                    const SizedBox(width: 8),
                    DSIconButton(
                      icon: DSIconName.delete,
                      label: 'Remove zone',
                      size: 36,
                      disabled: buckets.length <= 2,
                      onPressed: () => setS(() {
                        buckets.removeAt(bi);
                        for (var zi = 0; zi < zones.length; zi++) {
                          if (zones[zi] == bi) {
                            zones[zi] = 0;
                          } else if (zones[zi] > bi) {
                            zones[zi] -= 1;
                          }
                        }
                      }),
                    ),
                  ]),
                ),
              if (buckets.length < 6)
                Align(
                  alignment: Alignment.centerLeft,
                  child: DSButton(
                    variant: DSButtonVariant.outline,
                    size: DSButtonSize.sm,
                    leadingIcon: DSIconName.add,
                    onPressed: () =>
                        setS(() => buckets.add(TextEditingController())),
                    child: const Text('Add zone'),
                  ),
                ),
              const SizedBox(height: 12),
              Text('Items and their correct zone',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              for (var i = 0; i < clsItems.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: DSTextField(
                        clean: true,
                        label: 'Item ${i + 1}',
                        controller: clsItems[i],
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                          child: DSSelect(
                        label: 'Zone',
                        value: '${zones[i]}',
                        options: [
                          for (var bi = 0; bi < buckets.length; bi++)
                            DSSelectOption(
                                '$bi',
                                buckets[bi].text.trim().isEmpty
                                    ? 'Zone ${bi + 1}'
                                    : buckets[bi].text.trim()),
                        ],
                        onChanged: (v) =>
                            setS(() => zones[i] = int.tryParse('$v') ?? 0),
                      )),
                    ]),
                    Row(children: [
                      const Spacer(),
                      DSIconButton(
                        icon: DSIconName.up,
                        label: 'Move up',
                        size: 36,
                        onPressed: i == 0
                            ? null
                            : () => setS(() {
                                  final c = clsItems.removeAt(i);
                                  clsItems.insert(i - 1, c);
                                  zones.insert(i - 1, zones.removeAt(i));
                                }),
                      ),
                      const SizedBox(width: 8),
                      DSIconButton(
                        icon: DSIconName.down,
                        label: 'Move down',
                        size: 36,
                        onPressed: i == clsItems.length - 1
                            ? null
                            : () => setS(() {
                                  final c = clsItems.removeAt(i);
                                  clsItems.insert(i + 1, c);
                                  zones.insert(i + 1, zones.removeAt(i));
                                }),
                      ),
                      const SizedBox(width: 8),
                      DSIconButton(
                        icon: DSIconName.delete,
                        label: 'Remove',
                        size: 36,
                        disabled: clsItems.length <= 2,
                        onPressed: () => setS(() {
                          clsItems.removeAt(i);
                          zones.removeAt(i);
                        }),
                      ),
                    ]),
                  ]),
                ),
              if (clsItems.length < 10)
                Align(
                  alignment: Alignment.centerLeft,
                  child: DSButton(
                    variant: DSButtonVariant.outline,
                    size: DSButtonSize.sm,
                    leadingIcon: DSIconName.add,
                    onPressed: () => setS(() {
                      clsItems.add(TextEditingController());
                      zones.add(0);
                    }),
                    child: const Text('Add item'),
                  ),
                ),
            ],
            if (qtype == 'ordering') ...[
              Text('Items — enter in the CORRECT order:',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              for (var i = 0; i < ordItems.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    SizedBox(
                        width: 18,
                        child: Center(
                            child: Text('${i + 1}',
                                style: DSText.label
                                    .copyWith(color: DSColors.muted)))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: DSTextField(
                      clean: true,
                      label: 'Item ${i + 1}',
                      controller: ordItems[i],
                    )),
                    const SizedBox(width: 8),
                    DSIconButton(
                      icon: DSIconName.up,
                      label: 'Move up',
                      size: 36,
                      onPressed: i == 0
                          ? null
                          : () => setS(() {
                                final c = ordItems.removeAt(i);
                                ordItems.insert(i - 1, c);
                              }),
                    ),
                    const SizedBox(width: 8),
                    DSIconButton(
                      icon: DSIconName.down,
                      label: 'Move down',
                      size: 36,
                      onPressed: i == ordItems.length - 1
                          ? null
                          : () => setS(() {
                                final c = ordItems.removeAt(i);
                                ordItems.insert(i + 1, c);
                              }),
                    ),
                    const SizedBox(width: 8),
                    DSIconButton(
                      icon: DSIconName.delete,
                      label: 'Remove',
                      size: 36,
                      disabled: ordItems.length <= 2,
                      onPressed: () => setS(() => ordItems.removeAt(i)),
                    ),
                  ]),
                ),
              if (ordItems.length < 10)
                Align(
                  alignment: Alignment.centerLeft,
                  child: DSButton(
                    variant: DSButtonVariant.outline,
                    size: DSButtonSize.sm,
                    leadingIcon: DSIconName.add,
                    onPressed: () =>
                        setS(() => ordItems.add(TextEditingController())),
                    child: const Text('Add item'),
                  ),
                ),
              DSCheckbox(
                label: 'Shuffle for students',
                value: ordShuffle,
                onChanged: (v) => setS(() => ordShuffle = v),
              ),
            ],
            const SizedBox(height: 12),
            DSButton(
              fullWidth: true,
              loading: saving,
              disabled: saving,
              onPressed: save,
              child: const Text('Save question'),
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
    if (saved != true) return;
    setState(() => _refresh++);
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

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repoProvider);
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
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Activities for "${widget.lesson['title']}"',
                      style: DSText.h2.copyWith(color: DSColors.surface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
        Expanded(
            child: MaxWidth(
                child: ListView(padding: const EdgeInsets.all(16), children: [
          DSCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text('New activity', style: DSText.title),
                const SizedBox(height: 10),
                DSTextField(
                    clean: true,
                    label: 'Title',
                    hint: 'e.g. ELABORATE — Reaction Detective',
                    controller: _title,
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 10),
                DSTextField(
                    clean: true,
                    label: 'Description',
                    hint: 'optional',
                    controller: _desc),
                const SizedBox(height: 12),
                DSButton(
                    loading: _creating,
                    disabled: _creating || _title.text.trim().isEmpty,
                    onPressed: _createAssessment,
                    child: const Text('Create activity')),
                if (_createErr != null) ...[
                  const SizedBox(height: 8),
                  Text(_createErr!,
                      style: DSText.caption.copyWith(color: DSColors.error)),
                ],
              ])),
          const SizedBox(height: 16),
          FutureBuilder<List<Json>>(
            key: ValueKey(_refresh),
            future: repo.lessonAssessments('${widget.lesson['id']}'),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text('${snap.error}',
                    style: DSText.caption.copyWith(color: DSColors.error));
              }
              if (!snap.hasData) {
                return const Center(child: DSLoadingIndicator());
              }
              final rows = snap.data!;
              if (rows.isEmpty) {
                return const DSCard(
                    child: DSEmptyState(
                        icon: DSIconName.assessment,
                        title: 'No activities yet',
                        body: 'Create one above, then add questions.'));
              }
              return Column(children: [
                for (final a in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DSCard(
                        child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('${a['title']}',
                                  style: DSText.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(_partCountLabel(a),
                                  style: DSText.caption
                                      .copyWith(color: DSColors.muted)),
                            ])),
                        const SizedBox(width: 8),
                        DSStatusBadge(
                            status: a['is_published'] == true
                                ? DSStatus.published
                                : DSStatus.draft),
                        const SizedBox(width: 8),
                        DSIconButton(
                          icon: DSIconName.delete,
                          label: 'Delete activity',
                          size: 36,
                          onPressed: () async {
                            if (await _confirm('Delete activity?',
                                'This removes the activity and its questions.')) {
                              try {
                                await repo.deleteAssessment('${a['id']}');
                              } catch (e) {
                                if (context.mounted) {
                                  DSToast.show(context,
                                      message: '$e', tone: DSToastTone.error);
                                }
                              }
                              setState(() => _refresh++);
                            }
                          },
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        DSButton(
                          variant: DSButtonVariant.outline,
                          size: DSButtonSize.sm,
                          onPressed: () => setState(() =>
                              _open = _open == a['id'] ? null : '${a['id']}'),
                          child: Text(_open == a['id'] ? 'Close' : 'Questions'),
                        ),
                        const SizedBox(width: 8),
                        DSButton(
                          variant: DSButtonVariant.outline,
                          size: DSButtonSize.sm,
                          onPressed: () async {
                            try {
                              await repo.setAssessmentPublished(
                                  '${a['id']}', a['is_published'] != true);
                            } catch (e) {
                              if (context.mounted) {
                                DSToast.show(context,
                                    message: '$e', tone: DSToastTone.error);
                              }
                            }
                            setState(() => _refresh++);
                          },
                          child: Text(a['is_published'] == true
                              ? 'Unpublish'
                              : 'Publish'),
                        ),
                      ]),
                      _ScoreRelease(
                        mode: '${a['release_scores'] ?? 'immediate'}',
                        released: a['scores_released'] == true,
                        repo: repo,
                        assessmentId: '${a['id']}',
                        onChanged: () => setState(() => _refresh++),
                      ),
                      if (_open == a['id'])
                        FutureBuilder<List<List<Json>>>(
                          key: ValueKey('${a['id']}-$_refresh'),
                          future: Future.wait([
                            repo.parts('${a['id']}'),
                            repo.questionsFull('${a['id']}'),
                          ]),
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text('${snap.error}',
                                      style: DSText.caption
                                          .copyWith(color: DSColors.error)));
                            }
                            if (!snap.hasData) {
                              return const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: DSLoadingIndicator());
                            }
                            final parts = snap.data![0];
                            final qs = snap.data![1];
                            List<Json> partItems(String pid) => [
                                  for (final qq in qs)
                                    if (qq['part_id'] == pid) qq
                                ];
                            final ungrouped = [
                              for (final qq in qs)
                                if (qq['part_id'] == null) qq
                            ];

                            Widget itemTile(
                                Json qq, int n, String? pid, String pmode) {
                              final p = '${qq['prompt']}';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: DSListItemCard(
                                  leading: Text('$n', style: DSText.label),
                                  title: Text(p,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      _qtypeLabel['${qq['qtype']}'] ??
                                          '${qq['qtype']}'
                                              .replaceAll('_', ' ')),
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DSIconButton(
                                          icon: DSIconName.edit,
                                          label: 'Edit',
                                          size: 36,
                                          onPressed: () => _editQuestion(
                                              '${a['id']}',
                                              parts,
                                              pid,
                                              pmode,
                                              qq),
                                        ),
                                        const SizedBox(width: 8),
                                        DSIconButton(
                                          icon: DSIconName.delete,
                                          label: 'Delete question',
                                          size: 36,
                                          onPressed: () async {
                                            if (await _confirm(
                                                'Delete question?',
                                                '"${p.length > 80 ? p.substring(0, 80) : p}"')) {
                                              try {
                                                await repo.deleteQuestion(
                                                    '${qq['id']}');
                                              } catch (e) {
                                                if (context.mounted) {
                                                  DSToast.show(context,
                                                      message: '$e',
                                                      tone: DSToastTone.error);
                                                }
                                              }
                                              setState(() => _refresh++);
                                            }
                                          },
                                        ),
                                      ]),
                                ),
                              );
                            }

                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const DSDivider(),
                                  for (var pi = 0; pi < parts.length; pi++)
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  Text(
                                                      'Activity ${pi + 1}${'${parts[pi]['title']}'.isEmpty ? '' : ' — ${parts[pi]['title']}'}',
                                                      style: DSText.label,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                  Text(
                                                      '${_modes[parts[pi]['mode']] ?? '${parts[pi]['mode']}'.replaceAll('_', ' ')}${parts[pi]['scored'] == false ? ' · not scored' : ' · ${fmtPts(parts[pi]['points'] as num? ?? 1)} pt${(parts[pi]['points'] as num? ?? 1) == 1 ? '' : 's'} each'}',
                                                      style: DSText.caption
                                                          .copyWith(
                                                              color: DSColors
                                                                  .muted)),
                                                ])),
                                            DSIconButton(
                                              icon: DSIconName.edit,
                                              label: 'Edit part',
                                              size: 36,
                                              onPressed: () => _editPart(
                                                  '${a['id']}', pi, parts[pi]),
                                            ),
                                            const SizedBox(width: 8),
                                            DSIconButton(
                                              icon: DSIconName.delete,
                                              label: 'Delete part',
                                              size: 36,
                                              onPressed: () async {
                                                if (await _confirm(
                                                    'Delete part?',
                                                    'This removes "${'${parts[pi]['title']}'.isEmpty ? 'this part' : parts[pi]['title']}" and its ${partItems('${parts[pi]['id']}').length} question(s).')) {
                                                  try {
                                                    await repo.deletePart(
                                                        '${parts[pi]['id']}');
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      DSToast.show(context,
                                                          message: '$e',
                                                          tone: DSToastTone
                                                              .error);
                                                    }
                                                  }
                                                  setState(() => _refresh++);
                                                }
                                              },
                                            ),
                                          ]),
                                          if ('${parts[pi]['directions'] ?? ''}'
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 2, bottom: 4),
                                              child: Text(
                                                  '${parts[pi]['directions']}',
                                                  style: DSText.caption
                                                      .copyWith(
                                                          color:
                                                              DSColors.muted)),
                                            ),
                                          for (var ii = 0;
                                              ii <
                                                  partItems(
                                                          '${parts[pi]['id']}')
                                                      .length;
                                              ii++)
                                            itemTile(
                                                partItems(
                                                    '${parts[pi]['id']}')[ii],
                                                ii + 1,
                                                '${parts[pi]['id']}',
                                                '${parts[pi]['mode']}'),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: DSButton(
                                              variant: DSButtonVariant.outline,
                                              size: DSButtonSize.sm,
                                              leadingIcon: DSIconName.add,
                                              onPressed: () => _editQuestion(
                                                  '${a['id']}',
                                                  parts,
                                                  '${parts[pi]['id']}',
                                                  '${parts[pi]['mode']}',
                                                  null,
                                                  partItems(
                                                          '${parts[pi]['id']}')
                                                      .length),
                                              child: const Text('Add item'),
                                            ),
                                          ),
                                          const DSDivider(),
                                        ]),
                                  if (ungrouped.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                          'Ungrouped questions — pick a Part inside each item to file it.',
                                          style: DSText.caption
                                              .copyWith(color: DSColors.muted)),
                                    ),
                                    for (var i = 0; i < ungrouped.length; i++)
                                      itemTile(ungrouped[i], i + 1, null,
                                          'multiple_choice'),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: DSButton(
                                          variant: DSButtonVariant.outline,
                                          size: DSButtonSize.sm,
                                          leadingIcon: DSIconName.add,
                                          onPressed: () => _editQuestion(
                                              '${a['id']}',
                                              parts,
                                              null,
                                              'multiple_choice',
                                              null,
                                              ungrouped.length),
                                          child: const Text('Add item'),
                                        ),
                                      ),
                                    ),
                                  ],
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: DSButton(
                                      variant: DSButtonVariant.outline,
                                      size: DSButtonSize.sm,
                                      leadingIcon: DSIconName.add,
                                      onPressed: () =>
                                          _editPart('${a['id']}', parts.length),
                                      child: const Text('Add part'),
                                    ),
                                  ),
                                ]);
                          },
                        ),
                    ])),
                  ),
              ]);
            },
          ),
        ]))),
      ]),
    );
  }
}

/// Score visibility control: 'immediate' shows scores after submit,
/// 'manual' keeps them hidden until the teacher releases.
class _ScoreRelease extends StatelessWidget {
  final String mode, assessmentId;
  final bool released;
  final Repo repo;
  final VoidCallback onChanged;
  const _ScoreRelease(
      {required this.mode,
      required this.released,
      required this.repo,
      required this.assessmentId,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final manual = mode == 'manual';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            DSStatusBadge(
              status: manual
                  ? (released ? DSStatus.released : DSStatus.hidden)
                  : DSStatus.active,
              label: manual
                  ? (released ? 'Scores released' : 'Scores hidden')
                  : 'Instant scores',
            ),
            DSButton(
              variant: DSButtonVariant.outline,
              size: DSButtonSize.sm,
              onPressed: () async {
                try {
                  await repo.setScoreRelease(
                      assessmentId, manual ? 'immediate' : 'manual');
                } catch (e) {
                  if (context.mounted) {
                    DSToast.show(context,
                        message: '$e', tone: DSToastTone.error);
                  }
                }
                onChanged();
              },
              child: Text(manual ? 'Show after submit' : 'Release manually'),
            ),
            if (manual && !released)
              DSButton(
                size: DSButtonSize.sm,
                onPressed: () async {
                  try {
                    await repo.releaseScores(assessmentId);
                  } catch (e) {
                    if (context.mounted) {
                      DSToast.show(context,
                          message: '$e', tone: DSToastTone.error);
                    }
                  }
                  onChanged();
                },
                child: const Text('Release scores'),
              ),
          ]),
    );
  }
}
