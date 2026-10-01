import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Colores mejorados tipo Tony's Pizza House
  static const primary = Color(0xFFC41E24);
  static const primaryLight = Color(0xFFE8454A);
  static const dark = Color(0xFF2D2420);
  static const gray = Color(0xFF8B7E74);
  static const lightGray = Color(0xFFB8AFA6);
  static const success = Color(0xFF27AE60);
  static const warning = Color(0xFFF39C12);
  static const danger = Color(0xFFE74C3C);
  static const bg = Color(0xFFF8F3EC);
  static const surface = Colors.white;
  static const gold = Color(0xFFF5A623);
  static const hairline = Color(0xFFEDE5DA);
}

class AppText {
  static TextStyle serif({
    double size = 20,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.dark,
    double? height,
    double? letterSpacing,
    FontStyle? style,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: style,
      );
}

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.gold,
    surface: AppColors.surface,
  ),
  textTheme: GoogleFonts.interTextTheme()
      .apply(bodyColor: AppColors.dark, displayColor: AppColors.dark)
      .copyWith(
        headlineSmall: AppText.serif(size: 26, weight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.dark),
        bodyMedium: GoogleFonts.inter(color: AppColors.dark, height: 1.4),
      ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bg,
    foregroundColor: AppColors.dark,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: AppText.serif(size: 26, weight: FontWeight.w700),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.08),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.hairline),
    ),
    margin: EdgeInsets.zero,
  ),
  dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: 1),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      elevation: 0,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: GoogleFonts.inter(color: AppColors.gray),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.hairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: AppColors.primary,
    showCheckmark: false,
    labelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.dark),
    secondaryLabelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
    shape: const StadiumBorder(side: BorderSide(color: AppColors.hairline)),
    padding: const EdgeInsets.symmetric(horizontal: 6),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.bg,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.dark,
    contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

class EstadoPedidoUI {
  static const Map<String, Color> colores = {
    "PENDIENTE_PAGO": AppColors.warning,
    "CONFIRMADO": Color(0xFF3498DB),
    "EN_PREPARACION": Color(0xFFE67E22),
    "EN_CAMINO": AppColors.primary,
    "ENTREGADO": AppColors.success,
    "CANCELADO": AppColors.danger,
  };

  static const Map<String, String> etiquetas = {
    "PENDIENTE_PAGO": "Pendiente de pago",
    "CONFIRMADO": "Confirmado",
    "EN_PREPARACION": "En preparación",
    "EN_CAMINO": "En camino",
    "ENTREGADO": "Entregado",
    "CANCELADO": "Cancelado",
  };

  static Color color(String estado) => colores[estado] ?? AppColors.gray;
  static String etiqueta(String estado) => etiquetas[estado] ?? estado;
}
