import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// AuthShell (mobile) — navy header + white sheet: the mobile counterpart of
/// the web split screen. The header holds brand + illustration; the body is a
/// white surface with 32px top radius holding the segmented control + form.
///
/// For a push-up sheet flow, pair this layout with showDSBottomSheet, which
/// provides the same chrome as a modal.
class DSAuthShell extends StatelessWidget {
  /// Navy header content — brand mark, illustration, sticker badges.
  final Widget header;

  /// Sheet body — segmented control + form.
  final Widget child;

  const DSAuthShell({super.key, required this.header, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.paper,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              DSSpacing.gutter,
              MediaQuery.paddingOf(context).top + DSSpacing.s5,
              DSSpacing.gutter,
              DSSpacing.s6,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [DSColors.navyDeep, DSColors.navy],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(DSRadii.panel)),
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: DSColors.surface),
              child: header,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(DSSpacing.gutter, DSSpacing.s5,
                  DSSpacing.gutter, DSSpacing.s5),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
