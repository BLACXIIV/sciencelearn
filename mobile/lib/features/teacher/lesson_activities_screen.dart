import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Teacher activity builder for one lesson — mirrors web LessonActivities.
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
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _kind = 'topic_quiz';
  String? _open; // expanded assessment id
  int _refresh = 0;

  @override
  void dispose() { _title.dispose(); _desc.dispose(); super.dispose(); }

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

    final saved = await showDSBottomSheet<bool>(
      context,
      child: StatefulBuilder(builder: (ctx, setS) {
        Widget listRows(List<TextEditingController> ctrls, String hint) =>
            Column(children: [
              for (var i = 0; i < ctrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(child: DSTextField(
                      label: '$hint ${i + 1}',
                      controller: ctrls[i],
                    )),
                    if (ctrls.length > (hint == 'Choice' ? 2 : 1))
                      DSIconButton(
                        icon: DSIconName.delete,
                        label: 'Remove',
                        size: 36,
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
                  onPressed: () => setS(() => ctrls.add(TextEditingController())),
                  child: Text('Add $hint'),
                ),
              ),
            ]);

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DSSelect(
              label: 'Question type',
              value: qtype,
              options: const [
                DSSelectOption('multiple_choice', 'Multiple Choice'),
                DSSelectOption('true_false', 'True or False'),
                DSSelectOption('fill_blank', 'Fill in the Blank'),
                DSSelectOption('identification', 'Identification'),
                DSSelectOption('enumeration', 'Enumeration'),
              ],
              onChanged: (v) => setS(() => qtype = v ?? qtype),
            ),
            const SizedBox(height: 10),
            DSTextArea(label: 'Prompt', controller: prompt, minLines: 2),
            const SizedBox(height: 12),
            if (qtype == 'multiple_choice') ...[
              Text('Choices — pick the correct one:',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              listRows(choices, 'Choice'),
              const SizedBox(height: 8),
              DSSelect(
                label: 'Correct choice',
                value: '$correct',
                options: [
                  for (var i = 0; i < choices.length; i++)
                    DSSelectOption('$i', 'Choice ${i + 1}'),
                ],
                onChanged: (v) => setS(() => correct = int.tryParse(v ?? '0') ?? 0),
              ),
            ],
            if (qtype == 'true_false')
              DSSegmentedControl(
                options: const [
                  DSSegment('true', 'True'),
                  DSSegment('false', 'False'),
                ],
                value: boolAnswer ? 'true' : 'false',
                onChanged: (v) => setS(() => boolAnswer = v == 'true'),
              ),
            if (qtype == 'fill_blank' || qtype == 'identification') ...[
              Text('Accepted answers — matching ignores case and surrounding spaces:',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              listRows(accepted, 'Answer'),
            ],
            if (qtype == 'enumeration') ...[
              Text('Expected items:',
                  style: DSText.caption.copyWith(color: DSColors.muted)),
              const SizedBox(height: 8),
              listRows(items, 'Item'),
              DSCheckbox(
                label: 'Order matters — items must appear in this order',
                value: ordered,
                onChanged: (v) => setS(() => ordered = v),
              ),
              DSCheckbox(
                label: 'Partial credit — score each correct item, otherwise all-or-nothing',
                value: partial,
                onChanged: (v) => setS(() => partial = v),
              ),
            ],
            const SizedBox(height: 12),
            DSButton(
              fullWidth: true,
              child: const Text('Save question'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ])),
        );
      }),
    );
    if (saved != true) return;

    final filled = choices.map((c) => c.text.trim()).where((c) => c.isNotEmpty).toList();
    await ref.read(repoProvider).upsertQuestion({
      if (q != null) 'id': q['id'],
      'assessment_id': assessmentId,
      'qtype': qtype,
      'prompt': prompt.text.trim(),
      'position': q?['position'] ?? 0,
      'choices': qtype == 'multiple_choice' ? filled : null,
      'correct_index': qtype == 'multiple_choice'
          ? choices.take(correct).where((c) => c.text.trim().isNotEmpty).length
          : null,
      'answer': qtype == 'true_false' ? {'correct': boolAnswer}
          : qtype == 'fill_blank' || qtype == 'identification'
              ? {'accepted': accepted.map((a) => a.text.trim()).where((a) => a.isNotEmpty).toList()}
              : qtype == 'enumeration'
                  ? {'items': items.map((i) => i.text.trim()).where((i) => i.isNotEmpty).toList(),
                     'ordered': ordered, 'partial': partial}
                  : null,
    });
    setState(() => _refresh++);
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDSModal<bool>(
      context,
      title: title,
      body: Text(body, style: DSText.body),
      actions: [
        DSButton(
          variant: DSButtonVariant.ghost,
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
              Expanded(child: Text('Activities: ${widget.lesson['title']}', style: DSText.h2)),
            ]),
          ),
        ),
        Expanded(child: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [
          DSCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('New activity', style: DSText.title),
            const SizedBox(height: 10),
            DSSelect(
              label: 'Type',
              value: _kind,
              options: [for (final e in _kinds.entries) DSSelectOption(e.key, e.value)],
              onChanged: (v) => setState(() => _kind = v ?? _kind),
            ),
            const SizedBox(height: 10),
            DSTextField(label: 'Title', controller: _title),
            const SizedBox(height: 10),
            DSTextField(label: 'Description (optional)', controller: _desc),
            const SizedBox(height: 12),
            DSButton(onPressed: _createAssessment, child: const Text('Create activity')),
          ])),
          const SizedBox(height: 16),
          FutureBuilder<List<Json>>(
            key: ValueKey(_refresh),
            future: repo.lessonAssessments('${widget.lesson['id']}'),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final rows = snap.data!;
              if (rows.isEmpty) {
                return const DSCard(child: DSEmptyState(
                    icon: DSIconName.assessment, title: 'No activities yet',
                    body: 'Create one above, then add questions.'));
              }
              return Column(children: [
                for (final a in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DSCard(child: Column(children: [
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${a['title']}', style: DSText.title),
                          Text('${_kinds[a['kind']] ?? a['kind']}${a['is_published'] == true ? ' · published' : ' · draft'}',
                              style: DSText.caption.copyWith(color: DSColors.muted)),
                        ])),
                        DSButton(
                          variant: DSButtonVariant.outline,
                          size: DSButtonSize.sm,
                          onPressed: () => setState(() => _open = _open == a['id'] ? null : '${a['id']}'),
                          child: Text(_open == a['id'] ? 'Close' : 'Questions'),
                        ),
                        const SizedBox(width: 4),
                        DSButton(
                          variant: DSButtonVariant.outline,
                          size: DSButtonSize.sm,
                          onPressed: () async {
                            await repo.setAssessmentPublished('${a['id']}', a['is_published'] != true);
                            setState(() => _refresh++);
                          },
                          child: Text(a['is_published'] == true ? 'Unpublish' : 'Publish'),
                        ),
                        DSIconButton(
                          icon: DSIconName.delete,
                          label: 'Delete activity',
                          size: 36,
                          onPressed: () async {
                            if (await _confirm('Delete activity?',
                                'This removes "${a['title']}" and its questions.')) {
                              await repo.deleteAssessment('${a['id']}');
                              setState(() => _refresh++);
                            }
                          },
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
                        FutureBuilder<List<Json>>(
                          key: ValueKey('${a['id']}-$_refresh'),
                          future: repo.questionsFull('${a['id']}'),
                          builder: (context, qs) {
                            if (!qs.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(8), child: CircularProgressIndicator());
                            }
                            return Column(children: [
                              const DSDivider(),
                              for (var i = 0; i < qs.data!.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: DSListItemCard(
                                    leading: Text('${i + 1}', style: DSText.label),
                                    title: Text('${qs.data![i]['prompt']}',
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text('${qs.data![i]['qtype']}'.replaceAll('_', ' ')),
                                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                      DSIconButton(
                                        icon: DSIconName.edit,
                                        label: 'Edit',
                                        size: 36,
                                        onPressed: () => _editQuestion('${a['id']}', qs.data![i]),
                                      ),
                                      DSIconButton(
                                        icon: DSIconName.delete,
                                        label: 'Delete question',
                                        size: 36,
                                        onPressed: () async {
                                          if (await _confirm('Delete question?',
                                              '"${qs.data![i]['prompt']}"')) {
                                            await repo.deleteQuestion('${qs.data![i]['id']}');
                                            setState(() => _refresh++);
                                          }
                                        },
                                      ),
                                    ]),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: DSButton(
                                  variant: DSButtonVariant.outline,
                                  size: DSButtonSize.sm,
                                  leadingIcon: DSIconName.add,
                                  onPressed: () => _editQuestion('${a['id']}'),
                                  child: const Text('Add question'),
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
  const _ScoreRelease({required this.mode, required this.released,
      required this.repo, required this.assessmentId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final manual = mode == 'manual';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        const DSIcon(DSIconName.award, size: 14, color: DSColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            manual
                ? (released ? 'Scores released' : 'Scores hidden until you release them')
                : 'Students see scores right after submitting',
            style: DSText.caption.copyWith(color: DSColors.muted),
          ),
        ),
        DSButton(
          variant: DSButtonVariant.ghost,
          size: DSButtonSize.sm,
          onPressed: () async {
            await repo.setScoreRelease(assessmentId, manual ? 'immediate' : 'manual');
            onChanged();
          },
          child: Text(manual ? 'Show after submit' : 'Release manually'),
        ),
        if (manual && !released)
          DSButton(
            size: DSButtonSize.sm,
            onPressed: () async {
              await repo.releaseScores(assessmentId);
              onChanged();
            },
            child: const Text('Release scores'),
          ),
      ]),
    );
  }
}
