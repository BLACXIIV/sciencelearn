import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// PageHeader — navy band with 32px rounded bottom corners (the mobile hero
/// shape, reused as a page top). White content; place titles/actions inside.
class DSPageHeader extends StatelessWidget {
  final Widget child;
  final bool compact;

  const DSPageHeader({super.key, required this.child, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        DSSpacing.gutter,
        compact ? DSSpacing.s5 : DSSpacing.s6,
        DSSpacing.gutter,
        compact ? DSSpacing.s5 : DSSpacing.s6,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DSColors.navy, DSColors.navyDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(DSRadii.panel)),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: DSColors.surface),
        child: child,
      ),
    );
  }
}
