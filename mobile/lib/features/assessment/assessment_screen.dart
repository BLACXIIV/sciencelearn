import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

class AssessmentScreen extends ConsumerWidget {
  const AssessmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    return Scaffold(
      body: Column(children: [
        DSPageHeader(
          compact: true,
          child: SafeArea(
            bottom: false,
            child: Text('Assessment center', style: DSText.h2),
          ),
        ),
        Expanded(
            child: FutureBuilder<({List<Json> rows, Map<String, num> scores})>(
          future: (() async => (
                rows: await repo.assessments([
                  'pre_test',
                  'post_test',
                  'topic_quiz',
                  'problem_solving',
                  'final_challenge'
                ]),
                scores: await repo.myAttemptScores(),
              ))(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const DSEmptyState(
                icon: DSIconName.offline,
                title: "Couldn't load this right now",
                body: 'Check your connection and try again.',
              );
            }
            if (!snap.hasData) {
              return const Center(child: DSLoadingIndicator());
            }
            final scores = snap.data!.scores;
            final rows = snap.data!.rows;
            final tests = rows
                .where(
                    (a) => a['kind'] == 'pre_test' || a['kind'] == 'post_test')
                .toList();
            final quizzes = rows
                .where(
                    (a) => a['kind'] != 'pre_test' && a['kind'] != 'post_test')
                .toList();
            return MaxWidth(
                child: ListView(padding: const EdgeInsets.all(16), children: [
              // Pre/Post as the mockup's two pastel hero tiles.
              if (tests.isNotEmpty)
                Row(children: [
                  for (final a in tests) ...[
                    Expanded(child: _TestTile(a: a)),
                    if (a != tests.last) const SizedBox(width: 10),
                  ],
                ]),
              if (tests.isNotEmpty) const SizedBox(height: 18),
              Text('Quizzes & exercises', style: DSText.title),
              const SizedBox(height: 8),
              if (quizzes.isEmpty)
                const DSCard(
                    child: DSEmptyState(
                        icon: DSIconName.assessment,
                        title: 'No quizzes published yet')),
              for (final a in quizzes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DSListItemCard(
                    onTap: () => context.push(
                        '/quiz/${a['id']}?t=${Uri.encodeComponent(a['title'])}'),
                    leading: DSIcon(_icon(a['kind']),
                        size: 22, color: DSColors.blue),
                    title: Text('${a['title']}'),
                    subtitle: Row(children: [
                      DSChip(child: Text(_label('${a['kind']}'))),
                      const SizedBox(width: 6),
                      Flexible(child: Text('${a['description'] ?? ''}')),
                    ]),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (scores.containsKey('${a['id']}'))
                        DSBadge(
                            tone: DSBadgeTone.mint,
                            child: Text('${scores['${a['id']}']!.round()}%')),
                      const SizedBox(width: 6),
                      const DSIcon(DSIconName.chevron, color: DSColors.muted),
                    ]),
                  ),
                ),
            ]));
          },
        )),
      ]),
    );
  }

  DSIconName _icon(String kind) => switch (kind) {
        'pre_test' => DSIconName.preTest,
        'post_test' => DSIconName.postTest,
        'problem_solving' => DSIconName.puzzle,
        'final_challenge' => DSIconName.award,
        _ => DSIconName.quiz,
      };

  String _label(String kind) => switch (kind) {
        'pre_test' => 'Pre-test',
        'post_test' => 'Post-test',
        'problem_solving' => 'Exercise',
        'final_challenge' => 'Final',
        'practice' => 'Practice',
        _ => 'Quiz',
      };
}

class _TestTile extends StatelessWidget {
  final Json a;
  const _TestTile({required this.a});

  @override
  Widget build(BuildContext context) {
    final isPre = a['kind'] == 'pre_test';
    return GestureDetector(
      onTap: () =>
          context.push('/quiz/${a['id']}?t=${Uri.encodeComponent(a['title'])}'),
      child: DSCard(
        variant: DSCardVariant.pastel,
        pastel: isPre ? DSCardPastel.blue : DSCardPastel.yellow,
        tilt: true,
        child: Column(children: [
          DSIcon(isPre ? DSIconName.preTest : DSIconName.postTest,
              size: 36, color: DSColors.navy),
          const SizedBox(height: 6),
          Text(isPre ? 'Pre-test' : 'Post-test', style: DSText.title),
          Text(isPre ? 'Before learning' : 'After learning',
              style: DSText.caption),
        ]),
      ),
    );
  }
}
