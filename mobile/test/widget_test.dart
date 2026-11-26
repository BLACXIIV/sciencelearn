// Widget smoke tests for shared UI (no Supabase/network needed).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sciencelearn/data/repository.dart';
import 'package:sciencelearn/design_system/design_system.dart';
import 'package:sciencelearn/features/landing/landing_screen.dart';
import 'package:sciencelearn/features/shell.dart';

Widget _gateApp(Map<String, dynamic>? profile, {bool fail = false}) =>
    ProviderScope(
      overrides: [
        meProvider.overrideWith((ref) => fail
            ? throw Exception('offline')
            : Future.value(profile ?? const {})),
      ],
      child:
          const MaterialApp(home: RoleGate(child: Text('student app content'))),
    );

void main() {
  testWidgets('DSEmptyState shows title and body', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DSEmptyState(
          icon: DSIconName.inbox,
          title: 'Nothing here yet',
          body: 'Check back soon.',
        ),
      ),
    ));
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Check back soon.'), findsOneWidget);
  });

  testWidgets('DSProgressBar clamps out-of-range values',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DSProgressBar(value: 1.5))));
    final fill =
        tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(fill.widthFactor, 1.0);
  });

  testWidgets('RoleGate admits students to the app',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(_gateApp({'role': 'student', 'full_name': 'QA Student'}));
    await tester.pump();
    expect(find.text('student app content'), findsOneWidget);
  });

  testWidgets('RoleGate redirects teachers away from the student app',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(_gateApp({'role': 'teacher', 'full_name': 'QA Teacher'}));
    await tester.pump();
    expect(find.text('student app content'), findsNothing);
    expect(find.byType(DSLoadingIndicator), findsOneWidget);
  });

  testWidgets('RoleGate redirects admins too', (WidgetTester tester) async {
    await tester.pumpWidget(_gateApp({'role': 'admin'}));
    await tester.pump();
    expect(find.text('student app content'), findsNothing);
  });

  testWidgets('RoleGate fails closed when the profile cannot load',
      (WidgetTester tester) async {
    await tester.pumpWidget(_gateApp(null, fail: true));
    await tester.pump();
    expect(find.text("Couldn't load this right now"), findsOneWidget);
    expect(find.text('student app content'), findsNothing);
  });

  // DSIslandNavBar lives in Scaffold.bottomNavigationBar — a slot that hands
  // it the full body height and width. It must keep its own pill size (stay
  // docked at the bottom) and never exceed the screen's width.
  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('DSIslandNavBar stays docked at $size',
        (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const Text('body'),
          bottomNavigationBar: DSIslandNavBar(
            active: 'home',
            onSelect: (_) {},
            items: const [
              DSNavItem('home', 'Home', DSIconName.home),
              DSNavItem('classes', 'Classes', DSIconName.students),
              DSNavItem('progress', 'Progress', DSIconName.progress),
              DSNavItem('account', 'Account', DSIconName.account),
            ],
          ),
        ),
      ));

      final bar = tester.getRect(find.byType(DSIslandNavBar));
      // bottom edge sits at the bottom of the window
      expect(bar.bottom, closeTo(size.height, 1));
      // pill keeps its natural height, never expands to fill the screen
      expect(bar.height, lessThan(120));
      // all items fit inside the screen width (no right-edge overflow)
      expect(bar.left, greaterThanOrEqualTo(-1));
      expect(bar.right, lessThanOrEqualTo(size.width + 1));
      // body gets real space, not squeezed to zero
      expect(tester.getSize(find.text('body')).height, greaterThan(0));
    });
  }

  // RenderFlex overflows surface as test failures — the landing page must
  // reflow on a narrow phone instead of spilling off the edge.
  testWidgets('Landing screen lays out at narrow width without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    expect(find.text('ScienceLearn'), findsWidgets);
    expect(find.text('Start learning'), findsOneWidget);
  });
}
