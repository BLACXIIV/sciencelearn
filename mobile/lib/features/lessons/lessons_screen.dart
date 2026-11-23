import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets.dart';
import '../../data/repository.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ref.watch(subjectProvider);
    final lessons = ref.watch(lessonsProvider);
    const subjects = [null, 'Physics', 'Chemistry', 'Earth Science'];

    return Scaffold(
      appBar: AppBar(title: const Text('My Lessons')),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              for (final s in subjects)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s ?? 'All'),
                    selected: subject == s,
                    onSelected: (_) => ref.read(subjectProvider.notifier).state = s,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: lessons.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (rows) => RefreshIndicator(
              onRefresh: () async => ref.refresh(lessonsProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final l = rows[i];
                  final lp = (l['lesson_progress'] as List?) ?? [];
                  final pct = lp.isEmpty ? 0 : (lp.first['percent'] as int);
                  return AppCard(
                    onTap: () => context.push('/lesson/${l['id']}'),
                    child: Row(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.science, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l['title'], style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('Objectives: ${l['objectives']}', maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Row(children: [Expanded(child: Bar(pct / 100)), const SizedBox(width: 8), Text('$pct%')]),
                        ]),
                      ),
                      const Icon(Icons.chevron_right),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
