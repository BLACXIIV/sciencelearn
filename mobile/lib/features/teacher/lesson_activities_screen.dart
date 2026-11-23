import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

/// Teacher activity builder for one lesson â€” mirrors web LessonActivities.
/// Manage assessments (kind, publish, delete) and per-type questions.
class LessonActivitiesScreen extends ConsumerStatefulWidget {
  final Json lesson;
  const LessonActivitiesScreen({super.key, required this.lesson});
  @override
  ConsumerState<LessonActivitiesScreen> createState() => _ActivitiesState();
}

class _ActivitiesState extends ConsumerState<LessonActivitiesScreen> {
  static const _kinds = {
    'pre_test': 'Pre-Test', 'post_test': 'Post-Test', 'topic_quiz': 'Topic Quiz',
    'problem_solving': 'Problem Solving', 'final_challenge': 'Final Challenge', 'practice': 'Practice',
  };
  static const _qtypes = {
    'multiple_choice': 'Multiple Choice',
    'true_false': 'True or False',
    'fill_blank': 'Fill in the Blank',
    'identification': 'Identification',
    'enumeration': 'Enumeration',
  };
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _kind = 'topic_quiz';
  String? _open; // expanded assessment id
  int _refresh = 0;

  Future<void> _createAssessment() async {
    if (_title.text.trim().isEmpty) return;
    final a = await ref.read(repoProvider)
        .createAssessment('${widget.lesson['id']}', _kind, _title.text.trim(), _desc.text.trim());
    _title.clear(); _desc.clear();
    setState(() { _open = a['id']; _refresh++; });
  }

