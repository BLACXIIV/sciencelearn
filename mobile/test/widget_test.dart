// Widget smoke tests for shared UI (no Supabase/network needed).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sciencelearn/core/widgets.dart';

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
}
