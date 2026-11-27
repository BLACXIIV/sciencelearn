import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/typography.dart';
import 'icon.dart';

/// DSDashedBox — wraps a child in the web's `border: 2px dashed edge-white`
/// look. Flutter's `Border` can't dash, so the stroke is segmented along the
/// rounded-rect path by [_DashedRRectPainter]. Used by [DSFilePicker] and
/// any "add new" tiles (e.g. the dashed + Subject card).
class DSDashedBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;
  final EdgeInsets padding;

  const DSDashedBox({
    super.key,
    required this.child,
    this.color = DSColors.edgeWhite,
    this.radius = DSRadii.input,
    this.strokeWidth = 2,
    this.dash = 6,
    this.gap = 4,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dash: dash,
        gap: gap,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// DSFilePicker — dashed 2px edge-white tile (radius 14) for picking one
/// file. Mirrors the web FileDropZone: 44px pastel icon tile, label + hint
/// until a file is picked, then file name + "Tap to replace" + a remove ×.
///
/// The dashed border comes from [DSDashedBox]. The caller owns the actual
/// pick (openFile/file_selector stays in the screen, not the DS).
class DSFilePicker extends StatelessWidget {
  final DSIconName icon;
  final String label;
  final String hint;
  /// Picked file name — when set, the row shows it + a remove ×.
  final String? fileName;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const DSFilePicker({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.fileName,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final picked = fileName != null;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: DSDashedBox(
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: DSRadii.inputBr,
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DSColors.pastelBlue,
                  borderRadius: DSRadii.smBr,
                ),
                child: Center(
                    child: DSIcon(icon, size: 20, color: DSColors.ink)),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName ?? label,
                      style: DSText.label.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(picked ? 'Tap to replace' : hint,
                      style:
                          DSText.caption.copyWith(color: DSColors.muted)),
                ],
              )),
              if (picked)
                GestureDetector(
                  onTap: onClear,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: DSIcon(DSIconName.close,
                          size: 18, color: DSColors.muted),
                    ),
                  ),
                )
              else
                Text('Browse',
                    style: DSText.label
                        .copyWith(fontSize: 13, color: DSColors.blue)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded-rect stroke — segments a solid stroke along the RRect
/// path so container borders can look like the web's `border: dashed`.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 2,
    this.dash = 6,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
            Offset.zero & size, Radius.circular(radius))
        .deflate(strokeWidth / 2);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final len = math.min(dash, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap;
}
