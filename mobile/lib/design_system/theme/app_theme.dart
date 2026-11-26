import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/typography.dart';

/// ScienceLearn Design System — ThemeData built ONLY from DS tokens.
/// Even stock widgets (TextField, FilledButton, Chip, dialogs) land on the
/// design language. Body/inputs/captions are Inter; headings/labels Lexend —
/// this intentionally overrides the legacy app-wide Lexend text theme.
ThemeData buildDSTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: DSColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: DSColors.blue,
      primary: DSColors.blue,
      secondary: DSColors.mint,
      surface: DSColors.surface,
      error: DSColors.error,
    ),
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    displayLarge: DSText.display,
    displayMedium: DSText.display.copyWith(fontSize: 48),
    headlineLarge: DSText.h1,
    headlineMedium: DSText.h2,
    headlineSmall: DSText.h3,
    titleLarge: DSText.title.copyWith(fontSize: 18),
    titleMedium: DSText.title,
    titleSmall: DSText.label,
    labelLarge: DSText.button,
    labelMedium: DSText.label,
    bodyLarge: DSText.body,
    bodyMedium: DSText.bodySm,
    bodySmall: DSText.caption,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: DSRadii.inputBr,
    borderSide: const BorderSide(color: DSColors.line),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: DSColors.paper,
      foregroundColor: DSColors.ink,
      elevation: 0,
      titleTextStyle: DSText.title.copyWith(fontSize: 18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DSColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: DSText.bodySm.copyWith(color: DSColors.muted),
      hintStyle: DSText.bodySm.copyWith(color: DSColors.muted),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: DSColors.blue, width: 2),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: DSColors.error),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: DSColors.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DSColors.blue,
        foregroundColor: DSColors.surface,
        minimumSize: const Size(64, 48),
        textStyle: DSText.button,
        shape: RoundedRectangleBorder(borderRadius: DSRadii.buttonBr),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DSColors.blue,
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: DSColors.line),
        textStyle: DSText.button,
        shape: RoundedRectangleBorder(borderRadius: DSRadii.buttonBr),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: DSColors.surface,
      selectedColor: DSColors.pastelBlue,
      labelStyle: DSText.label.copyWith(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: DSRadii.pillBr),
      side: const BorderSide(color: DSColors.line),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DSColors.surface,
      shape: RoundedRectangleBorder(borderRadius: DSRadii.cardBr),
      titleTextStyle: DSText.h3,
      contentTextStyle: DSText.bodySm,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: DSColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(DSRadii.panel)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: DSColors.ink,
      contentTextStyle: DSText.bodySm.copyWith(color: DSColors.surface),
      shape: RoundedRectangleBorder(borderRadius: DSRadii.cardBr),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: DSColors.blue,
      linearTrackColor: DSColors.track,
      circularTrackColor: DSColors.track,
    ),
  );
}
