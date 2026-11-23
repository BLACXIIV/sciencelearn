import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repository.dart';

class LessonDetailScreen extends ConsumerWidget {
  final String id;
  const LessonDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: FutureBuilder<Json>(
        future: repo.lesson(id),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final l = snap.data!;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(l['title'], style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Objectives: ${l['objectives']}'),
            const Divider(height: 32),
            Text(l['content_md'] ?? ''),
            const SizedBox(height: 24),
            if (l['content_key'] != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open lesson material'),
                onPressed: () async {
                  final url = await repo.signedUrl(l['content_key']); // R2 signed URL
                  if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await repo.setProgress(id, 100);
                ref.invalidate(lessonsProvider);
                ref.invalidate(progressProvider);
                ref.invalidate(recentProvider);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Mark as completed'),
            ),
          ]);
        },
      ),
    );
  }
}
