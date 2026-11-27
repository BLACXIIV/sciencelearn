import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

class QuizRunnerScreen extends ConsumerStatefulWidget {
  final String id, title;
  const QuizRunnerScreen({super.key, required this.id, required this.title});
  @override
  ConsumerState<QuizRunnerScreen> createState() => _QuizRunnerState();
}

/// Student-facing prompt: the editor's [blank] marker renders as a line.
String _showPrompt(String s) => s.replaceAll('[blank]', '________');

/// Prompt with the [blank] slot live-filled: [fill] (the student's pick or
/// the correct word) renders inline colored+underlined; unset keeps the line.
Widget _promptView(
  String prompt,
  TextStyle style, {
  String? fill,
  Color fillColor = DSColors.blue,
}) {
  final parts = prompt.split('[blank]');
  if (fill == null || fill.isEmpty || parts.length < 2) {
    return Text(_showPrompt(prompt), style: style);
  }
  return Text.rich(
    TextSpan(
      style: style,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0)
            TextSpan(
              text: fill,
              style: style.copyWith(
                color: fillColor,
                decoration: TextDecoration.underline,
              ),
            ),
          TextSpan(text: parts[i]),
        ],
      ],
    ),
  );
}

/// Student-facing context card — navy panel; a "X:" line prefix renders in
/// sun-yellow like the design's equation labels, the rest white.
Widget _ctxCard(String ctx) {
  final lines = ctx.split('\n');
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: DSColors.navy,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          _ctxLine(lines[i]),
        ],
      ],
    ),
  );
}

