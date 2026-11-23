import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository.dart';

class QuizRunnerScreen extends ConsumerStatefulWidget {
  final String id, title;
  const QuizRunnerScreen({super.key, required this.id, required this.title});
  @override
  ConsumerState<QuizRunnerScreen> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends ConsumerState<QuizRunnerScreen> {
  final Map<String, int> _answers = {};
  Json? _result;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repoProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _result != null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
                Text('${_result!['score']}%', style: Theme.of(context).textTheme.displayMedium),
                Text('${_result!['correct']} / ${_result!['total']} correct'),
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
                return ListView(padding: const EdgeInsets.all(16), children: [
                  for (var i = 0; i < qs.length; i++) ...[
                    Text('${i + 1}. ${qs[i]['prompt']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    RadioGroup<int>(
                      groupValue: _answers[qs[i]['id']],
                      onChanged: (v) => setState(() => _answers[qs[i]['id']] = v!),
                      child: Column(children: [
                        for (var c = 0; c < (qs[i]['choices'] as List).length; c++)
                          RadioListTile<int>(value: c, title: Text('${(qs[i]['choices'] as List)[c]}')),
                      ]),
                    ),
                    const Divider(),
                  ],
                  FilledButton(
                    onPressed: _busy ? null : () async {
                      setState(() => _busy = true);
                      final r = await repo.submit(widget.id, _answers);
                      setState(() { _result = r; _busy = false; });
                    },
                    child: const Text('Submit'),
                  ),
                ]);
              },
            ),
    );
  }
}
