import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    void open(String title, Future<List<Json>> f, String Function(Json) a, String Function(Json) b) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ListPage(title: title, future: f, head: a, sub: b)));
    }

    final tiles = <(String, String, Color, VoidCallback)>[
      ('Flashcards', AppEmoji.flashcards, AppColors.purple,
          () => open('Flashcards', repo.flashcards(), (r) => r['front'], (r) => r['back'])),
      ('Formula Guide', AppEmoji.formulas, AppColors.teal,
          () => open('Formula Guide', repo.formulas(), (r) => r['title'], (r) => r['expression'])),
      ('Key Terms', AppEmoji.keyTerms, AppColors.orange,
          () => open('Key Terms', repo.keyTerms(), (r) => r['term'], (r) => r['definition'])),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Review Center')),
      body: MaxWidth(child: GridView.extent(
        padding: const EdgeInsets.all(16), maxCrossAxisExtent: 220, mainAxisSpacing: 12, crossAxisSpacing: 12,
        children: [
          for (final t in tiles)
            AppCard(
              color: pastelBg(context, t.$3),
              onTap: t.$4,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                EmojiIcon(t.$2, size: 52),
                const SizedBox(height: 8),
                Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      )),
    );
  }
}

class _ListPage extends StatelessWidget {
  final String title;
  final Future<List<Json>> future;
  final String Function(Json) head, sub;
  const _ListPage({required this.title, required this.future, required this.head, required this.sub});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: FutureBuilder<List<Json>>(
          future: future,
          builder: (_, snap) => AsyncView<List<Json>>(
            snap: snap,
            builder: (rows) => rows.isEmpty
                ? const EmptyState(icon: AppIcons.inbox, title: 'Nothing here yet', message: 'Check back soon.')
                : MaxWidth(child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(head(rows[i]), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(sub(rows[i])),
                ]),
              ),
            )),
          ),
        ),
      );
}
