import 'package:flutter/material.dart';

/// ScienceLearn Design System — corner radii. Fixed scale.
/// Names match web/src/design-system/tokens/radii.css (--ds-r-*).
abstract final class DSRadii {
  static const sm = 12.0; // small controls, menu items
  static const input = 14.0;
  static const button = 16.0;
  static const tile = 18.0; // tiles, empty slots
  static const row = 20.0; // list rows
  static const card = 24.0;
  static const strip = 28.0; // navy strips, report headers
  static const sheet = 30.0; // bottom sheets
  static const panel = 32.0; // panels, header bottom corners
  static const pill = 99.0;
  static const chip = input; // legacy alias — small chips/icon tiles

  static BorderRadius br(double r) => BorderRadius.circular(r);
  static BorderRadius get smBr => br(sm);
  static BorderRadius get inputBr => br(input);
  static BorderRadius get buttonBr => br(button);
  static BorderRadius get tileBr => br(tile);
  static BorderRadius get rowBr => br(row);
  static BorderRadius get cardBr => br(card);
  static BorderRadius get stripBr => br(strip);
  static BorderRadius get sheetBr => br(sheet);
  static BorderRadius get panelBr => br(panel);
  static BorderRadius get pillBr => br(pill);
  static BorderRadius get chipBr => br(chip);
}
