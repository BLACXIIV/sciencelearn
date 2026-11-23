import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One brightness's set of layout colors. Semantic accent colors stay global.
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.text,
    required this.muted,
  });
  final Color bg, surface, surface2, line, text, muted;
}

const darkPalette = AppPalette(
  bg: Color(0xFF0C0F16),
  surface: Color(0xFF141926),
  surface2: Color(0xFF1B2334),
  line: Color(0xFF262F45),
  text: Color(0xFFF1F4FA),
  muted: Color(0xFF8B93A7),
);

const lightPalette = AppPalette(
  bg: Color(0xFFEEF1F7),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFE6EAF2),
  line: Color(0xFFD4DBE8),
  text: Color(0xFF141A26),
  muted: Color(0xFF5C6678),
);

/// Accent presets — ids are persisted and shared with the web client.
class AccentDef {
  const AccentDef(this.id, this.label, this.hex, this.on);
  final String id, label;
  final Color hex, on;
}

const kAccents = [
  AccentDef('blue', 'Blue', Color(0xFF4C8DFF), Colors.white),
  AccentDef('purple', 'Purple', Color(0xFF9B7BFF), Colors.white),
  AccentDef('teal', 'Teal', Color(0xFF2ED3B7), Color(0xFF06201A)),
  AccentDef('green', 'Green', Color(0xFF3ECF8E), Color(0xFF062012)),
  AccentDef('orange', 'Orange', Color(0xFFF5A623), Color(0xFF241300)),
  AccentDef('pink', 'Pink', Color(0xFFF0759C), Color(0xFF2B0713)),
];

AccentDef accentById(String id) =>
    kAccents.firstWhere((a) => a.id == id, orElse: () => kAccents.first);

enum SurfaceStyle { flat, glass, neo, skeuo }

/// Mutable palette backing the whole app. Screens read colors through these
/// getters so a mode/accent switch repaints every AppColors.* reference.
class AppColors {
  static AppPalette _p = darkPalette;
  static AccentDef _accent = kAccents.first;
  static SurfaceStyle surfaceStyle = SurfaceStyle.flat;

  static void apply({required AppPalette palette, required AccentDef accent, SurfaceStyle? surface}) {
    _p = palette;
    _accent = accent;
    if (surface != null) surfaceStyle = surface;
  }

  static AppPalette get palette => _p;
  static AccentDef get accentDef => _accent;
  static Color get onAccent => _accent.on;

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surface2 => _p.surface2;
  static Color get line => _p.line;
  static Color get text => _p.text;
  static Color get muted => _p.muted;
  static Color get blue => _accent.hex;

  static const success = Color(0xFF3ECF8E);
  static const orange = Color(0xFFF5A623);
  static const purple = Color(0xFF9B7BFF);
  static const teal = Color(0xFF2ED3B7);
  static const pink = Color(0xFFF0759C);
  static const yellow = Color(0xFFF5C518);
  static const danger = Color(0xFFF07575);
}

/// Data-series palette: reserved for charts/rings, never chrome.
List<Color> get kSeries => [
      AppColors.yellow,
      AppColors.blue,
      AppColors.pink,
      AppColors.muted,
      AppColors.teal,
    ];

/// Soft tinted background behind a colored icon on themed surfaces.
Color pastelBg(BuildContext context, Color c) => c.withValues(alpha: 0.16);

/// Rounded tinted icon container used on tiles, list rows, and stat cards.
Widget iconChip(BuildContext context, IconData icon, Color color,
        {double size = 42, double iconSize = 24}) =>
    Container(
      width: size, height: size,
      decoration: BoxDecoration(color: pastelBg(context, color), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: iconSize),
    );

ThemeData buildTheme({AppPalette palette = darkPalette, AccentDef? accent}) {
  final a = accent ?? kAccents.first;
  final scheme = ColorScheme(
    brightness: palette == darkPalette ? Brightness.dark : Brightness.light,
    primary: a.hex,
    onPrimary: a.on,
    secondary: AppColors.teal,
    onSecondary: Colors.black,
    surface: palette.surface,
    onSurface: palette.text,
    surfaceContainerHighest: palette.surface2,
    onSurfaceVariant: palette.muted,
    error: AppColors.danger,
    onError: Colors.white,
    outline: palette.line,
    outlineVariant: palette.line,
  );
  final base = palette == darkPalette ? ThemeData.dark() : ThemeData.light();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.bg,
    dividerColor: palette.line,
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: palette.text, displayColor: palette.text),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bg,
      foregroundColor: palette.text,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(color: palette.surface, elevation: 0),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: a.hex,
      circularTrackColor: palette.surface2,
      linearTrackColor: palette.surface2,
    ),
    snackBarTheme: SnackBarThemeData(backgroundColor: palette.surface2),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: a.hex,
        foregroundColor: a.on,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        side: BorderSide(color: palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
