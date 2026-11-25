import 'package:flutter/material.dart';

/// ScienceLearn Design System — color tokens.
/// Canonical values copied from the Landing/Log in/Sign up screens
/// (previously core/tokens.dart SLColors). Self-contained layer; names match
/// web/src/design-system/tokens/colors.css 1:1 (--ds-* → camelCase).
abstract final class DSColors {
  // brand
  static const navy = Color(0xFF0A1A5C), navyDeep = Color(0xFF07124A);
  static const blue = Color(0xFF2F5BFF), blueDark = Color(0xFF1B3FC4);
  static const mint = Color(0xFF5EEAD4), sun = Color(0xFFFFC83D);
  static const paper = Color(0xFFF4F7FF);

  // pastels
  static const pastelBlue = Color(0xFFBFD0FF), pastelYellow = Color(0xFFFFE08A);
  static const pastelPurple = Color(0xFFD9CCFF), pastelMint = Color(0xFFA7F3E4);

  // neutrals
  static const ink = navy, inkSoft = Color(0xFF2B3466);
  static const muted = Color(0xFF5A6480), line = Color(0xFFDDE4F5);
  static const surface = Color(0xFFFFFFFF);

  // solid bottom-edge ("edge") colors — a darker shade of the fill above
  static const edgeCard = Color(0xFFC9CFEA);
  static const edgeWhite = Color(0xFF9FB4FF);
  static const edgeBlue = blueDark;
  static const edgeMint = Color(0xFF2BB5A0);
  static const edgeSun = Color(0xFFC99400);
  static const edgeSoft = Color(0xFFD5DEFF); // softer edge (island bar, panels)
  static const edgeNavy = navyDeep;
  static const edgeChip = Color(0x33000000); // sticker-chip drop (0,0,0,.2)

  // status
  static const success = Color(0xFF2BB5A0);
  static const warning = Color(0xFFF5A623);
  static const error = Color(0xFFD9483B);
  static const errorSurface = Color(0xFFFFD9D4);

  // progress track
  static const track = Color(0xFFE4E9FB);

  // chart series (canonical order: lessons, quizzes, pre-test, post-test) —
  // identical to --ds-chart-1..4 so web and mobile rings match.
  static const chart1 = Color(0xFFFFC83D);
  static const chart2 = Color(0xFF2F5BFF);
  static const chart3 = Color(0xFFF0759C);
  static const chart4 = Color(0xFF2ED3B7);
}
