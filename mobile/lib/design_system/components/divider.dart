import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// Divider — 1px DSColors.line rule, optionally with a centered muted
/// caption ("or", section titles).
class DSDivider extends StatelessWidget {
  final String? label;
  final double spacing;

  const DSDivider({super.key, this.label, this.spacing = 16});

  @override
  Widget build(BuildContext context) {
    final line = Container(height: 1, color: DSColors.line);
    if (label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: spacing),
        child: line,
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: Row(
        children: [
          Expanded(child: line),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!.toUpperCase(),
              style: DSText.caption.copyWith(
                color: DSColors.muted,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: line),
        ],
      ),
    );
  }
}
