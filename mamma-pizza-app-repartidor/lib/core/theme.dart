import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF8B3A2E);
  static const primaryLight = Color(0xFFB35A46);
  static const primaryDark = Color(0xFF5E2219);
  static const dark = Color(0xFF2B2118);
  static const gray = Color(0xFF7A7168);
  static const success = Color(0xFF1E7A34);
  static const warning = Color(0xFFE0A800);
  static const danger = Color(0xFFC0392B);
  static const info = Color(0xFF2E7FD1);
  static const bg = Color(0xFFF7F3EE);
  static const surface = Colors.white;
  static const border = Color(0xFFE8E2DA);
}

class AppGradients {
  static const brand = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const success = LinearGradient(
    colors: [Color(0xFF1E7A34), Color(0xFF2FA04A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static final soft = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static final floating = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 26, offset: const Offset(0, 10)),
  ];
  static final hoja = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 24, offset: const Offset(0, -6)),
  ];
}

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  fontFamily: GoogleFonts.poppins().fontFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.surface,
  ),
  textTheme: GoogleFonts.poppinsTextTheme().copyWith(
    headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.dark),
    titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.dark),
    bodyMedium: GoogleFonts.poppins(color: AppColors.dark, height: 1.4),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bg,
    foregroundColor: AppColors.dark,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.dark,
    ),
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
      disabledBackgroundColor: AppColors.border,
      disabledForegroundColor: AppColors.gray,
      minimumSize: const Size.fromHeight(54),
      elevation: 0,
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: AppColors.primary,
    labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.border),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 4),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.dark,
    contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  ),
);

// Colores y etiquetas de estado de pedido, coherentes con el enum del backend
class EstadoPedidoUI {
  static const Map<String, Color> colores = {
    "PENDIENTE_PAGO": AppColors.warning,
    "CONFIRMADO": Color(0xFF2E7FD1),
    "EN_PREPARACION": Color(0xFFE07A00),
    "EN_CAMINO": Color(0xFF7C3AED),
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