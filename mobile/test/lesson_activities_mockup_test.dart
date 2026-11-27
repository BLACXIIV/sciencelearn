// Mockup parity audit for LessonActivitiesScreen at 390pt — pumps the real
// screen with a fake repo and asserts the spec'd text styles, colors and
// geometry numerically (golden not used: google_fonts are runtime-fetched,
// so test rendering substitutes glyphs).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sciencelearn/data/repository.dart';
import 'package:sciencelearn/features/teacher/lesson_activities_screen.dart';

class _FakeRepo extends Repo {
  @override
  Future<Json> lesson(String id) async =>
      {'id': 'l1', 'title': 'ELABORATE — Reaction Detective'};

  @override
  Future<List<Json>> lessonAssessments(String lessonId) async => [
        {
          'id': 'a1',
          'title': 'Reaction Detective Quiz',
          'description': 'Classify each reaction type',
          'is_published': true,
          'release_scores': 'immediate',
          'scores_released': false,
          'questions': [
            {'count': 7}
          ],
        },
        {
          'id': 'a2',
          'title': 'Balancing Drill',
          'description': 'Balance the equations',
          'is_published': false,
          'release_scores': 'manual',
          'scores_released': false,
          'questions': [
            {'count': 0}
          ],
        },
      ];
}

void main() {
  // google_fonts can't runtime-fetch under flutter_test — register the
  // variable TTFs so layout/text metrics match the real app.
  // Lexend/Inter TTFs are bundled in assets/fonts/ — with runtime fetching
  // off, google_fonts resolves them from the asset manifest (real metrics).
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  TextStyle styleOf(WidgetTester t, String text) =>
      t.widget<Text>(find.text(text).first).style!;

  testWidgets('activities screen matches mockup spec at 390px',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(_FakeRepo())],
      child: const MaterialApp(
          home: LessonActivitiesScreen(
              lessonId: 'l1',
              lesson: {
                'id': 'l1',
                'title': 'ELABORATE — Reaction Detective'
              })),
    ));
    await tester.pumpAndSettle();

    // Layout proof — bundled fonts loaded, PNG reflects real metrics.
    await expectLater(
        find.byType(LessonActivitiesScreen),
        matchesGoldenFile('goldens/lesson_activities_390.png'));

    expect(tester.takeException(), isNull,
        reason: 'screen overflowed or threw at 390px');

    // "Activities" twice — header title Lexend 800 28 white + section
    // title Lexend 800 20.
    final titles = tester
        .widgetList<Text>(find.text('Activities'))
        .map((w) => w.style!)
        .toList();
    expect(
        titles.any((s) =>
            s.fontSize == 28 &&
            s.fontWeight == FontWeight.w800 &&
            s.color == const Color(0xFFFFFFFF)),
        isTrue);
    expect(
        titles.any(
            (s) => s.fontSize == 20 && s.fontWeight == FontWeight.w800),
        isTrue);

    // Count pill — pastel bg, navy Lexend 800 13.
    expect(styleOf(tester, '2').fontSize, 13);
    expect(styleOf(tester, '2').fontWeight, FontWeight.w800);

    // New activity — Lexend 800 14 navy.
    final newAct = styleOf(tester, 'New activity');
    expect(newAct.fontSize, 14);
    expect(newAct.fontWeight, FontWeight.w800);

    // Card title — Lexend 800 16.
    final cardTitle = styleOf(tester, 'Reaction Detective Quiz');
    expect(cardTitle.fontSize, 16);
    expect(cardTitle.fontWeight, FontWeight.w800);
    expect(
        tester.widget<Text>(find.text('Reaction Detective Quiz')).maxLines,
        2);

    // Footer buttons — Lexend 800 13 white / Inter 600 14 navy.
    final q = styleOf(tester, 'Questions');
    expect(q.fontSize, 13);
    expect(q.fontWeight, FontWeight.w800);
    expect(q.color, const Color(0xFFFFFFFF));
    final p = styleOf(tester, 'Preview');
    expect(p.fontSize, 14);
    expect(p.fontWeight, FontWeight.w600);

    // Switch labels — Inter 600 13.
    expect(styleOf(tester, 'Published').fontSize, 13);
    expect(styleOf(tester, 'Published').fontWeight, FontWeight.w600);
    expect(styleOf(tester, 'Draft').fontSize, 13);

    // Chips present in both states.
    expect(find.text('7 questions'), findsOneWidget);
    expect(find.text('0 questions'), findsOneWidget);
    expect(find.text('Instant scores'), findsOneWidget);
    expect(find.text('Manual release'), findsOneWidget);
    expect(find.text('Add questions to publish'), findsOneWidget);

    // Switch track is exactly 44x26 (SizedBox under the publish toggle).
    final track = find.byWidgetPredicate((w) =>
        w is SizedBox && w.width == 44 && w.height == 26);
    expect(track, findsNWidgets(2));
  });
}
