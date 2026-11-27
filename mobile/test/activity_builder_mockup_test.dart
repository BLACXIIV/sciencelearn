// Mockup parity audit for ActivityBuilderScreen at 390pt — pumps the real
// screen with a fake repo and asserts the spec'd text styles, colors and
// geometry numerically. Golden PNG at goldens/activity_builder_390.png.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sciencelearn/data/repository.dart';
import 'package:sciencelearn/features/teacher/activity_builder_screen.dart';

class _FakeRepo extends Repo {
  /// Parts inserted via the UI, in call order — lets tests assert the
  /// position a new part requested.
  final List<Json> insertedParts = [];

  @override
  Future<void> upsertPart(Json p) async {
    if (p['id'] == null) insertedParts.add(Map.of(p));
  }

  @override
  Future<void> reorderPartPositions(List<String> orderedIds) async {}

  @override
  Future<Json> assessment(String id) async => {
        'id': 'a1',
        'title': 'EVALUATE - ASSESSING YOUR LEARNING',
        'description': 'Check understanding of reactions',
        'is_published': true,
        'release_scores': 'immediate',
        'scores_released': false,
      };

  @override
  Future<List<Json>> parts(String assessmentId) async => [
        {
          'id': 'p1',
          'assessment_id': 'a1',
          'title': 'Reaction Detective',
          'directions': 'Read each situation carefully.',
          'mode': 'multiple_choice',
          'scored': true,
          'points': 1,
          'position': 1,
        },
        {
          'id': 'p2',
          'assessment_id': 'a1',
          'title': 'Balance It',
          'directions': '',
          'mode': 'fill_blank',
          'scored': true,
          'points': 2,
          'position': 2,
        },
      ];

  @override
  Future<List<Json>> questionsFull(String assessmentId) async => [
        {
          'id': 'q1',
          'assessment_id': 'a1',
          'part_id': 'p1',
          'qtype': 'multiple_choice',
          'prompt': 'Which of these is a chemical reaction?',
          'position': 1,
          'choices': ['Rusting iron', 'Melting ice'],
          'correct_index': 0,
        },
        {
          'id': 'q2',
          'assessment_id': 'a1',
          'part_id': 'p1',
          'qtype': 'fill_blank',
          'prompt': 'Water is made of hydrogen and ___.',
          'position': 2,
          'answer': {'accepted': ['oxygen']},
        },
      ];
}

