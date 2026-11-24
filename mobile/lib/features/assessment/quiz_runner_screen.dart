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

class _QuizRunnerState extends ConsumerState<QuizRunnerScreen> {
  /// Question id -> answer payload: {i}, {b}, {t}, or {items}.
  final Map<String, Map<String, dynamic>> _answers = {};
  final Map<String, TextEditingController> _ctrl = {};
  final Map<String, List<TextEditingController>> _enumCtrl = {};
  Json? _result;
  bool _busy = false;
  String? _err;
  int _qi = 0;

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
    return true;
  }

  String _typeLabel(String qtype) => switch (qtype) {
        'multiple_choice' => 'Multiple choice',
        'true_false' => 'True or false',
        'fill_blank' => 'Fill in the blank',
        'identification' => 'Identification',
        'enumeration' => 'Enumeration',
        _ => 'Question',
      };

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
              state: sel == (i == 0)
                  ? DSQuizOptionState.selected
                  : DSQuizOptionState.normal,
              onTap: () => setState(() => _answers[id] = {'b': i == 0}),
              child: Text(i == 0 ? 'True' : 'False'),
            ),
        ];
      case 'fill_blank':
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
            id, () => List.generate(n, (_) => TextEditingController()));
        return [
          for (var i = 0; i < n; i++)
            DSTextField(
              label: 'Item ${i + 1}',
              controller: ctrls[i],
              onChanged: (_) =>
                  _answers[id] = {'items': ctrls.map((c) => c.text).toList()},
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
              Expanded(
                child: Text(widget.title,
                    style: DSText.h2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ),
        Expanded(child: _result != null ? _buildResult() : _buildQuiz(repo)),
      ]),
    );
  }

  Widget _buildResult() {
    final score = _result!['score'] as num?;
    final s = (score ?? 0).toDouble();
    return MaxWidth(
        child: ListView(padding: const EdgeInsets.all(16), children: [
      DSCard(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 16),
            if (score != null) ...[
              DSRingChart(
                size: 140,
                slices: [
                  DSRingSlice(s, series: 1),
                  DSRingSlice(100 - s, series: 0),
                ],
                center: Text('${score.round()}%', style: DSText.h2),
              ),
              const SizedBox(height: 12),
              Text('${_result!['total']} questions', style: DSText.bodySm),
            ] else ...[
              const DSEmptyState(
                icon: DSIconName.done,
                title: 'Submitted',
                body: 'Your score will appear once your teacher releases it.',
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
          ]),
        ),
      ),
    ]));
  }

  Widget _buildQuiz(Repo repo) {
    return FutureBuilder<List<Json>>(
      future: repo.questions(widget.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final qs = snap.data!;
        if (_qi >= qs.length) _qi = qs.length - 1;
        final answered = qs.where(_answered).length;
        final q = qs[_qi];
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
                '${qs.length - answered} ${qs.length - answered == 1 ? 'question' : 'questions'} unanswered. Submit anyway?'),
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

        return MaxWidth(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Text('Question ${_qi + 1} of ${qs.length}', style: DSText.label),
            const SizedBox(width: 12),
            Expanded(
                child: DSProgressBar(
              value: answered / qs.length,
              size: DSProgressBarSize.sm,
            )),
          ]),
          const SizedBox(height: 12),
          DSQuizNav(
            count: qs.length,
            current: _qi,
            answered: [for (final qq in qs) _answered(qq)],
            onSelect: (i) => setState(() => _qi = i),
          ),
          const SizedBox(height: 12),
          DSQuizCard(
            tag: _typeLabel('${q['qtype']}'),
            title: Text('${q['prompt']}'),
            options: _options(q),
            footer: Text('$answered of ${qs.length} answered'),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
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
          ]),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_err!,
                  textAlign: TextAlign.center,
                  style: DSText.caption.copyWith(color: DSColors.error)),
            ),
        ]));
      },
    );
  }
}
