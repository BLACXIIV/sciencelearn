import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy = Color(0xFF0B2A6F);
  static const blue = Color(0xFF2563EB);
  static const bg = Color(0xFFF1F5FD);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFF59E0B);
  static const purple = Color(0xFF7C3AED);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
    );
