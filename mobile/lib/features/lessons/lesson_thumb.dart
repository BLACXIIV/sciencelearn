import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// Lesson thumbnail — resolves the R2 object key to a signed URL, then
/// renders DSThumbnail (falls back to the science icon when there is none).
class LessonThumb extends ConsumerWidget {
  final String? thumbKey;
  const LessonThumb({super.key, required this.thumbKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);
    if (thumbKey == null || thumbKey!.isEmpty) return const DSThumbnail();
    return FutureBuilder<String?>(
      future: repo.signedUrl(thumbKey),
      builder: (_, snap) => DSThumbnail(imageUrl: snap.data),
    );
  }
}
