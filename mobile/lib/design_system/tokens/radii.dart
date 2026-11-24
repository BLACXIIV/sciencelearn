import 'package:flutter/material.dart';

/// ScienceLearn Design System — corner radii. Fixed set, six values.
/// Names match web/src/design-system/tokens/radii.css (--ds-r-*).
abstract final class DSRadii {
  static const button = 16.0;
  static const input = 14.0;
  static const card = 22.0;
  static const panel = 32.0; // panels, sheets, header bottom corners
  static const chip = 14.0;
  static const pill = 999.0;

  static BorderRadius br(double r) => BorderRadius.circular(r);
  static BorderRadius get buttonBr => br(button);
  static BorderRadius get inputBr => br(input);
  static BorderRadius get cardBr => br(card);
  static BorderRadius get panelBr => br(panel);
  static BorderRadius get chipBr => br(chip);
  static BorderRadius get pillBr => br(pill);
}
