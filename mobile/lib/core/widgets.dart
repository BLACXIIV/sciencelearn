import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository.dart';
import '../design_system/design_system.dart';

/// Current user's avatar: R2 photo when set, initials tile otherwise.
class UserAvatar extends ConsumerWidget {
  final double radius;
  final DSAvatarPastel pastel;
  const UserAvatar({super.key, this.radius = 28, this.pastel = DSAvatarPastel.blue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).valueOrNull;
    final key = me?['avatar_url'] as String?;
    final name = (me?['full_name'] as String?)?.trim();
    final repo = ref.read(repoProvider);
    Widget avatar(String? url) => DSAvatar(
          name: (name == null || name.isEmpty) ? 'Me' : name,
          imageUrl: url,
          size: radius * 2,
          pastel: pastel,
        );
    if (key == null || key.isEmpty) return avatar(null);
    return FutureBuilder<String?>(
      future: repo.signedUrl(key),
      builder: (_, s) => avatar(s.data),
    );
  }
}

/// Caps content width and centers it when the window is wider than a phone
/// (tablet, desktop window). Transparent pass-through on narrow screens.
class MaxWidth extends StatelessWidget {
  final Widget child;
  final double max;
  const MaxWidth({super.key, required this.child, this.max = 640});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: max),
          child: child,
        ),
      );
}
