import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// ScienceLearn Design System — typography tokens.
/// Rule: Lexend = headings / buttons / tabs / field labels.
///       Inter  = body text / inputs / captions.
/// Named styles match web/src/design-system/tokens/typography.css 1:1.
/// Sizes are the mobile set (auth title 24, body 16) — the web file carries
/// the desktop breakpoints.
abstract final class DSText {
  static TextStyle get display => GoogleFonts.lexend(
      fontSize: 56, fontWeight: FontWeight.w800, color: DSColors.ink, height: 0.95, letterSpacing: -0.5);
  static TextStyle get h1 => GoogleFonts.lexend(
      fontSize: 30, fontWeight: FontWeight.w800, color: DSColors.ink, height: 1.2, letterSpacing: -0.5);
  static TextStyle get h2 => GoogleFonts.lexend(
      fontSize: 24, fontWeight: FontWeight.w800, color: DSColors.ink, height: 1.25, letterSpacing: -0.6);
  static TextStyle get h3 => GoogleFonts.lexend(
      fontSize: 21, fontWeight: FontWeight.w800, color: DSColors.ink, height: 1.3);
  static TextStyle get title => GoogleFonts.lexend(
      fontSize: 16, fontWeight: FontWeight.w600, color: DSColors.ink, height: 1.35);
  static TextStyle get body => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w400, color: DSColors.ink, height: 1.55);
  static TextStyle get bodySm => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: DSColors.ink, height: 1.55);
  static TextStyle get label => GoogleFonts.lexend(
      fontSize: 13, fontWeight: FontWeight.w600, color: DSColors.ink, height: 1.3);
  static TextStyle get button => GoogleFonts.lexend(
      fontSize: 15, fontWeight: FontWeight.w700, color: DSColors.ink, height: 1);
  static TextStyle get caption => GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: DSColors.ink, height: 1.5);
}
