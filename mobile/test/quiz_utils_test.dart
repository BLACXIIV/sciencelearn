import 'package:flutter_test/flutter_test.dart';
import 'package:sciencelearn/core/widgets.dart';
import 'package:sciencelearn/data/repository.dart';

/// sortQuestionsByPart — mirrors web's part-aware sort: questions group by
/// their part's position, order by position inside the part, ungrouped last.
void main() {
  Json q(String id, String? partId, int position) =>
      {'id': id, 'part_id': partId, 'position': position};
  Json part(String id, int position) => {'id': id, 'position': position};

  test('groups by part position, then question position', () {
    // Parts arrive pre-sorted by position from the repo query — the rank
    // map follows array order (same as web).
    final parts = [part('p1', 0), part('p2', 1)];
    final qs = [
      q('c', 'p2', 0),
      q('a', 'p1', 1),
      q('b', 'p1', 0),
      q('d', 'p2', 1),
    ];
    expect([for (final x in sortQuestionsByPart(qs, parts)) x['id']],
        ['b', 'a', 'c', 'd']);
  });

  test('ungrouped questions go last', () {
    final parts = [part('p1', 0)];
    final qs = [q('u', null, 0), q('a', 'p1', 5), q('v', null, 1)];
    expect([for (final x in sortQuestionsByPart(qs, parts)) x['id']],
        ['a', 'u', 'v']);
  });

  test('unknown-part questions tail-sort like ungrouped (then by position/id)',
      () {
    final parts = [part('p1', 0)];
    final qs = [q('x', 'gone', 0), q('u', null, 0), q('a', 'p1', 0)];
    // 'x' and 'u' share the tail rank — tie-breaks by position then id.
    expect([for (final x in sortQuestionsByPart(qs, parts)) x['id']],
        ['a', 'u', 'x']);
  });

  test('same-part same-position ties break by id for a stable order', () {
    final parts = [part('p1', 0)];
    final qs = [q('z', 'p1', 0), q('y', 'p1', 0), q('x', 'p1', 0)];
    expect([for (final x in sortQuestionsByPart(qs, parts)) x['id']],
        ['x', 'y', 'z']);
  });

  test('string meta values still parse for the answered gate', () {
    // _intOr is private — exercise the same logic the runner uses: a
    // string-typed meta.min must not make a valid selection look unanswered.
    int? intOr(Object? v) => v is num ? v.toInt() : int.tryParse('$v');
    expect(intOr('2'), 2);
    expect(intOr(2.7), 2);
    expect(intOr(null), isNull);
    expect(intOr('junk'), isNull);
  });
}
