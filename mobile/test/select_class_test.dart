import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sciencelearn/data/repository.dart';
import 'package:sciencelearn/design_system/design_system.dart';
import 'package:sciencelearn/features/classes/classes_screen.dart'
    show enrolledClassesProvider;
import 'package:sciencelearn/features/classes/select_class_screen.dart';

/// Classroom picker — the post-login gate. These tests pin the mockup's
/// key elements: navy header + role chip, class tiles with pastel icons,
/// pending lock, dashed ghost tiles, and Continue gating on a selection.
Widget _app(Map<String, dynamic> me, List<Override> overrides) => ProviderScope(
      overrides: [
        meProvider.overrideWith((ref) => Future.value(me)),
        ...overrides,
      ],
      child: const MaterialApp(home: SelectClassScreen()),
    );

final _enrolled = [
  {
    'class_id': 'c1',
    'status': 'active',
    'classes': {
      'name': 'Grade 7 – Diamond',
      'code': 'K4M2QR',
      'profiles': {'full_name': 'Ms. Aquino'},
    },
  },
  {
    'class_id': 'c2',
    'status': 'pending',
    'classes': {'name': 'Grade 8 – Ruby', 'code': 'R7VBKD', 'profiles': null},
  },
];

final _taught = [
  {
    'id': 't1',
    'name': 'Grade 7 – Sapphire',
    'code': 'Q9XTPL',
    'enrollments': [
      {'status': 'active'},
      {'status': 'pending'},
    ],
  },
];

void main() {
  testWidgets('student picker lists classes; Continue enables on selection',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app({
      'role': 'student',
      'full_name': 'Rhey Aguilar'
    }, [
      enrolledClassesProvider.overrideWith((ref) => Future.value(_enrolled)),
    ]));
    await tester.pumpAndSettle();

    // Header + list content matches the mockup.
    expect(find.text('Choose your classroom'), findsOneWidget);
    expect(find.text('STUDENT'), findsOneWidget);
    expect(find.text('Grade 7 – Diamond'), findsOneWidget);
    expect(find.text('Ms. Aquino'), findsOneWidget);
    expect(find.text('Grade 8 – Ruby'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Join with a class code'), findsOneWidget);

    // Continue is the gate: disabled until a class is selected.
    var cta =
        tester.widget<DSButton>(find.widgetWithText(DSButton, 'Continue'));
    expect(cta.disabled, isTrue);

    await tester.tap(find.text('Grade 7 – Diamond'));
    await tester.pump();

    cta = tester.widget<DSButton>(find.widgetWithText(DSButton, 'Continue'));
    expect(cta.disabled, isFalse);
    // Selection shows the mint corner-check from the mockup.
    expect(find.byIcon(DSIconName.check.data), findsOneWidget);

    // Pending rows stay locked — tapping one must not select it.
    await tester.tap(find.text('Grade 8 – Ruby'));
    await tester.pump();
    expect(find.byIcon(DSIconName.check.data), findsOneWidget);
  });

  testWidgets('teacher picker shows code chips, pending badge, create tile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app({
      'role': 'teacher',
      'full_name': 'Ms. Aquino'
    }, [
      teacherClassesProvider.overrideWith((ref) => Future.value(_taught)),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('TEACHER'), findsOneWidget);
    expect(find.text('Grade 7 – Sapphire'), findsOneWidget);
    expect(find.text('1 student'), findsOneWidget);
    expect(find.text('Q9XTPL'), findsOneWidget);
    expect(find.text('1 request'), findsOneWidget);
    expect(find.text('Create a new class'), findsOneWidget);
  });

  // The navy header carries absolute-positioned decoration — make sure it
  // never overflows the layout at a narrow width.
  testWidgets('picker lays out at narrow width without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app({
      'role': 'student',
      'full_name': 'Rhey'
    }, [
      enrolledClassesProvider.overrideWith((ref) => Future.value(_enrolled)),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Choose your classroom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
