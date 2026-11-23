import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy = Color(0xFF0B2A6F);
  static const navyDark = Color(0xFF081B47);
  static const blue = Color(0xFF2563EB);
  static const bg = Color(0xFFF1F5FD);
  static const success = Color(0xFF15803D);
  static const orange = Color(0xFFD97706);
  static const purple = Color(0xFF7C3AED);
  static const teal = Color(0xFF0D9488);
}

/// Picks [light] or [dark] by the ambient brightness — for the few brand
/// accent colors used on cards/icons that ColorScheme roles don't cover.
Color adaptiveColor(BuildContext context, Color light, Color dark) =>
    Theme.of(context).brightness == Brightness.dark ? dark : light;

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: brightness,
  );
  final dark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? scheme.surface : AppColors.bg,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: brightness).textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.navyDark : AppColors.navy,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      circularTrackColor: scheme.surfaceContainerHighest,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
  );
}
