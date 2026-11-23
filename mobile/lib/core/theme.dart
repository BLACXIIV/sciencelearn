import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0C0F16);
  static const surface = Color(0xFF141926);
  static const surface2 = Color(0xFF1B2334);
  static const line = Color(0xFF262F45);
  static const text = Color(0xFFF1F4FA);
  static const muted = Color(0xFF8B93A7);
  static const blue = Color(0xFF4C8DFF);
  static const success = Color(0xFF3ECF8E);
  static const orange = Color(0xFFF5A623);
  static const purple = Color(0xFF9B7BFF);
  static const teal = Color(0xFF2ED3B7);
  static const pink = Color(0xFFF0759C);
  static const yellow = Color(0xFFF5C518);
}

/// Data-series palette: reserved for charts/rings, never chrome.
const kSeries = [
  AppColors.yellow,
  AppColors.blue,
  AppColors.pink,
  AppColors.muted,
  AppColors.teal,
];

/// Soft tinted background behind a colored icon on dark surfaces.
Color pastelBg(BuildContext context, Color c) => c.withValues(alpha: 0.16);

/// Rounded tinted icon container used on tiles, list rows, and stat cards.
Widget iconChip(BuildContext context, IconData icon, Color color,
        {double size = 42, double iconSize = 24}) =>
    Container(
      width: size, height: size,
      decoration: BoxDecoration(color: pastelBg(context, color), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: iconSize),
    );

ThemeData buildTheme(Brightness brightness) {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.blue,
    onPrimary: Colors.white,
    secondary: AppColors.teal,
    onSecondary: Colors.black,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    surfaceContainerHighest: AppColors.surface2,
    onSurfaceVariant: AppColors.muted,
    error: Color(0xFFF07575),
    onError: Colors.black,
    outline: AppColors.line,
    outlineVariant: AppColors.line,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    dividerColor: AppColors.line,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(color: AppColors.surface, elevation: 0),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.blue,
      circularTrackColor: AppColors.surface2,
      linearTrackColor: AppColors.surface2,
    ),
    snackBarTheme: const SnackBarThemeData(backgroundColor: AppColors.surface2),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
