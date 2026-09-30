import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF8B3A2E);
  static const primaryLight = Color(0xFFB35A46);
  static const dark = Color(0xFF2B2118);
  static const gray = Color(0xFF7A7168);
  static const success = Color(0xFF1E7A34);
  static const warning = Color(0xFFE0A800);
  static const danger = Color(0xFFC0392B);
  static const bg = Color(0xFFF7F3EE);
  static const surface = Colors.white;
}

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  fontFamily: GoogleFonts.poppins().fontFamily,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary, surface: AppColors.surface),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bg,
    foregroundColor: AppColors.dark,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.zero,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      elevation: 0,
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8E2DA))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
  ),
);