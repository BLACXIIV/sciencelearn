import 'package:flutter/material.dart';

/// Elastic "bento" card grid — the mobile counterpart of the web app's
/// `design-system/layout/bento.css` rule.
///
/// Children wrap into rows sized so each gets at least [minWidth]; every
/// row shares its width equally, so a lone child on the last row stretches
/// full width — no dead space beside it. Cards re-arrange themselves when
/// the available width changes.
///
/// With [fit] set, a partial last row keeps column width instead — for
/// tile galleries where a lone stretched card looks wrong (web `.bento-fit`).
class BentoGrid extends StatelessWidget {
  /// Cards to lay out.
  final List<Widget> children;

  /// Minimum width a card keeps before wrapping to the next row.
  final double minWidth;

  /// Horizontal + vertical gap between cards.
  final double gap;

  /// Keep column width on a partial last row instead of stretching.
  final bool fit;

  const BentoGrid({
    super.key,
    required this.children,
    this.minWidth = 300,
    this.gap = 16,
    this.fit = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = (c.maxWidth / minWidth)
          .floor()
          .clamp(1, children.isEmpty ? 1 : children.length);
      final colW = (c.maxWidth - gap * (cols - 1)) / cols;
      final rows = <List<Widget>>[
        for (var i = 0; i < children.length; i += cols)
          children.sublist(
              i, (i + cols) > children.length ? children.length : i + cols),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows[r].length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    fit && rows[r].length < cols
                        ? SizedBox(width: colW, child: rows[r][i])
                        : Expanded(child: rows[r][i]),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}
