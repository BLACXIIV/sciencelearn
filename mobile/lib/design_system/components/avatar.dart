import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

enum DSAvatarPastel { blue, yellow, purple, mint }

/// Avatar — circular image or pastel initials tile with a line border.
/// Initials are up to two letters from [name]; falls back on image error.
class DSAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final DSAvatarPastel pastel;

  const DSAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.pastel = DSAvatarPastel.blue,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (pastel) {
      DSAvatarPastel.blue => DSColors.pastelBlue,
      DSAvatarPastel.yellow => DSColors.pastelYellow,
      DSAvatarPastel.purple => DSColors.pastelPurple,
      DSAvatarPastel.mint => DSColors.pastelMint,
    };
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials =
        parts.take(2).map((w) => w.isEmpty ? '' : w[0]).join().toUpperCase();

    return Semantics(
      label: name,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: DSColors.line, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(initials),
              )
            : _initials(initials),
      ),
    );
  }

  Widget _initials(String initials) => Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: DSText.label.copyWith(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
            color: DSColors.navy,
          ),
        ),
      );
}
