// Widget smoke tests for shared UI (no Supabase/network needed).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sciencelearn/core/widgets.dart';
import 'package:sciencelearn/data/repository.dart';
import 'package:sciencelearn/features/shell.dart';

Widget _gateApp(Map<String, dynamic>? profile, {bool fail = false}) => ProviderScope(
      overrides: [
        meProvider.overrideWith(
            (ref) => fail ? throw Exception('offline') : Future.value(profile ?? const {})),
      ],
      child: const MaterialApp(home: RoleGate(child: Text('student app content'))),
    );

void main() {
  testWidgets('EmptyState shows title and message', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EmptyState(icon: Icons.inbox, title: 'Nothing here yet', message: 'Check back soon.')),
    ));
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Check back soon.'), findsOneWidget);
  });

  testWidgets('Bar clamps out-of-range values', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Bar(1.5))));
    final indicator = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(indicator.value, 1.0);
  });

  testWidgets('RoleGate admits students to the app', (WidgetTester tester) async {
    await tester.pumpWidget(_gateApp({'role': 'student', 'full_name': 'QA Student'}));
    await tester.pump();
    expect(find.text('student app content'), findsOneWidget);
  });

  testWidgets('RoleGate redirects teachers away from the student app', (WidgetTester tester) async {
    await tester.pumpWidget(_gateApp({'role': 'teacher', 'full_name': 'QA Teacher'}));
    await tester.pump();
    expect(find.text('student app content'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('RoleGate redirects admins too', (WidgetTester tester) async {
    await tester.pumpWidget(_gateApp({'role': 'admin'}));
    await tester.pump();
    expect(find.text('student app content'), findsNothing);
  });

  testWidgets('RoleGate fails closed when the profile cannot load', (WidgetTester tester) async {
    await tester.pumpWidget(_gateApp(null, fail: true));
    await tester.pump();
    expect(find.text("Couldn't load this right now"), findsOneWidget);
    expect(find.text('student app content'), findsNothing);
  });
}
