import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'icon.dart';

/// EmptyState — pastel icon circle + title + body + optional action.
/// For empty lists, no-results, and first-run prompts.
class DSEmptyState extends StatelessWidget {
  final DSIconName icon;
  final String title;
  final String? body;
  final Widget? action;

  const DSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s5, vertical: DSSpacing.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: DSColors.pastelBlue,
              shape: BoxShape.circle,
            ),
            child: Center(child: DSIcon(icon, size: 28, color: DSColors.navy)),
          ),
          const SizedBox(height: DSSpacing.s3),
          Text(title, style: DSText.h3.copyWith(color: DSColors.navy), textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: DSSpacing.s3),
            Text(
              body!,
              style: DSText.bodySm.copyWith(color: DSColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: DSSpacing.s4),
            action!,
          ],
        ],
      ),
    );
  }
}
