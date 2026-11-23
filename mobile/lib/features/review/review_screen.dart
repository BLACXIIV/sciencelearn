import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final tiles = <(String, IconData, Color, VoidCallback)>[
      ('Flashcards', Icons.style, AppColors.purple,
          () => open('Flashcards', repo.flashcards(), (r) => r['front'], (r) => r['back'])),
      ('Formula Guide', Icons.functions, AppColors.teal,
          () => open('Formula Guide', repo.formulas(), (r) => r['title'], (r) => r['expression'])),
      ('Key Terms', Icons.lightbulb, AppColors.orange,
          () => open('Key Terms', repo.keyTerms(), (r) => r['term'], (r) => r['definition'])),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Review Center')),
      body: GridView.count(
        padding: const EdgeInsets.all(16), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
        children: [
          for (final t in tiles)
            AppCard(
              onTap: t.$4,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(t.$2, size: 44, color: t.$3),
                const SizedBox(height: 8),
                Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
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
                ? const EmptyState(icon: Icons.inbox_outlined, title: 'Nothing here yet', message: 'Check back soon.')
                : ListView.separated(
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
            ),
          ),
        ),
      );
}