Widget _ctxLine(String line) {
  final m = RegExp(r'^(\S+:)\s*(.*)$').firstMatch(line);
  final body = DSText.body.copyWith(
    color: DSColors.surface,
    fontWeight: FontWeight.w500,
  );
  if (m == null) return Text(line, style: body);
  return Text.rich(
    TextSpan(
      style: body,
      children: [
        TextSpan(
          text: m.group(1),
          style: body.copyWith(
            color: DSColors.sun,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextSpan(text: ' ${m.group(2)}'),
      ],
    ),
  );
}

class _QuizRunnerState extends ConsumerState<QuizRunnerScreen> {
  /// Question id -> answer payload: {i}, {b}, {t}, {items}, or {sel}.
  final Map<String, Map<String, dynamic>> _answers = {};
  final Map<String, TextEditingController> _ctrl = {};
  final Map<String, List<TextEditingController>> _enumCtrl = {};
  Json? _result;
  bool _busy = false;
  String? _err;
  int _qi = 0;
  bool _showReview = false;

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final l in _enumCtrl.values) {
      for (final c in l) {
        c.dispose();
      }
    }
    super.dispose();
  }

  bool _answered(Json q) {
    final a = _answers[q['id']];
    if (a == null) return false;
    if (a.containsKey('t')) return (a['t'] as String).trim().isNotEmpty;
    if (a.containsKey('items')) {
      return (a['items'] as List).any((s) => (s as String).trim().isNotEmpty);
    }
    if (a.containsKey('sel')) {
      final min = (q['meta'] as Map?)?['min'] as int? ?? 1;
      return (a['sel'] as List).length >= min;
    }
    if (a.containsKey('z')) {
      final zs = a['z'] as List;
      return zs.length >= (q['choices'] as List? ?? []).length &&
          zs.every((z) => (z as num) >= 0);
    }
    if (a.containsKey('o')) {
      return (a['o'] as List).length >= (q['choices'] as List? ?? []).length;
    }
    return true;
  }

  String _typeLabel(String qtype) => switch (qtype) {
        'multiple_choice' => 'Multiple choice',
        'multi_select' => 'Multi-select',
        'true_false' => 'True or false',
        'fill_blank' => 'Fill in the blank',
        'identification' => 'Identification',
        'enumeration' => 'Enumeration',
        'classification' => 'Classification',
        'ordering' => 'Ordering',
        _ => 'Question',
      };

  /// The classification tag reflects what it carries: a context block =
  /// equation labeling, else zone count (2 = binary, 3+ = multi-category).
  String _clsLabel(Json q) {
    final meta = q['meta'] as Map?;
    if ('${meta?['context'] ?? ''}'.isNotEmpty) return 'Equation labeling';
    return ((meta?['buckets'] as List? ?? const []).length <= 2)
        ? 'Binary classification'
        : 'Multi-category';
  }

  /// True/False option badge — check for True, close for False, colored
  /// by row state like the letter badge it replaces.
  Widget _tfBadge(bool v, DSQuizOptionState s) {
    final (bg, fg) = switch (s) {
      DSQuizOptionState.selected => (DSColors.blue, Colors.white),
      DSQuizOptionState.correct => (DSColors.success, Colors.white),
      DSQuizOptionState.wrong => (DSColors.error, Colors.white),
      _ => (DSColors.track, DSColors.navy),
    };
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: bg, borderRadius: DSRadii.chipBr),
      child: Center(
        child: DSIcon(
          v ? DSIconName.check : DSIconName.close,
          size: 18,
          color: fg,
        ),
      ),
    );
  }

  /// Options for the current question, rendered inside the DSQuizCard.
  List<Widget> _options(Json q) {
    final id = q['id'] as String;
    String letter(int i) => String.fromCharCode(65 + i);
    switch (q['qtype'] as String? ?? 'multiple_choice') {
      case 'true_false':
        final sel = _answers[id]?['b'] as bool?;
        return [
          for (var i = 0; i < 2; i++)
            DSQuizOption(
              letter: letter(i),
              leading: _tfBadge(
                i == 0,
                sel == (i == 0)
                    ? DSQuizOptionState.selected
                    : DSQuizOptionState.normal,
              ),
              state: sel == (i == 0)
                  ? DSQuizOptionState.selected
                  : DSQuizOptionState.normal,
              onTap: () => setState(() => _answers[id] = {'b': i == 0}),
              child: Text(i == 0 ? 'True' : 'False'),
            ),
        ];
      case 'multi_select':
        final sel = List<int>.from(_answers[id]?['sel'] as List? ?? const []);
        final choices = (q['choices'] as List? ?? []);
        final meta = q['meta'] as Map? ?? const {};
        final max = (meta['max'] as int?) ?? choices.length;
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Select ${(meta['min'] as int?) ?? 0}–$max answers.',
              style: DSText.caption.copyWith(color: DSColors.muted),
            ),
          ),
          for (var c = 0; c < choices.length; c++)
            DSQuizOption(
              letter: letter(c),
              leading: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: sel.contains(c) ? DSColors.blue : DSColors.track,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: sel.contains(c) ? DSColors.blue : DSColors.line,
                    width: 2,
                  ),
                ),
                child: sel.contains(c)
                    ? const Center(
                        child: DSIcon(
                          DSIconName.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              state: sel.contains(c)
                  ? DSQuizOptionState.selected
                  : DSQuizOptionState.normal,
              onTap: () => setState(() {
                if (sel.contains(c)) {
                  sel.remove(c);
                } else if (sel.length < max) {
                  sel.add(c);
                }
                _answers[id] = {'sel': sel};
              }),
              child: Text('${choices[c]}'),
            ),
        ];
      case 'fill_blank':
        final fbChoices = (q['choices'] as List? ?? []);
        if (fbChoices.isNotEmpty) {
          // v2 cloze: pick the option that fills the blank.
          final sel = _answers[id]?['i'] as int?;
          return [
            for (var c = 0; c < fbChoices.length; c++)
              DSQuizOption(
                letter: letter(c),
                state: sel == c
                    ? DSQuizOptionState.selected
                    : DSQuizOptionState.normal,
                onTap: () => setState(() => _answers[id] = {'i': c}),
                child: Text('${fbChoices[c]}'),
              ),
          ];
        }
        // Legacy typed fill_blank — free-text input.
        final fc = _ctrl.putIfAbsent(id, () => TextEditingController());
        return [
          DSTextField(
            label: 'Your answer',
            controller: fc,
            onChanged: (v) => _answers[id] = {'t': v},
          ),
        ];
      case 'identification':
        final c = _ctrl.putIfAbsent(id, () => TextEditingController());
        return [
          DSTextField(
            label: 'Your answer',
            controller: c,
            onChanged: (v) => _answers[id] = {'t': v},
          ),
        ];
      case 'enumeration':
        final n = (q['meta'] as Map?)?['n'] as int? ?? 3;
        final ctrls = _enumCtrl.putIfAbsent(
          id,
          () => List.generate(n, (_) => TextEditingController()),
        );
        return [
          for (var i = 0; i < n; i++)
            DSTextField(
              label: 'Item ${i + 1}',
              controller: ctrls[i],
              onChanged: (_) =>
                  _answers[id] = {'items': ctrls.map((c) => c.text).toList()},
            ),
        ];
      case 'classification':
        return [
          _ClsInput(
            // Keyed by question — the selected chip / pool seed must reset
            // when the runner navigates to a different question.
            key: ValueKey(id),
            q: q,
            value: _answers[id],
            onChanged: (v) => setState(() => _answers[id] = v),
          ),
        ];
      case 'ordering':
        return [
          _OrdInput(
            key: ValueKey(id),
            q: q,
            value: _answers[id],
            onChanged: (v) => setState(() => _answers[id] = v),
          ),
        ];
      default: // multiple_choice
        final sel = _answers[id]?['i'] as int?;
        final choices = (q['choices'] as List? ?? []);
        return [
          for (var c = 0; c < choices.length; c++)
            DSQuizOption(
              letter: letter(c),
              state: sel == c
                  ? DSQuizOptionState.selected
                  : DSQuizOptionState.normal,
              onTap: () => setState(() => _answers[id] = {'i': c}),
              child: Text('${choices[c]}'),
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repoProvider);
    return Scaffold(
      body: Column(
        children: [
          DSPageHeader(
            compact: true,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  DSIconButton(
                    icon: DSIconName.back,
                    label: 'Back',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: DSText.h2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _result != null && !_showReview
                ? _buildResult()
                : _buildQuiz(repo),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final score = _result!['score'] as num?;
    final s = (score ?? 0).toDouble();
    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DSCard(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  if (score != null) ...[
                    DSRingChart(
                      size: 140,
                      slices: [
                        DSRingSlice(s, series: 1),
                        DSRingSlice(100 - s, series: 0),
                      ],
                      center: Text(
                        _result!['points_total'] != null
                            ? '${fmtPts(_result!['points_earned'] as num?)}/'
                                '${fmtPts(_result!['points_total'] as num?)}'
                            : '${score.round()}%',
                        style: DSText.h2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_result!['points_total'] != null ? 'points · ' : ''}'
                      '${_result!['total']} questions',
                      style: DSText.bodySm,
                    ),
                  ] else ...[
                    const DSEmptyState(
                      icon: DSIconName.done,
                      title: 'Submitted',
                      body:
                          'Your score will appear once your teacher releases it.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_result!['released'] == true) ...[
                    DSButton(
                      variant: DSButtonVariant.outline,
                      onPressed: () => setState(() => _showReview = true),
                      child: const Text('Review answers'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  DSButton(
                    onPressed: () {
                      ref.invalidate(progressProvider);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Done'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Review rows for one submitted question: correct pick highlighted, the
  /// student's pick marked wrong when it missed. Not tappable.
  List<Widget> _reviewRows(Json q, Json? item) {
    String letter(int i) => String.fromCharCode(65 + i);
    final student = item?['student'] as Json?;
    final ok = item?['is_correct'] == true;
    switch (q['qtype'] as String? ?? 'multiple_choice') {
      case 'true_false':
        final ci = (item?['key'] as Json?)?['correct'] == true ? 0 : 1;
        final sb = student?['b'] as bool?;
        final si = sb == null ? null : (sb ? 0 : 1);
        return [
          for (var i = 0; i < 2; i++)
            DSQuizOption(
              letter: letter(i),
              leading: _tfBadge(
                i == 0,
                i == ci
                    ? DSQuizOptionState.correct
                    : (i == si && !ok
                        ? DSQuizOptionState.wrong
                        : DSQuizOptionState.normal),
              ),
              state: i == ci
                  ? DSQuizOptionState.correct
                  : (i == si && !ok
                      ? DSQuizOptionState.wrong
                      : DSQuizOptionState.normal),
              child: Text(i == 0 ? 'True' : 'False'),
            ),
        ];
      case 'multi_select':
        final keys = <int>{
          for (final i
              in ((item?['key'] as Json?)?['indexes'] as List? ?? const []))
            (i as num).toInt(),
        };
        final picks = <int>{
          for (final i in (student?['sel'] as List? ?? const []))
            (i as num).toInt(),
        };
        final msChoices = (q['choices'] as List? ?? const []);
        return [
          for (var i = 0; i < msChoices.length; i++)
            DSQuizOption(
              letter: letter(i),
              state: keys.contains(i)
                  ? DSQuizOptionState.correct
                  : (picks.contains(i)
                      ? DSQuizOptionState.wrong
                      : DSQuizOptionState.normal),
              child: Text('${msChoices[i]}'),
            ),
        ];
      case 'fill_blank':
        final fbChoices = (q['choices'] as List? ?? const []);
        if (fbChoices.isNotEmpty) {
          // Options mode (v2): pick the option that fills the blank.
          final ci = item?['correct_index'] as int? ?? -1;
          final si = student?['i'] as int?;
          return [
            for (var i = 0; i < fbChoices.length; i++)
              DSQuizOption(
                letter: letter(i),
                state: i == ci
                    ? DSQuizOptionState.correct
                    : (i == si && !ok
                        ? DSQuizOptionState.wrong
                        : DSQuizOptionState.normal),
                child: Text('${fbChoices[i]}'),
              ),
          ];
        }
        // Legacy typed fill_blank — accepted-answer card.
        final fbAccepted = List<dynamic>.from(
          (item?['key'] as Json?)?['accepted'] as List? ?? const [],
        );
        final fbGot = '${student?['t'] ?? ''}'.trim();
        return [
          DSListItemCard(
            leading: DSIcon(
              ok ? DSIconName.check : DSIconName.close,
              size: 20,
              color: ok ? DSColors.success : DSColors.error,
            ),
            title: Text(fbGot.isEmpty ? '—' : fbGot),
            subtitle: Text(
              ok
                  ? 'Your answer — correct'
                  : 'Your answer · Correct: ${fbAccepted.join(' / ')}',
            ),
          ),
        ];
      case 'identification':
        final accepted = List<dynamic>.from(
          (item?['key'] as Json?)?['accepted'] as List? ?? const [],
        );
        final got = '${student?['t'] ?? ''}'.trim();
        return [
          DSListItemCard(
            leading: DSIcon(
              ok ? DSIconName.check : DSIconName.close,
              size: 20,
              color: ok ? DSColors.success : DSColors.error,
            ),
            title: Text(got.isEmpty ? '—' : got),
            subtitle: Text(
              ok
                  ? 'Your answer — correct'
                  : 'Your answer · Correct: ${accepted.join(' / ')}',
            ),
          ),
        ];
      case 'enumeration':
        final exp = List<dynamic>.from(
          (item?['key'] as Json?)?['items'] as List? ?? const [],
        );
        final got = List<dynamic>.from(student?['items'] as List? ?? const [])
            .where((s) => '$s'.trim().isNotEmpty)
            .toList();
        final earned = (item?['earned'] as num?) ?? 0;
        final ordered = (item?['key'] as Json?)?['ordered'] == true;
        return [
          DSListItemCard(
            leading: DSIcon(
              ok ? DSIconName.check : DSIconName.close,
              size: 20,
              color: ok ? DSColors.success : DSColors.error,
            ),
            title: Text(
              'Expected: ${exp.join(', ')}${ordered ? ' (in order)' : ''}',
            ),
            subtitle: Text(
              'Yours: ${got.isEmpty ? '—' : got.join(', ')} · ${(earned * 100).round()}%',
            ),
          ),
        ];
      case 'classification':
        final key = item?['key'] as Json? ?? const {};
        final buckets = List<dynamic>.from(
          key['buckets'] as List? ??
              ((q['meta'] as Map?)?['buckets'] as List? ?? const []),
        );
        final clsCtx =
            '${key['context'] ?? (q['meta'] as Map?)?['context'] ?? ''}';
        final zones = List<dynamic>.from(key['zones'] as List? ?? const []);
        final zs = List<dynamic>.from(student?['z'] as List? ?? const []);
        final clsChoices = (q['choices'] as List? ?? const []);
        String bName(int? z) => z == null || z < 0
            ? '—'
            : '${z < buckets.length ? buckets[z] : 'Bucket ${z + 1}'}';
        return [
          if (clsCtx.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ctxCard(clsCtx),
            ),
          for (var i = 0; i < clsChoices.length; i++)
            DSListItemCard(
              leading: DSIcon(
                i < zs.length && zs[i] == (zones.length > i ? zones[i] : null)
                    ? DSIconName.check
                    : DSIconName.close,
                size: 20,
                color: i < zs.length &&
                        zs[i] == (zones.length > i ? zones[i] : null)
                    ? DSColors.success
                    : DSColors.error,
              ),
              title: Text(
                '${clsChoices[i]} → ${bName(zones.length > i ? (zones[i] as num?)?.toInt() : null)}',
              ),
              subtitle:
                  i < zs.length && zs[i] != (zones.length > i ? zones[i] : null)
                      ? Text('Yours: ${bName((zs[i] as num?)?.toInt())}')
                      : null,
            ),
        ];
      case 'ordering':
        final correct = List<dynamic>.from(
          (item?['key'] as Json?)?['correct'] as List? ?? const [],
        );
        final os = List<dynamic>.from(student?['o'] as List? ?? const []);
        final ordChoices = (q['choices'] as List? ?? const []);
        String at(int p, List<dynamic> list) =>
            p < list.length && (list[p] as num).toInt() < ordChoices.length
                ? '${ordChoices[(list[p] as num).toInt()]}'
                : '—';
        return [
          for (var p = 0; p < correct.length; p++)
            Builder(
              builder: (_) {
                final wrong = p < os.length && os[p] != correct[p];
                return DSListItemCard(
                  leading: DSIcon(
                    wrong ? DSIconName.close : DSIconName.check,
                    size: 20,
                    color: wrong ? DSColors.error : DSColors.success,
                  ),
                  title: Text('${p + 1}. ${at(p, correct)}'),
                  subtitle: wrong ? Text('Yours: ${at(p, os)}') : null,
                );
              },
            ),
        ];
      default: // multiple_choice
        final ci = item?['correct_index'] as int? ?? -1;
        final si = student?['i'] as int?;
        final choices = (q['choices'] as List? ?? const []);
        return [
          for (var i = 0; i < choices.length; i++)
            DSQuizOption(
              letter: letter(i),
              state: i == ci
                  ? DSQuizOptionState.correct
                  : (i == si && !ok
                      ? DSQuizOptionState.wrong
                      : DSQuizOptionState.normal),
              child: Text('${choices[i]}'),
            ),
        ];
    }
  }

  Widget _reviewCard(
    Json q,
    int n,
    Json? item,
    Map<String, int> partNo,
    Map<String, Json> partMeta,
  ) {
    final pid = '${q['part_id']}';
    final p = partMeta[pid];
    final ok = item?['is_correct'] == true;
    final rows = _reviewRows(q, item);
    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Question $n',
                style: DSText.label.copyWith(color: DSColors.muted),
              ),
              DSIcon(
                ok ? DSIconName.check : DSIconName.close,
                size: 16,
                color: ok ? DSColors.success : DSColors.error,
              ),
              if (p != null)
                Text(
                  'Activity ${partNo[pid]}${'${p['title']}'.isNotEmpty ? ' — ${p['title']}' : ''}',
                  style: DSText.caption.copyWith(color: DSColors.muted),
                ),
              if (p != null && p['scored'] == false)
                const DSChip(
                  variant: DSChipVariant.pastel,
                  pastel: DSChipPastel.yellow,
                  child: Text('Not scored'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          q['qtype'] == 'fill_blank'
              ? _promptView(
                  '${q['prompt']}',
                  DSText.title,
                  fill: (() {
                    final chs = q['choices'] as List? ?? const [];
                    final ci = item?['correct_index'] as int?;
                    return ci != null && ci < chs.length ? '${chs[ci]}' : null;
                  })(),
                  fillColor: DSColors.success,
                )
              : Text(_showPrompt('${q['prompt']}'), style: DSText.title),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: DSSpacing.s2),
            rows[i],
          ],
        ],
      ),
    );
  }

  /// Post-submit screen: score card + per-question review (keys hidden until
  /// scores are released — then only "Submitted" shows, and no retake).
  Widget _buildReview(List<Json> qs, List<Json> parts, Json review) {
    final released = review['released'] == true;
    final score = review['score'] as num?;
    final items = {
      for (final it in List<Json>.from(review['items'] as List? ?? const []))
        '${it['question_id']}': it,
    };
    final partNo = <String, int>{};
    final partMeta = <String, Json>{};
    for (var i = 0; i < parts.length; i++) {
      partNo['${parts[i]['id']}'] = i + 1;
      partMeta['${parts[i]['id']}'] = parts[i];
    }
    final s = (score ?? 0).toDouble();
    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DSCard(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  if (released && score != null) ...[
                    DSRingChart(
                      size: 140,
                      slices: [
                        DSRingSlice(s, series: 1),
                        DSRingSlice(100 - s, series: 0),
                      ],
                      center: Text(
                        review['points_total'] != null
                            ? '${fmtPts(review['points_earned'] as num?)}/'
                                '${fmtPts(review['points_total'] as num?)}'
                            : '${score.round()}%',
                        style: DSText.h2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${review['points_total'] != null ? 'points · ' : ''}'
                      '${review['total']} questions',
                      style: DSText.bodySm,
                    ),
                  ] else ...[
                    DSEmptyState(
                      icon: DSIconName.done,
                      title: released ? 'Submitted' : 'Already submitted',
                      body: released
                          ? 'Your answers are below.'
                          : 'Your score will appear once your teacher releases it.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  DSButton(
                    onPressed: () {
                      ref.invalidate(progressProvider);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Done'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (released)
            for (var i = 0; i < qs.length; i++) ...[
              const SizedBox(height: 12),
              _reviewCard(
                qs[i],
                i + 1,
                items['${qs[i]['id']}'],
                partNo,
                partMeta,
              ),
            ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuiz(Repo repo) {
    return FutureBuilder<List<Object>>(
      future: Future.wait([
        repo.questions(widget.id),
        repo.partsPublic(widget.id),
        repo.reviewAttempt(widget.id),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: DSLoadingIndicator());
        }
        final qs = snap.data![0] as List<Json>;
        final parts = snap.data![1] as List<Json>;
        final review = snap.data![2] as Json;
        // One-shot: a submitted attempt turns the runner into review mode.
        if (review['attempted'] == true) {
          return _buildReview(qs, parts, review);
        }
        if (qs.isEmpty) {
          return const DSEmptyState(
            icon: DSIconName.quiz,
            title: 'No questions yet',
          );
        }
        if (_qi >= qs.length) _qi = qs.length - 1;
        final answered = qs.where(_answered).length;
        final q = qs[_qi];
        // The part this question belongs to, + its 1-based display index.
        Json? part;
        var partNo = 0;
        for (var i = 0; i < parts.length; i++) {
          if (parts[i]['id'] == q['part_id']) {
            part = parts[i];
            partNo = i + 1;
          }
        }
        Future<void> doSubmit() async {
          setState(() {
            _busy = true;
            _err = null;
          });
          try {
            final r = await repo.submit(widget.id, _answers);
            setState(() => _result = r);
          } catch (e) {
            setState(() => _err = '$e'.replaceFirst('Exception: ', ''));
          } finally {
            if (mounted) setState(() => _busy = false);
          }
        }

        Future<void> trySubmit() async {
          if (answered >= qs.length) return doSubmit();
          final ok = await showDSModal<bool>(
            context,
            title: 'Submit anyway?',
            body: Text(
              '${qs.length - answered} ${qs.length - answered == 1 ? 'question' : 'questions'} unanswered. Submit anyway?',
            ),
            actions: [
              DSButton(
                variant: DSButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep going'),
              ),
              DSButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Submit'),
              ),
            ],
          );
          if (ok == true) await doSubmit();
        }

        final opts = _options(q);
        // A part's mode wins over the item's qtype for the tag — a
        // classification item inside a "Matching" part reads "Matching".
        // A bare classification tags by zone count: binary vs multi.
        final tag = part?['mode'] == 'matching'
            ? 'Matching'
            : q['qtype'] == 'classification'
                ? _clsLabel(q)
                : _typeLabel('${q['qtype']}');
        return MaxWidth(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '$tag · Question ${_qi + 1} of ${qs.length}',
                style: DSText.label.copyWith(color: DSColors.muted),
              ),
              const SizedBox(height: 8),
              DSProgressBar(
                value: answered / qs.length,
                size: DSProgressBarSize.sm,
                tone: DSProgressBarTone.mint,
              ),
              const SizedBox(height: 12),
              DSQuizNav(
                count: qs.length,
                current: _qi,
                answered: [for (final qq in qs) _answered(qq)],
                onSelect: (i) => setState(() => _qi = i),
              ),
              if (part != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Activity $partNo${'${part['title']}'.isNotEmpty ? ' — ${part['title']}' : ''}',
                            style: DSText.label,
                          ),
                          if (part['scored'] == false)
                            const DSChip(
                              variant: DSChipVariant.pastel,
                              pastel: DSChipPastel.yellow,
                              child: Text('Not scored'),
                            ),
                        ],
                      ),
                      if ('${part['directions'] ?? ''}'.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${part['directions']}',
                            style: DSText.caption.copyWith(
                              color: DSColors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              q['qtype'] == 'fill_blank'
                  ? _promptView(
                      '${q['prompt']}',
                      DSText.h2,
                      fill: (() {
                        final chs = q['choices'] as List? ?? const [];
                        final si = _answers['${q['id']}']?['i'] as int?;
                        return si != null && si < chs.length
                            ? '${chs[si]}'
                            : null;
                      })(),
                    )
                  : Text(_showPrompt('${q['prompt']}'), style: DSText.h2),
              const SizedBox(height: 16),
              for (var i = 0; i < opts.length; i++) ...[
                if (i > 0) const SizedBox(height: DSSpacing.s3),
                opts[i],
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  DSButton(
                    variant: DSButtonVariant.outline,
                    disabled: _qi == 0,
                    onPressed: () => setState(() => _qi -= 1),
                    child: const Text('Back'),
                  ),
                  if (_qi < qs.length - 1)
                    DSButton(
                      onPressed: () => setState(() => _qi += 1),
                      child: const Text('Next'),
                    )
                  else
                    DSButton(
                      loading: _busy,
                      onPressed: _busy ? null : trySubmit,
                      child: const Text('Submit answers'),
                    ),
                ],
              ),
              if (_err != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _err!,
                    textAlign: TextAlign.center,
                    style: DSText.caption.copyWith(color: DSColors.error),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Classification pool→zone input: tap an item chip, then tap a zone card —
/// the chip moves into it. Tapping a placed chip re-selects it to move it.
class _ClsInput extends StatefulWidget {
  final Json q;
  final Map<String, dynamic>? value;
  final void Function(Map<String, dynamic>) onChanged;
  const _ClsInput(
      {super.key, required this.q, this.value, required this.onChanged});
  @override
  State<_ClsInput> createState() => _ClsInputState();
}

class _ClsInputState extends State<_ClsInput> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    final items = (q['choices'] as List? ?? const []);
    final buckets = List<dynamic>.from(
      (q['meta'] as Map?)?['buckets'] as List? ?? const [],
    );
    final ctx = '${(q['meta'] as Map?)?['context'] ?? ''}';
    final zs = List<int>.from(widget.value?['z'] as List? ?? const []);
    int zoneOf(int i) => i < zs.length ? zs[i] : -1;
    final all = List<int>.generate(items.length, (i) => i);
    final unplaced = all.where((i) => zoneOf(i) < 0).toList();

    void place(int zone) {
      final s = _sel;
      if (s == null) return;
      final next = List<int>.generate(items.length, zoneOf);
      next[s] = zone;
      widget.onChanged({'z': next});
      setState(() => _sel = null);
    }

    Widget chip(int i) {
      final sel = _sel == i;
      return GestureDetector(
        // A chip inside a zone claims the tap — the zone's place() won't fire.
        onTap: () => setState(() => _sel = sel ? null : i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? DSColors.blue : DSColors.pastelBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${items[i]}',
            style: DSText.body.copyWith(
              fontWeight: FontWeight.w600,
              color: sel ? DSColors.surface : DSColors.navy,
            ),
          ),
        ),
      );
    }

    Widget chips(Iterable<int> idx) => Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final i in idx) chip(i)],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ctx.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ctxCard(ctx),
          ),
        _DashedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Tap an item, then tap a zone',
                  style: DSText.label.copyWith(color: DSColors.muted),
                ),
              ),
              unplaced.isNotEmpty
                  ? chips(unplaced)
                  : Text(
                      'All items sorted.',
                      style: DSText.bodySm.copyWith(color: DSColors.muted),
                    ),
            ],
          ),
        ),
        for (var bi = 0; bi < buckets.length; bi++)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: () => place(bi),
              child: _DashedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${buckets[bi]}',
                        style: DSText.label.copyWith(color: DSColors.muted),
                      ),
                    ),
                    chips(all.where((i) => zoneOf(i) == bi)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Rounded-rect dashed outline matching the web `.sd-cls-*` zone cards.
class _DashedBox extends StatelessWidget {
  final Widget child;
  const _DashedBox({required this.child});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedRectPainter(color: DSColors.edgeSoft),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + dash).clamp(0.0, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}

/// Ordering slot→pool input: dashed "Step" slots on top, a "Tap in order"
/// chip pool below — each tap fills the next slot; tapping a placed chip pulls
/// it back into the pool (later chips compact up). `o` = choice indexes in
/// slot order, empty until the student starts placing.
class _OrdInput extends StatefulWidget {
  final Json q;
  final Map<String, dynamic>? value;
  final void Function(Map<String, dynamic>) onChanged;
  const _OrdInput(
      {super.key, required this.q, this.value, required this.onChanged});
  @override
  State<_OrdInput> createState() => _OrdInputState();
}

class _OrdInputState extends State<_OrdInput> {
  /// Pool display order — the saved scramble, or reshuffled per open.
  late final List<int> _seed;

  @override
  void initState() {
    super.initState();
    final n = (widget.q['choices'] as List? ?? const []).length;
    _seed = List<int>.generate(n, (i) => i);
    if ((widget.q['meta'] as Map?)?['shuffle'] != false) _seed.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.q['choices'] as List? ?? const []);
    final placed = List<int>.from(widget.value?['o'] as List? ?? const []);
    final pool = _seed.where((c) => !placed.contains(c)).toList();

    Widget chip(int c, void Function() onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: DSColors.pastelBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${items[c]}',
              style: DSText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: DSColors.navy,
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var p = 0; p < items.length; p++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DashedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${p + 1}',
                    style: DSText.label.copyWith(color: DSColors.muted),
                  ),
                  if (p < placed.length)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      // pulling a chip compacts the slots above the pool
                      child: chip(
                        placed[p],
                        () => widget.onChanged({
                          'o': [
                            for (var x = 0; x < placed.length; x++)
                              if (x != p) placed[x],
                          ],
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        _DashedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Tap in order',
                  style: DSText.label.copyWith(color: DSColors.muted),
                ),
              ),
              pool.isNotEmpty
                  ? Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in pool)
                          chip(
                            c,
                            () => widget.onChanged({
                              'o': [...placed, c],
                            }),
                          ),
                      ],
                    )
                  : Text(
                      'All steps placed.',
                      style: DSText.bodySm.copyWith(color: DSColors.muted),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
