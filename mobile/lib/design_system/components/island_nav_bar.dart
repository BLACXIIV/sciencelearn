import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'icon.dart';
import 'nav_bar.dart';

/// IslandNavBar — floating white pill nav: radius 32, card edge, line
/// border, blue icon+label when active. Dock it via Scaffold.bottomNavigationBar
/// or a bottom-aligned Stack child; respects safe-area.
class DSIslandNavBar extends StatelessWidget {
  final List<DSNavItem> items;
  final String? active;
  final ValueChanged<String>? onSelect;

  const DSIslandNavBar({
    super.key,
    required this.items,
    this.active,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 560),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            padding: const EdgeInsets.all(DSSpacing.s2),
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: DSRadii.panelBr,
              border: Border.all(color: DSColors.line),
              boxShadow: dsEdge(DSColors.edgeCard, h: 5),
            ),
            child: Row(
              children: [
                for (final it in items)
                  Expanded(
                    child: _IslandItem(
                      item: it,
                      active: active == it.key,
                      onTap: () => onSelect?.call(it.key),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IslandItem extends StatelessWidget {
  final DSNavItem item;
  final bool active;
  final VoidCallback onTap;
  const _IslandItem(
      {required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? DSColors.blue : DSColors.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? DSColors.pastelBlue : Colors.transparent,
          borderRadius: DSRadii.buttonBr,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DSIcon(item.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(item.label,
                style: DSText.label.copyWith(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
