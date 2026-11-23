import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';

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

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final l in _enumCtrl.values) {
      for (final c in l) { c.dispose(); }
    }
    super.dispose();
  }

  bool _answered(Json q) {
    final a = _answers[q['id']];
    if (a == null) return false;
    if (a.containsKey('t')) return (a['t'] as String).trim().isNotEmpty;
    if (a.containsKey('items')) return (a['items'] as List).any((s) => (s as String).trim().isNotEmpty);
    return true;
  }

  Widget _input(Json q) {
    final id = q['id'] as String;
    switch (q['qtype'] as String? ?? 'multiple_choice') {
      case 'true_false':
        final sel = _answers[id]?['b'] as bool?;
        return Row(children: [
          for (final v in [true, false]) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Center(child: Text(v ? 'True' : 'False')),
                  selected: sel == v,
                  onSelected: (_) => setState(() => _answers[id] = {'b': v}),
                ),
              ),
            ),
          ],
        ]);
      case 'fill_blank':
      case 'identification':
        final c = _ctrl.putIfAbsent(id, () => TextEditingController());
        return TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'Your answer'),
          onChanged: (v) => _answers[id] = {'t': v},
        );
      case 'enumeration':
        final n = (q['meta'] as Map?)?['n'] as int? ?? 3;
        final ctrls = _enumCtrl.putIfAbsent(
            id, () => List.generate(n, (_) => TextEditingController()));
        return Column(children: [
          for (var i = 0; i < n; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: ctrls[i],
                decoration: InputDecoration(hintText: '${i + 1}.'),
                onChanged: (_) => _answers[id] = {
                  'items': ctrls.map((c) => c.text).toList()
                },
              ),
            ),
        ]);
      default: // multiple_choice
        final sel = _answers[id]?['i'] as int?;
        return RadioGroup<int>(
          groupValue: sel,
          onChanged: (v) => setState(() => _answers[id] = {'i': v}),
          child: Column(children: [
            for (var c = 0; c < (q['choices'] as List? ?? []).length; c++)
              RadioListTile<int>(value: c, title: Text('${(q['choices'] as List)[c]}')),
          ]),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repoProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _result != null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const EmojiIcon(AppEmoji.postTest, size: 88),
                Text('${_result!['score']}%', style: Theme.of(context).textTheme.displayMedium),
                Text('${_result!['total']} questions'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () { ref.invalidate(progressProvider); Navigator.of(context).pop(); },
                  child: const Text('Done'),
                ),
              ]),
            )
          : FutureBuilder<List<Json>>(
              future: repo.questions(widget.id),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final qs = snap.data!;
                final answered = qs.where(_answered).length;
                return ListView(padding: const EdgeInsets.all(16), children: [
                  for (var i = 0; i < qs.length; i++) ...[
                    Text('${i + 1}. ${qs[i]['prompt']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${qs[i]['qtype']}'.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    _input(qs[i]),
                    const Divider(height: 28),
                  ],
                  const SizedBox(height: 4),
                  Text('$answered of ${qs.length} answered',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: (_busy || answered < qs.length) ? null : () async {
                      setState(() => _busy = true);
                      final r = await repo.submit(widget.id, _answers);
                      setState(() { _result = r; _busy = false; });
                    },
                    child: _busy
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit Answers'),
                  ),
                ]);
              },
            ),
    );
  }
}
