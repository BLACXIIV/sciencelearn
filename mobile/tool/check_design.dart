// Design-system gate for the Flutter app.
// Pages and features may not contain raw colors, font families, border
// radii or box shadows — those live only in lib/design_system/.
// Exits 1 and prints every violation found outside design_system/.
//
// Run: dart run tool/check_design.dart

import 'dart:io';

final rules = <(String, RegExp)>[
  ('raw color', RegExp(r'Color\(0x')),
  ('raw font', RegExp(r'GoogleFonts\.')),
  ('raw radius', RegExp(r'BorderRadius\.circular\(')),
  ('raw shadow', RegExp(r'BoxShadow\(')),
];

void main() {
  final lib = Directory('lib');
  final findings = <String>[];
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.contains('design_system')) continue;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      for (final (name, re) in rules) {
        if (re.hasMatch(lines[i])) {
          findings.add(
              '${entity.path}:${i + 1}  [$name] ${lines[i].trim()}');
        }
      }
    }
  }

  if (findings.isNotEmpty) {
    stderr.writeln('Design-system violations (${findings.length}):\n');
    findings.forEach(stderr.writeln);
    stderr.writeln(
        '\nPages/features may only use DSColors/DSText/DSRadii/dsEdge and DS'
        ' widgets. If a needed style does not exist, add it to'
        ' lib/design_system/.');
    exit(1);
  }
  stdout.writeln(
      'Design-system check passed - no raw styling outside design_system/.');
}