  /// Per-type question editor sheet. Writes choices/correct_index or answer jsonb.
  Future<void> _editQuestion(String assessmentId, [Json? q]) async {
    String qtype = '${q?['qtype'] ?? 'multiple_choice'}';
    final prompt = TextEditingController(text: '${q?['prompt'] ?? ''}');
    final choices = [for (final c in (q?['choices'] as List? ?? ['', '', '', ''])) TextEditingController(text: '$c')];
    int correct = (q?['correct_index'] as num?)?.toInt() ?? 0;
    bool boolAnswer = q?['answer']?['correct'] == true;
    final accepted = [for (final a in (q?['answer']?['accepted'] as List? ?? [''])) TextEditingController(text: '$a')];
    final items = [for (final i in (q?['answer']?['items'] as List? ?? ['', '', ''])) TextEditingController(text: '$i')];
    bool ordered = q?['answer']?['ordered'] == true;
    bool partial = q?['answer']?['partial'] != false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        Widget listRows(List<TextEditingController> ctrls, String hint, {bool choices_ = false}) =>
            Column(children: [
              for (var i = 0; i < ctrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: TextField(controller: ctrls[i],
                        decoration: InputDecoration(hintText: '$hint ${i + 1}'))),
                    if (choices_) ...[
                      const SizedBox(width: 6),
                      ChoiceChip(label: const Text('correct'), selected: correct == i,
                          onSelected: (_) => setS(() => correct = i)),
                    ],
                    if (ctrls.length > (choices_ ? 2 : 1))
                      IconButton(icon: const Icon(AppIcons.delete, size: 18),
                          onPressed: () => setS(() => ctrls.removeAt(i))),
                  ]),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(AppIcons.add, size: 16),
                  label: Text('Add $hint'),
                  onPressed: () => setS(() => ctrls.add(TextEditingController())),
                ),
              ),
            ]);

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: qtype,
              decoration: const InputDecoration(labelText: 'Question type'),
              items: [for (final e in _qtypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setS(() => qtype = v ?? qtype),
            ),
            const SizedBox(height: 10),
            TextField(controller: prompt, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Prompt')),
            const SizedBox(height: 12),
            if (qtype == 'multiple_choice')
              listRows(choices, 'Choice', choices_: true),
            if (qtype == 'true_false')
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('True is correct')),
                  ButtonSegment(value: false, label: Text('False is correct')),
                ],
                selected: {boolAnswer},
                onSelectionChanged: (s) => setS(() => boolAnswer = s.first),
              ),
            if (qtype == 'fill_blank' || qtype == 'identification')
              listRows(accepted, 'Accepted answer'),
            if (qtype == 'enumeration') ...[
              listRows(items, 'Item'),
              CheckboxListTile(
                value: ordered, dense: true, contentPadding: EdgeInsets.zero,
                title: const Text('Order matters'),
                onChanged: (v) => setS(() => ordered = v ?? false),
              ),
              CheckboxListTile(
                value: partial, dense: true, contentPadding: EdgeInsets.zero,
                title: const Text('Partial credit per item'),
                onChanged: (v) => setS(() => partial = v ?? true),
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save question'),
              )),
              const SizedBox(width: 8),
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ]),
          ])),
        );
      }),
    );
    if (saved != true) return;

    final filledChoices = choices.map((c) => c.text.trim()).toList();
    final body = <String, dynamic>{
      'assessment_id': assessmentId,
      'qtype': qtype,
      'prompt': prompt.text.trim(),
      'position': (q?['position'] as num?)?.toInt() ?? 0,
      'choices': qtype == 'multiple_choice' ? filledChoices.where((c) => c.isNotEmpty).toList() : null,
      'correct_index': qtype == 'multiple_choice'
          ? filledChoices.sublist(0, correct).where((c) => c.isNotEmpty).length
          : null,
      'answer': switch (qtype) {
        'true_false' => {'correct': boolAnswer},
        'fill_blank' || 'identification' =>
          {'accepted': accepted.map((a) => a.text.trim()).where((a) => a.isNotEmpty).toList()},
        'enumeration' => {
            'items': items.map((i) => i.text.trim()).where((i) => i.isNotEmpty).toList(),
            'ordered': ordered, 'partial': partial,
          },
        _ => null,
      },
      if (q?['id'] != null) 'id': q!['id'],
    };
    await ref.read(repoProvider).upsertQuestion(body);
    setState(() => _refresh++);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(repoProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Activities: ${widget.lesson['title']}')),
      body: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('New activity', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [for (final e in _kinds.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          const SizedBox(height: 10),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description (optional)')),
          const SizedBox(height: 12),
          FilledButton(onPressed: _createAssessment, child: const Text('Create activity')),
        ])),
        const SizedBox(height: 16),
        FutureBuilder<List<Json>>(
          key: ValueKey(_refresh),
          future: repo.lessonAssessments('${widget.lesson['id']}'),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final rows = snap.data!;
            if (rows.isEmpty) {
              return const AppCard(child: EmptyState(
                  icon: AppIcons.assessment, title: 'No activities yet',
                  message: 'Create one above, then add questions.'));
            }
            return Column(children: [
              for (final a in rows)
                AppCard(child: Column(children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${a['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${_kinds[a['kind']] ?? a['kind']}${a['is_published'] == true ? ' Â· published' : ' Â· draft'}',
                          style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    ])),
                    IconButton(
                      icon: const Icon(AppIcons.delete, size: 18),
                      onPressed: () async {
                        await repo.deleteAssessment('${a['id']}');
                        setState(() => _refresh++);
                      },
                    ),
                  ]),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(spacing: 4, children: [
                      TextButton(
                        onPressed: () => setState(() => _open = _open == a['id'] ? null : '${a['id']}'),
                        child: Text(_open == a['id'] ? 'Close' : 'Questions'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await repo.setAssessmentPublished('${a['id']}', a['is_published'] != true);
                          setState(() => _refresh++);
                        },
                        child: Text(a['is_published'] == true ? 'Unpublish' : 'Publish'),
                      ),
                    ]),
                  ),
                  _ScoreRelease(
                    mode: '${a['release_scores'] ?? 'immediate'}',
                    released: a['scores_released'] == true,
                    repo: repo,
                    assessmentId: '${a['id']}',
                    onChanged: () => setState(() => _refresh++),
                  ),
                  if (_open == a['id'])
                    FutureBuilder<List<Json>>(
                      key: ValueKey('${a['id']}-$_refresh'),
                      future: repo.questionsFull('${a['id']}'),
                      builder: (context, qs) {
                        if (!qs.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(8), child: CircularProgressIndicator());
                        }
                        return Column(children: [
                          const Divider(),
                          for (var i = 0; i < qs.data!.length; i++)
                            ListTile(
                              dense: true, contentPadding: EdgeInsets.zero,
                              leading: Text('${i + 1}', style: TextStyle(color: AppColors.muted)),
                              title: Text('${qs.data![i]['prompt']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${qs.data![i]['qtype']}'.replaceAll('_', ' '),
                                  style: const TextStyle(fontSize: 11)),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(AppIcons.edit, size: 16),
                                    onPressed: () => _editQuestion('${a['id']}', qs.data![i])),
                                IconButton(icon: const Icon(AppIcons.delete, size: 16),
                                    onPressed: () async {
                                      await repo.deleteQuestion('${qs.data![i]['id']}');
                                      setState(() => _refresh++);
                                    }),
                              ]),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(AppIcons.add, size: 16),
                              label: const Text('Add question'),
                              onPressed: () => _editQuestion('${a['id']}'),
                            ),
                          ),
                        ]);
                      },
                    ),
                ])),
            ]);
          },
        ),
      ])),
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
  const _ScoreRelease({required this.mode, required this.released,
      required this.repo, required this.assessmentId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final manual = mode == 'manual';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(AppIcons.award, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              manual
                  ? (released ? 'Scores released' : 'Scores hidden until you release them')
                  : 'Students see scores right after submitting',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ]),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(spacing: 4, children: [
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () async {
                await repo.setScoreRelease(assessmentId, manual ? 'immediate' : 'manual');
                onChanged();
              },
              child: Text(manual ? 'Show after submit' : 'Release manually'),
            ),
            if (manual && !released)
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.orange),
                onPressed: () async {
                  await repo.releaseScores(assessmentId);
                  onChanged();
                },
                child: const Text('Release scores'),
              ),
          ]),
        ),
      ]),
    );
  }
}
