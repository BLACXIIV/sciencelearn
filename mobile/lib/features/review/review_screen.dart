import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/bento.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    void open(String title, Future<List<Json>> f, String Function(Json) a,
        String Function(Json) b,
        {bool flashcards = false}) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _ListPage(
              title: title,
              future: f,
              head: a,
              sub: b,
              flashcards: flashcards)));
    }

    final tiles = <(String, DSIconName, DSCardPastel, VoidCallback)>[
      (
        'Flashcards',
        DSIconName.review,
        DSCardPastel.purple,
        () => open('Flashcards', repo.flashcards(), (r) => r['front'],
            (r) => r['back'],
            flashcards: true)
      ),
      (
        'Formula guide',
        DSIconName.formulas,
        DSCardPastel.mint,
        () => open('Formula guide', repo.formulas(), (r) => r['title'],
            (r) => r['expression'])
      ),
      (
        'Key terms',
        DSIconName.keyTerms,
        DSCardPastel.yellow,
        () => open('Key terms', repo.keyTerms(), (r) => r['term'],
            (r) => r['definition'])
      ),
    ];
    return Scaffold(
      body: Column(children: [
        DSPageHeader(
          compact: true,
          child: SafeArea(
            bottom: false,
            child: Text('Review center', style: DSText.h2),
          ),
        ),
        Expanded(
            child: MaxWidth(
                child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BentoGrid(
              minWidth: 220,
              gap: 12,
              fit: true,
              children: [
                for (final t in tiles)
                  GestureDetector(
                    onTap: t.$4,
                    child: DSCard(
                      variant: DSCardVariant.pastel,
                      pastel: t.$3,
                      tilt: true,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DSIcon(t.$2, size: 36, color: DSColors.navy),
                            const SizedBox(height: 8),
                            Text(t.$1, style: DSText.title),
                          ]),
                    ),
                  ),
              ],
            ),
          ],
        ))),
      ]),
    );
  }
}

class _ListPage extends StatelessWidget {
  final String title;
  final Future<List<Json>> future;
  final String Function(Json) head, sub;
  final bool flashcards;
  const _ListPage(
      {required this.title,
      required this.future,
      required this.head,
      required this.sub,
      this.flashcards = false});
  @override
  Widget build(BuildContext context) => Scaffold(
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
                Expanded(child: Text(title, style: DSText.h2)),
              ]),
            ),
          ),
          Expanded(
              child: KeepDataFutureBuilder<List<Json>>(
            future: future,
            builder: (_, snap) {
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
              final rows = snap.data!;
              if (rows.isEmpty) {
                return const DSEmptyState(
                    icon: DSIconName.inbox,
                    title: 'Nothing here yet',
                    body: 'Check back soon.');
              }
              return MaxWidth(
                  child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => flashcards
                    ? DSFlashcard(
                        front: Text(head(rows[i])),
                        back: Text(sub(rows[i])),
                      )
                    : DSListItemCard(
                        title: Text(head(rows[i])),
                        subtitle: Text(sub(rows[i])),
                      ),
              ));
            },
          )),
        ]),
      );
}
