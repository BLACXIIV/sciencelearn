import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'icon.dart';

class DSNavItem {
  final String key;
  final String label;
  final DSIconName icon;
  const DSNavItem(this.key, this.label, this.icon);
}

/// NavBar — the navy rail/top bar. On mobile it renders as a compact top
/// row (brand + icon items); the mobile product uses DSIslandNavBar for
/// primary navigation — NavBar exists for parity with the web DS layer.
class DSNavBar extends StatelessWidget {
  final Widget brand;
  final List<DSNavItem> items;
  final String? active;
  final ValueChanged<String>? onSelect;
  final Widget? trailing;

  const DSNavBar({
    super.key,
    required this.brand,
    required this.items,
    this.active,
    this.onSelect,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.s3, vertical: DSSpacing.s2),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [DSColors.navy, DSColors.navyDeep],
        ),
      ),
      child: Row(
        children: [
          DefaultTextStyle.merge(
            style: DSText.title.copyWith(color: DSColors.surface),
            child: brand,
          ),
          const SizedBox(width: DSSpacing.s3),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final it in items)
                    Padding(
                      padding: const EdgeInsets.only(right: DSSpacing.s2),
                      child: _NavItem(item: it, active: active == it.key, onTap: () => onSelect?.call(it.key)),
                    ),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final DSNavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? DSColors.blue : Colors.transparent,
          borderRadius: DSRadii.buttonBr,
          boxShadow: active ? dsEdge(DSColors.edgeBlue, h: 4) : const [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DSIcon(item.icon, size: 20, color: active ? DSColors.surface : DSColors.pastelBlue),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: DSText.label.copyWith(
                fontSize: 11,
                color: active ? DSColors.surface : DSColors.pastelBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
