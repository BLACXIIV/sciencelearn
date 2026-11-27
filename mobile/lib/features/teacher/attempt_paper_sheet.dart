import 'package:flutter/material.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

String _fmtDate(Object? iso) {
  if (iso == null) return '—';
  final d = DateTime.tryParse('$iso')?.toLocal();
  if (d == null) return '—';
  const mo = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${mo[d.month - 1]} ${d.day}, ${d.year}';
}

/// Student-facing prompt: the editor's [blank] marker renders as a line.
String _showPrompt(String s) => s.replaceAll('[blank]', '________');

/// Prompt with the [blank] slot filled by the correct word (green inline).
Widget _promptView(String prefix, String prompt, TextStyle style,
    {String? fill}) {
  final parts = prompt.split('[blank]');
  if (fill == null || fill.isEmpty || parts.length < 2) {
    return Text('$prefix${_showPrompt(prompt)}', style: style);
  }
  return Text.rich(
    TextSpan(style: style, children: [
      TextSpan(text: prefix),
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0)
          TextSpan(
            text: fill,
            style: style.copyWith(
                color: DSColors.success, decoration: TextDecoration.underline),
          ),
        TextSpan(text: parts[i]),
      ],
    ]),
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
      borderRadius: DSRadii.inputBr,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < lines.length; i++) ...[
        if (i > 0) const SizedBox(height: 4),
        _ctxLine(lines[i]),
      ],
    ]),
  );
}

Widget _ctxLine(String line) {
  final m = RegExp(r'^(\S+:)\s*(.*)$').firstMatch(line);
  final body = DSText.body
      .copyWith(color: DSColors.surface, fontWeight: FontWeight.w500);
  if (m == null) return Text(line, style: body);
  return Text.rich(TextSpan(style: body, children: [
    TextSpan(
        text: m.group(1),
        style: body.copyWith(color: DSColors.sun, fontWeight: FontWeight.w700)),
    TextSpan(text: ' ${m.group(2)}'),
  ]));
}