void main() {
  // Lexend/Inter TTFs are bundled in assets/fonts/ — with runtime fetching
  // off, google_fonts resolves them from the asset manifest (real metrics).
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  TextStyle styleOf(WidgetTester t, String text) =>
      t.widget<Text>(find.text(text).first).style!;

  testWidgets('builder screen matches mockup spec at 390px',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(_FakeRepo())],
      child: const MaterialApp(
          home: ActivityBuilderScreen(assessmentId: 'a1')),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'screen overflowed or threw at 390px');

    // Title split — "EVALUATE - ASSESSING YOUR LEARNING" →
    // "Evaluate" Lexend 800 28 white + uppercase Inter 14 onNavy subtitle.
    final title = styleOf(tester, 'Evaluate');
    expect(title.fontSize, 28);
    expect(title.fontWeight, FontWeight.w800);
    expect(title.color, const Color(0xFFFFFFFF));
    final sub = styleOf(tester, 'ASSESSING YOUR LEARNING');
    expect(sub.fontSize, 14);
    expect(sub.color, const Color(0xFFDCE4FF));

    // Counts line — Inter 14 onNavy, real counts.
    expect(find.text('2 parts · 2 questions'), findsOneWidget);
    expect(styleOf(tester, '2 parts · 2 questions').color,
        const Color(0xFFDCE4FF));

    // Header publish label — Lexend 800 14 white.
    final pub = styleOf(tester, 'Published');
    expect(pub.fontSize, 14);
    expect(pub.fontWeight, FontWeight.w800);
    expect(pub.color, const Color(0xFFFFFFFF));

    // Release chip — Lexend 800 13 white.
    final rel = styleOf(tester, 'Instant scores');
    expect(rel.fontSize, 13);
    expect(rel.fontWeight, FontWeight.w800);
    expect(rel.color, const Color(0xFFFFFFFF));

    // Part chips — always "Part N", Lexend 800 14.
    final chip = styleOf(tester, 'Part 2');
    expect(chip.fontSize, 14);
    expect(chip.fontWeight, FontWeight.w800);
    expect(find.text('Activity 1'), findsNothing);
    expect(find.text('+ Add part'), findsOneWidget);

    // Part card header + Scored label (Inter 600 12 navy). 'Part 1'
    // appears on the chip (14) AND the card header (18) — assert both.
    final part1s = tester
        .widgetList<Text>(find.text('Part 1'))
        .map((w) => w.style!.fontSize)
        .toList();
    expect(part1s, containsAll(<double>[14, 18]));
    final scored = styleOf(tester, 'Scored');
    expect(scored.fontSize, 12);
    expect(scored.fontWeight, FontWeight.w600);

    // Field labels — Inter 600 13.
    for (final l in ['Title', 'Points', 'Mode', 'Directions']) {
      final s = styleOf(tester, l);
      expect(s.fontSize, 13, reason: l);
      expect(s.fontWeight, FontWeight.w600, reason: l);
    }

    // Questions heading — 18 + "Hold and drag" Inter 12 note.
    expect(styleOf(tester, 'Questions').fontSize, 18);
    final drag = styleOf(tester, 'Hold and drag');
    expect(drag.fontSize, 12);
    expect(drag.color, const Color(0xFF3B4A8F));

    // Type chips — UPPERCASE Lexend 800 10.
    expect(find.text('MULTIPLE CHOICE'), findsOneWidget);
    expect(find.text('FILL IN THE BLANK'), findsOneWidget);
    final tc = styleOf(tester, 'MULTIPLE CHOICE');
    expect(tc.fontSize, 10);
    expect(tc.fontWeight, FontWeight.w800);

    // Prompt — Inter 600 13.
    final prompt = styleOf(
        tester, 'Which of these is a chemical reaction?');
    expect(prompt.fontSize, 13);
    expect(prompt.fontWeight, FontWeight.w600);

    // Answer hint stays — Inter 12 note.
    expect(find.textContaining('Answer:'), findsAtLeastNWidgets(1));

    // Bottom bar — Preview Inter 600 15 navy, Add question Lexend 800 16.
    final prev = styleOf(tester, 'Preview');
    expect(prev.fontSize, 15);
    expect(prev.fontWeight, FontWeight.w600);
    expect(prev.color, const Color(0xFF0A1A5C));
    final add = styleOf(tester, 'Add question');
    expect(add.fontSize, 16);
    expect(add.fontWeight, FontWeight.w800);

    // 44x26 compact switches — publish + scored.
    final track = find.byWidgetPredicate((w) =>
        w is SizedBox && w.width == 44 && w.height == 26);
    expect(track, findsNWidgets(2));

    // Golden — real fonts render the full mockup layout.
    await expectLater(find.byType(ActivityBuilderScreen),
        matchesGoldenFile('goldens/activity_builder_390.png'));
  });

  testWidgets('question editor answer rows match spec at 390px',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(_FakeRepo())],
      child: const MaterialApp(
          home: ActivityBuilderScreen(assessmentId: 'a1')),
    ));
    await tester.pumpAndSettle();

    // Selected part is multiple_choice → sheet opens straight onto a
    // 4-choice MC form (no type picking).
    await tester.tap(find.text('Add question'));
    await tester.pumpAndSettle();

    // Sheet header at open — "Question 3" (next slot in part 1, which
    // holds 2 questions) + MULTIPLE CHOICE chip + X. No type picker.
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/question_editor_open.png'));
    expect(find.text('Question 3'), findsOneWidget);
    expect(find.text('MULTIPLE CHOICE'), findsAtLeastNWidgets(1));
    expect(find.text('Question type'), findsNothing);

    // Helper line under the Choices label — Inter 12 note.
    final helper = styleOf(tester,
        'Tap the circle for the correct answer. Hold the dots to reorder.');
    expect(helper.fontSize, 12);
    expect(helper.color, const Color(0xFF3B4A8F));

    // Choice field finders — descend into each keyed field container so
    // select/prompt fields can't shift the indices.
    Finder fieldOf(int i) => find.descendant(
        of: find.byKey(ValueKey('ans-choice-$i')),
        matching: find.byType(TextField));

    // (a) four one-line choices.
    final shorts = [
      'A color change that was not there before',
      'Ice melting in a glass',
      'Sugar dissolving in warm water',
      'Paper being folded',
    ];
    for (var i = 0; i < 4; i++) {
      await tester.enterText(fieldOf(i), shorts[i]);
    }
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('ans-choice-3')));
    await tester.pumpAndSettle();

    // Field widths — spec target ≈250px at 390pt (grip 20 + marker 44 +
    // remove inside). Report measured values.
    for (var i = 0; i < 4; i++) {
      final s = tester
          .getSize(find.byKey(ValueKey('ans-choice-$i')));
      // ignore: avoid_print
      print('FIELD[$i] w=${s.width} h=${s.height}');
      expect(s.width, inInclusiveRange(200, 290),
          reason: 'choice field $i width');
    }
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/question_editor_1line.png'));

    // (b) one ~80-character choice — wraps, no clip.
    await tester.enterText(fieldOf(1),
        'A color change that was not there before, like a nail turning orange with rust');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('ans-choice-3')));
    await tester.pumpAndSettle();
    final h80 = tester
        .getSize(find.byKey(const ValueKey('ans-choice-1')))
        .height;
    // ignore: avoid_print
    print('FIELD[1] 80-char h=$h80');
    expect(h80, greaterThan(60), reason: '80-char choice must wrap');
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/question_editor_80char.png'));

    // (c) a 150-character choice — grows taller still.
    await tester.enterText(fieldOf(1),
        'A chemical reaction that happens when iron metal is left outside in the rain and the air for a very long time, slowly turning orange-brown and flaky');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.byKey(const ValueKey('ans-choice-3')));
    await tester.pumpAndSettle();
    final h150 = tester
        .getSize(find.byKey(const ValueKey('ans-choice-1')))
        .height;
    // ignore: avoid_print
    print('FIELD[1] 150-char h=$h150');
    expect(h150, greaterThan(h80),
        reason: '150-char choice must grow taller than the 80-char one');
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/question_editor_150char.png'));
  });

  testWidgets('new part appends after existing parts (position max+1)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _FakeRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(repo)],
      child: const MaterialApp(
          home: ActivityBuilderScreen(assessmentId: 'a1')),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('+ Add part'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.ancestor(
            of: find.text('e.g. Activity 1 — Reaction Detective'),
            matching: find.byType(TextField)),
        'Electricity Basics');
    await tester.tap(find.text('Save part'));
    await tester.pumpAndSettle();

    expect(repo.insertedParts, hasLength(1));
    // Existing positions are 1 and 2 — the new part must land at 3, i.e.
    // AFTER everything, never before part 1.
    expect(repo.insertedParts.single['position'], 3,
        reason: 'new part must append after existing positions, not lead');
  });
}
