import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository.dart';
import '../design_system/design_system.dart';

/// Current user's avatar: R2 photo when set, initials tile otherwise.
class UserAvatar extends ConsumerWidget {
  final double radius;
  final DSAvatarPastel pastel;
  const UserAvatar(
      {super.key, this.radius = 28, this.pastel = DSAvatarPastel.blue});

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
    return KeepDataFutureBuilder<String?>(
      future: repo.signedUrl(key),
      builder: (_, s) => avatar(s.data),
    );
  }
}

/// Formats a point value without trailing zeros: 7 → "7", 2.5 → "2.5".
String fmtPts(num? v) {
  if (v == null) return '—';
  return v == v.roundToDouble() ? '${v.round()}' : '$v';
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

/// Part-aware question order — positions are per-part, so a flat order by
/// position interleaves parts. Groups by part position, orders by question
/// position inside each part; ungrouped items last. Mirrors web
/// src/utils/quiz.ts sortQuestionsByPart.
List<Json> sortQuestionsByPart(List<Json> questions, List<Json> parts) {
  final rank = <String, int>{};
  for (var i = 0; i < parts.length; i++) {
    rank['${parts[i]['id']}'] = i;
  }
  const tail = 1 << 30;
  int keyOf(Json q) =>
      q['part_id'] != null ? (rank['${q['part_id']}'] ?? tail) : tail;
  final sorted = [...questions];
  sorted.sort((a, b) {
    final ka = keyOf(a), kb = keyOf(b);
    if (ka != kb) return ka - kb;
    final pa = (a['position'] as num?)?.toInt() ?? 0;
    final pb = (b['position'] as num?)?.toInt() ?? 0;
    if (pa != pb) return pa - pb;
    return '${a['id']}'.compareTo('${b['id']}');
  });
  return sorted;
}

/// Drop-in FutureBuilder that keeps the last loaded data on screen while a
/// new future resolves — CRUD refetches update in place instead of flashing
/// the loading branch. First load behaves exactly like FutureBuilder;
/// errors still surface normally.
class KeepDataFutureBuilder<T> extends StatefulWidget {
  const KeepDataFutureBuilder(
      {super.key, required this.future, required this.builder});
  final Future<T>? future;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot)
      builder;

  @override
  State<KeepDataFutureBuilder<T>> createState() =>
      _KeepDataFutureBuilderState<T>();
}

class _KeepDataFutureBuilderState<T> extends State<KeepDataFutureBuilder<T>> {
  T? _last;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
      future: widget.future,
      builder: (context, snap) {
        if (snap.hasData) _last = snap.data;
        final effective = (!snap.hasData && !snap.hasError && _last != null)
            ? AsyncSnapshot<T>.withData(snap.connectionState, _last as T)
            : snap;
        return widget.builder(context, effective);
      });
}
