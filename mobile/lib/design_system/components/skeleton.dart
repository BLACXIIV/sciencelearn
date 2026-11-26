import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';

enum DSSkeletonShape { line, card, circle }

/// Skeleton — shimmer placeholder using track-color fills. Compose lines and
/// cards to mirror the layout being loaded. Respects reduced motion
/// (MediaQuery.disableAnimations → static fill).
class DSSkeleton extends StatefulWidget {
  final DSSkeletonShape shape;
  final double? width;
  final double? height;

  const DSSkeleton(
      {super.key, this.shape = DSSkeletonShape.line, this.width, this.height});

  @override
  State<DSSkeleton> createState() => _DSSkeletonState();
}

class _DSSkeletonState extends State<DSSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (w, h, radius) = switch (widget.shape) {
      DSSkeletonShape.line => (widget.width, widget.height ?? 14, DSRadii.pill),
      DSSkeletonShape.card => (
          widget.width ?? double.infinity,
          widget.height ?? 120,
          DSRadii.card
        ),
      DSSkeletonShape.circle => (
          widget.width ?? 44,
          widget.height ?? 44,
          999.0
        ),
    };
    final box = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: DSColors.track,
        borderRadius: widget.shape == DSSkeletonShape.circle
            ? null
            : BorderRadius.circular(radius),
        shape: widget.shape == DSSkeletonShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
      ),
    );
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return box;
    return FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.45).animate(_c), child: box);
  }
}
