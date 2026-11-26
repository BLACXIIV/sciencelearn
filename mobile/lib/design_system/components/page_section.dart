import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// PageSection — page body block: optional title row + content with the
/// standard gutter (20px) and vertical rhythm.
class DSPageSection extends StatelessWidget {
  final String? title;
  final Widget? aside;
  final Widget child;

  const DSPageSection({super.key, this.title, this.aside, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DSSpacing.gutter, DSSpacing.s5, DSSpacing.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || aside != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (title != null)
                  Expanded(
                      child: Text(title!,
                          style: DSText.h2.copyWith(fontSize: 21))),
                if (aside != null) aside!,
              ],
            ),
            const SizedBox(height: DSSpacing.s4),
          ],
          child,
        ],
      ),
    );
  }
}
