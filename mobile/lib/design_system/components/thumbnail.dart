import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import 'icon.dart';

/// Thumbnail — 64px rounded image tile (radius 14) with a track-colored
/// icon fallback. Used as the leading slot in DSListItemCard lesson rows.
class DSThumbnail extends StatelessWidget {
  /// Image URL. Falls back to the icon tile when absent or broken.
  final String? imageUrl;
  final DSIconName icon;
  final double size;

  const DSThumbnail({
    super.key,
    this.imageUrl,
    this.icon = DSIconName.science,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    Widget ph() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: DSColors.track, borderRadius: DSRadii.chipBr),
          child: DSIcon(icon, size: size * 0.45, color: DSColors.muted),
        );
    if (imageUrl == null || imageUrl!.isEmpty) return ph();
    return ClipRRect(
      borderRadius: DSRadii.chipBr,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => ph(),
        errorWidget: (_, __, ___) => ph(),
      ),
    );
  }
}