/// The student's paper for one assessment, presented as a tall bottom sheet —
/// the mobile counterpart of the web AttemptPaperModal. Meta header (lesson,
/// teacher, student, publish/answer dates, score), then per-part questions
/// with correct answers highlighted green and missed picks red.
class AttemptPaperSheet extends StatelessWidget {
  final Repo repo;
  final String assessmentId, studentId, studentName, teacherId;
  final bool released;
  const AttemptPaperSheet({
    super.key,
    required this.repo,
    required this.assessmentId,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    this.released = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: KeepDataFutureBuilder<List<Object>>(
        future: Future.wait([
          repo.attemptPaper(assessmentId, studentId),
          repo.profileName(teacherId),
        ]),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text("Couldn't load the paper: ${snap.error}",
                  style: DSText.bodySm.copyWith(color: DSColors.error)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: DSLoadingIndicator());
          }
          final p = snap.data![0] as Json;
          final teacherName = '${snap.data![1]}';
          final attempt = p['attempt'] as Json?;
          final answers = p['answers'] as Map? ?? const {};

          final qs = List<Json>.from(p['questions'] as List? ?? const []);
          final parts = List<Json>.from(p['parts'] as List? ?? const []);
          final byPart = <String?, List<Json>>{};
          for (final q in qs) {
            byPart.putIfAbsent(q['part_id'] as String?, () => []).add(q);
          }
          final groups = <({Json? part, List<Json> qs})>[];
          for (final pt in parts) {
            final id = '${pt['id']}';
            if (byPart.containsKey(id)) {
              groups.add((part: pt, qs: byPart.remove(id)!));
            }
          }
          // Ungrouped questions plus orphans whose part was deleted.
          final rest = byPart.values.expand((e) => e).toList();
          if (rest.isNotEmpty) groups.add((part: null, qs: rest));

          return ListView(children: [
            Row(children: [
              Expanded(
                  child: Text('${p['assessmentTitle']}', style: DSText.h3)),
              DSIconButton(
                  icon: DSIconName.close,
                  label: 'Close',
                  onPressed: () => Navigator.of(context).pop()),
            ]),
            const SizedBox(height: 10),
            _meta(p, attempt, teacherName),
            const SizedBox(height: 12),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('No questions in this activity yet.',
                    style: DSText.bodySm.copyWith(color: DSColors.muted)),
              ),
            for (var gi = 0; gi < groups.length; gi++)
              _partSection(groups[gi], gi, answers),
            const SizedBox(height: 16),
          ]);
        },
      ),
    );
  }

  Widget _meta(Json p, Json? attempt, String teacherName) {
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 86,
                child: Text(k.toUpperCase(),
                    style: DSText.label.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: DSColors.muted))),
            Expanded(
                child: Text(v,
                    style:
                        DSText.bodySm.copyWith(fontWeight: FontWeight.w600))),
          ]),
        );
    final score = attempt == null
        ? 'Not taken'
        : attempt['points_total'] != null
            ? '${fmtPts(attempt['points_earned'] as num?)} / '
                '${fmtPts(attempt['points_total'] as num?)} pts'
                '${released ? '' : ' (not released to student)'}'
            : attempt['score'] == null
                ? '—'
                : '${(attempt['score'] as num).round()}%'
                    '${released ? '' : ' (not released to student)'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: DSRadii.buttonBr,
        border: Border.all(color: DSColors.line, width: 1.5),
      ),
      child: Column(children: [
        row('Lesson', '${p['lessonTitle']}'),
        row('Teacher', teacherName),
        row('Student', studentName),
        row('Published', _fmtDate(p['publishedAt'])),
        row('Answered', _fmtDate(attempt?['submitted_at'])),
        row('Score', score),
      ]),
    );
  }

  Widget _partSection(({Json? part, List<Json> qs}) g, int gi, Map answers) {
    final part = g.part;
    final title = part == null
        ? 'Questions'
        : 'Activity ${gi + 1}'
            '${'${part['title']}'.isNotEmpty ? ' — ${part['title']}' : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 4, children: [
          Text(title, style: DSText.title),
          if (part != null && part['scored'] == false)
            const DSChip(
                variant: DSChipVariant.pastel,
                pastel: DSChipPastel.yellow,
                child: Text('Not scored')),
          if (part != null && part['scored'] != false)
            Text(
                '(${fmtPts(part['points'] as num? ?? 1)} '
                'pt${(part['points'] as num? ?? 1) == 1 ? '' : 's'} each)',
                style: DSText.caption.copyWith(color: DSColors.muted)),
        ]),
        if ('${part?['directions'] ?? ''}'.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${part!['directions']}',
                style: DSText.caption.copyWith(color: DSColors.muted)),
          ),
        for (var i = 0; i < g.qs.length; i++)
          _question(g.qs[i], i + 1, answers['${g.qs[i]['id']}'] as Json?),
      ]),
    );
  }

  Widget _question(Json q, int n, Json? ans) {
    final stu = ans?['answer'] as Json?;
    final ok = ans?['is_correct'] == true;
    String letter(int i) => String.fromCharCode(65 + i);
    final body = switch ('${q['qtype'] ?? 'multiple_choice'}') {
      'multi_select' => () {
          final keys = <int>{
            for (final i
                in ((q['answer'] as Json?)?['indexes'] as List? ?? const []))
              (i as num).toInt()
          };
          final picks = <int>{
            for (final i in (stu?['sel'] as List? ?? const []))
              (i as num).toInt()
          };
          final choices = (q['choices'] as List? ?? const []);
          return Column(children: [
            for (var i = 0; i < choices.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _option(letter(i), '${choices[i]}',
                  correct: keys.contains(i),
                  pickedWrong: picks.contains(i) && !keys.contains(i)),
            ],
          ]);
        }(),
      'true_false' => () {
          final ci = (q['answer'] as Json?)?['correct'] == true ? 0 : 1;
          final sb = stu?['b'] as bool?;
          final si = sb == null ? null : (sb ? 0 : 1);
          return Column(children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _option(letter(i), i == 0 ? 'True' : 'False',
                  correct: i == ci, pickedWrong: i == si && !ok),
            ],
          ]);
        }(),
      'fill_blank' => () {
          final choices = (q['choices'] as List? ?? const []);
          if (choices.isNotEmpty) {
            // Options mode (v2): pick the option that fills the blank.
            final ci = q['correct_index'] as int? ?? -1;
            final si = stu?['i'] as int?;
            return Column(children: [
              for (var i = 0; i < choices.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _option(letter(i), '${choices[i]}',
                    correct: i == ci, pickedWrong: i == si && !ok),
              ],
            ]);
          }
          // Legacy typed fill_blank — accepted-answer rows.
          final accepted = List<dynamic>.from(
              (q['answer'] as Json?)?['accepted'] as List? ?? const []);
          final got = '${stu?['t'] ?? ''}'.trim();
          return Column(children: [
            _ansRow('Student answer: ${got.isEmpty ? '—' : got}',
                ok: ok ? true : (ans != null ? false : null)),
            if (!ok) ...[
              const SizedBox(height: 8),
              _ansRow(
                  'Correct answer${accepted.length > 1 ? 's' : ''}: '
                  '${accepted.join(' / ')}',
                  ok: true),
            ],
          ]);
        }(),
      'classification' => () {
          final ans0 = q['answer'] as Json? ?? const {};
          final buckets =
              List<dynamic>.from(ans0['buckets'] as List? ?? const []);
          final zones = List<dynamic>.from(ans0['zones'] as List? ?? const []);
          final zs = List<dynamic>.from(stu?['z'] as List? ?? const []);
          final choices = (q['choices'] as List? ?? const []);
          final clsCtx = '${ans0['context'] ?? ''}';
          String bName(int? z) => z == null || z < 0
              ? '—'
              : '${z < buckets.length ? buckets[z] : 'Bucket ${z + 1}'}';
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (clsCtx.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ctxCard(clsCtx),
                  ),
                for (var i = 0; i < choices.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final keyZ =
                        zones.length > i ? (zones[i] as num?)?.toInt() : null;
                    final stuZ =
                        zs.length > i ? (zs[i] as num?)?.toInt() : null;
                    final wrong = stuZ != null && stuZ != keyZ;
                    return _ansRow(
                      '${choices[i]} → ${bName(keyZ)}'
                      '${wrong ? ' · student: ${bName(stuZ)}' : ''}',
                      ok: wrong
                          ? false
                          : (stuZ != null || ans != null ? true : null),
                    );
                  }),
                ],
              ]);
        }(),
      'ordering' => () {
          final correct = List<dynamic>.from(
              (q['answer'] as Json?)?['correct'] as List? ?? const []);
          final os = List<dynamic>.from(stu?['o'] as List? ?? const []);
          final choices = (q['choices'] as List? ?? const []);
          String at(int p, List<dynamic> list) =>
              p < list.length && (list[p] as num).toInt() < choices.length
                  ? '${choices[(list[p] as num).toInt()]}'
                  : '—';
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var p = 0; p < correct.length; p++) ...[
                  if (p > 0) const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final wrong = p < os.length && os[p] != correct[p];
                    return _ansRow(
                      '${p + 1}. ${at(p, correct)}'
                      '${wrong ? ' · student: ${at(p, os)}' : ''}',
                      ok: wrong
                          ? false
                          : (p < os.length || ans != null ? true : null),
                    );
                  }),
                ],
              ]);
        }(),
      'identification' => () {
          final accepted = List<dynamic>.from(
              (q['answer'] as Json?)?['accepted'] as List? ?? const []);
          final got = '${stu?['t'] ?? ''}'.trim();
          return Column(children: [
            _ansRow('Student answer: ${got.isEmpty ? '—' : got}',
                ok: ok ? true : (ans != null ? false : null)),
            if (!ok) ...[
              const SizedBox(height: 8),
              _ansRow(
                  'Correct answer${accepted.length > 1 ? 's' : ''}: '
                  '${accepted.join(' / ')}',
                  ok: true),
            ],
          ]);
        }(),
      'enumeration' => () {
          final exp = List<dynamic>.from(
              (q['answer'] as Json?)?['items'] as List? ?? const []);
          final got = List<dynamic>.from(stu?['items'] as List? ?? const [])
              .where((s) => '$s'.trim().isNotEmpty)
              .toList();
          final earned = (ans?['earned'] as num?) ?? 0;
          final ordered = (q['answer'] as Json?)?['ordered'] == true;
          return Column(children: [
            _ansRow(
                'Yours: ${got.isEmpty ? '—' : got.join(', ')} · '
                '${(earned * 100).round()}%',
                ok: ok ? true : (ans != null ? false : null)),
            const SizedBox(height: 8),
            _ansRow(
                'Expected: ${exp.join(', ')}'
                '${ordered ? ' (in order)' : ''}',
                ok: true),
          ]);
        }(),
      _ => () {
          // multiple_choice
          final ci = q['correct_index'] as int? ?? -1;
          final si = stu?['i'] as int?;
          final choices = (q['choices'] as List? ?? const []);
          return Column(children: [
            for (var i = 0; i < choices.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _option(letter(i), '${choices[i]}',
                  correct: i == ci, pickedWrong: i == si && !ok),
            ],
          ]);
        }(),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        q['qtype'] == 'fill_blank'
            ? _promptView(
                '$n. ', '${q['prompt']}', DSText.title.copyWith(fontSize: 14),
                fill: (() {
                final chs = q['choices'] as List? ?? const [];
                final ci = q['correct_index'] as int?;
                return ci != null && ci < chs.length ? '${chs[ci]}' : null;
              })())
            : Text('$n. ${_showPrompt('${q['prompt']}')}',
                style: DSText.title.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        body,
      ]),
    );
  }

  /// One lettered option row: green = correct answer, red = the student's
  /// missed pick. A correct pick gets both (green row + check mark).
  Widget _option(String letter, String text,
      {bool correct = false, bool pickedWrong = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: correct
            ? DSColors.pastelMint
            : pickedWrong
                ? DSColors.errorSurface
                : DSColors.paper,
        borderRadius: DSRadii.buttonBr,
        border: Border.all(
            color: correct
                ? DSColors.success
                : pickedWrong
                    ? DSColors.error
                    : Colors.transparent,
            width: 2),
      ),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
              color: DSColors.track, borderRadius: DSRadii.chipBr),
          child: Center(
              child: Text(letter,
                  style: DSText.label
                      .copyWith(fontSize: 13, color: DSColors.navy))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: DSText.bodySm.copyWith(fontWeight: FontWeight.w500))),
        if (correct)
          const DSIcon(DSIconName.check, size: 16, color: DSColors.success),
        if (pickedWrong)
          const DSIcon(DSIconName.close, size: 16, color: DSColors.error),
      ]),
    );
  }

  /// A text-answer row — ok=true paints green, false red, null plain.
  Widget _ansRow(String text, {bool? ok}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ok == true
            ? DSColors.pastelMint
            : ok == false
                ? DSColors.errorSurface
                : DSColors.paper,
        borderRadius: DSRadii.buttonBr,
      ),
      child: Row(children: [
        Expanded(child: Text(text, style: DSText.bodySm)),
        if (ok == true)
          const DSIcon(DSIconName.check, size: 16, color: DSColors.success),
        if (ok == false)
          const DSIcon(DSIconName.close, size: 16, color: DSColors.error),
      ]),
    );
  }
}
