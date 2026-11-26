import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

/// The one navy bleed header used on every class-portal screen: gradient
/// card running under the status bar (bottom corners only), title row with
/// switch-class/account tiles, mint copyable code chip + join-policy pill,
/// and the decorative dashed ring bleeding off the top-right corner.
///
/// [leading]/[title]/[subtitle] let pushed screens (e.g. the student report)
/// keep a back affordance and an entity title while staying uniform.
class ClassHeroHeader extends StatelessWidget {
  final Json cls;
  final Widget? leading;
  final String? title;
  final String? subtitle;

  const ClassHeroHeader({
    super.key,
    required this.cls,
    this.leading,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Transparent status bar + light icons — the navy hero shows through it
    // instead of Android's dark scrim strip.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DSColors.navyDeep, DSColors.navy],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          // The 8px edge is a bottom border INSIDE the rect — a boxShadow
          // would overflow into the scroll view and get painted over.
          border: Border(
            bottom: BorderSide(color: DSColors.edgeNavy, width: 8),
          ),
        ),
        // ClipRRect lets the dashed ring bleed past the card edge while
        // still clipping it to the rounded shape; padding lives in the Stack.
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(30)),
          child: Stack(children: [
            const Positioned(
              top: -45,
              right: -55,
              child: CustomPaint(
                size: Size(170, 170),
                painter: DashedRingPainter(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.paddingOf(context).top + 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title ?? '${cls['name'] ?? 'Class'}',
                              style: DSText.h1.copyWith(
                                  fontSize: 28, color: DSColors.surface),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: DSText.caption
                                    .copyWith(color: DSColors.pastelBlue),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      HeroTile(
                        icon: DSIconName.school,
                        label: 'Switch class',
                        onTap: () {
                          // Clearing the notifier re-gates the router back
                          // to the picker.
                          currentClass.value = null;
                          classPicked.value = false;
                          context.go('/select-class');
                        },
                      ),
                      const SizedBox(width: 10),
                      HeroTile(
                        icon: DSIconName.account,
                        label: 'Account',
                        onTap: () => context.push('/teacher/account'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Wrap so the join-policy pill drops under the chip on
                  // narrow screens instead of overflowing the row.
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    HeroCodeChip(code: '${cls['code'] ?? ''}'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: DSRadii.pillBr,
                      ),
                      child: Text(
                        cls['join_policy'] == 'approval'
                            ? 'Approval required'
                            : 'Instant join',
                        style: DSText.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: DSColors.pastelBlue),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Mint chunky code chip — tap copies the class code.
class HeroCodeChip extends StatelessWidget {
  final String code;
  const HeroCodeChip({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Class code copied')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DSColors.mint,
          borderRadius: DSRadii.smBr,
          boxShadow: dsEdge(DSColors.edgeMint, h: 4),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            code,
            style: DSText.label.copyWith(
                fontSize: 15, letterSpacing: 1.8, color: DSColors.navy),
          ),
          const SizedBox(width: 8),
          const DSIcon(DSIconName.copy, size: 15, color: DSColors.navy),
        ]),
      ),
    );
  }
}

/// White rounded tile with a navy icon — hero actions on the navy panel.
class HeroTile extends StatelessWidget {
  final DSIconName icon;
  final String label;
  final VoidCallback onTap;
  const HeroTile(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DSColors.surface,
            borderRadius: DSRadii.inputBr,
            boxShadow: dsEdge(DSColors.edgeWhite, h: 4),
          ),
          child: Center(child: DSIcon(icon, size: 22, color: DSColors.navy)),
        ),
      ),
    );
  }
}

/// Decorative broken circle bleeding off the hero's top-right corner.
class DashedRingPainter extends CustomPainter {
  const DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.22);
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width / 2 - 2);
    const dashes = 14;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.65, false, paint);
    }
  }

  @override
  bool shouldRepaint(DashedRingPainter old) => false;
}
