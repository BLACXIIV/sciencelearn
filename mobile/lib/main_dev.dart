import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'design_system/ui_kit_screen.dart';

/// Debug-only entry: runs the design-system gallery instead of the app.
///   flutter run -t lib/main_dev.dart
/// The production entry (main.dart) is untouched.
void main() {
  runApp(const UiKitApp());
}

class UiKitApp extends StatelessWidget {
  const UiKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScienceLearn UI Kit',
      debugShowCheckedModeBanner: true,
      theme: buildDSTheme(),
      home: const UiKitScreen(),
    );
  }
}
