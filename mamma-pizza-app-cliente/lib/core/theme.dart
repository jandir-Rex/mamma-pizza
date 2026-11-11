import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
// COLORES
// ─────────────────────────────────────────────────────────────
class AppColors {
  // --- Marca (logo) ---
  static const cacao = Color(0xFF5E3526);
  static const cacaoDark = Color(0xFF3E2118);
  static const primary = Color(0xFF8B3A2E);
  static const primaryLight = Color(0xFFB35A46);
  static const primaryDark = Color(0xFF5E2219);

  // --- Carta (kraft) ---
  static const kraft = Color(0xFFE9CFA6);
  static const kraftLight = Color(0xFFF3E3C8);
  static const kraftDark = Color(0xFFD4B483); // bordes sobre kraft

  // --- Acentos ---
  static const tomate = Color(0xFFE02B20);
  static const tomateDark = Color(0xFFB81F16);
  static const albahaca = Color(0xFF3C9A4A); // relleno / ícono (NO texto chico)
  static const mostaza = Color(0xFFF2B233); // relleno (texto encima: dark)
  static const mostazaDark = Color(0xFF8A5B00); // mostaza apta para texto
  static const carbon = Color(0xFF2A2C2E);
  static const carbonDark = Color(0xFF1A1B1C);

  // --- Base ---
  static const dark = Color(0xFF2B2118);
  static const gray = Color(0xFF7A7168);
  static const bg = Color(0xFFFBF6EE);
  static const surface = Colors.white;
  static const border = Color(0xFFE8E2DA);

  // --- Semánticos (aptos para texto, contraste AA) ---
  static const success = Color(0xFF2E7D3A);
  static const warning = mostaza;
  static const danger = Color(0xFFC0392B);
  static const info = Color(0xFF1F6FBF);

  // --- Estados de pedido ---
  static const naranja = Color(0xFFC2570C); // en preparación
  static const morado = Color(0xFF6B4BB8); // en camino

  // --- Fondos suaves para alertas / badges ---
  static const dangerSoft = Color(0xFFFDECEA);
  static const successSoft = Color(0xFFE8F4EA);
  static const warningSoft = Color(0xFFFFF3D6);
  static const infoSoft = Color(0xFFE6F0FB);

  // --- Compatibilidad con pantallas/widgets antiguos ---
  static const hairline = border;
  static const lightGray = Color(0xFFB8AFA6);
  static const gold = mostaza;
}

// ─────────────────────────────────────────────────────────────
// TIPOGRAFÍA
// ─────────────────────────────────────────────────────────────
class AppFonts {
  /// Nombre de marca y títulos hero (parecida al logo).
  static TextStyle marca({double size = 28, Color color = AppColors.cacao}) =>
      GoogleFonts.caprasimo(fontSize: size, color: color, height: 1.05);

  /// Encabezados de sección (como la carta).
  static TextStyle titulo({double size = 22, Color color = AppColors.dark}) =>
      GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 0.6);

  /// Precios: Bebas Neue en color primary.
  static TextStyle precio({double size = 22, Color color = AppColors.primary}) =>
      GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 0.5);

  /// Cuerpo (Poppins). Mínimo 12.
  static TextStyle cuerpo({
    double size = 14,
    FontWeight peso = FontWeight.w400,
    Color color = AppColors.dark,
    double? altura,
  }) =>
      GoogleFonts.poppins(
        fontSize: size < 12 ? 12 : size,
        fontWeight: peso,
        color: color,
        height: altura,
      );
}

/// Compatibilidad: ya no se usa Cormorant; mapea a Caprasimo.
class AppText {
  static TextStyle serif({
    double size = 20,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.dark,
    double? height,
    double? letterSpacing,
    FontStyle? style,
  }) =>
      GoogleFonts.caprasimo(
        fontSize: size,
        color: color,
        height: height ?? 1.1,
        letterSpacing: letterSpacing,
      );
}

// ─────────────────────────────────────────────────────────────
// SOMBRAS, DEGRADADOS, RADIOS, ESPACIADO, MOVIMIENTO
// ─────────────────────────────────────────────────────────────
class AppShadows {
  static const suave = [
    BoxShadow(color: Color(0x143E2118), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const media = [
    BoxShadow(color: Color(0x1F3E2118), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const alta = [
    BoxShadow(color: Color(0x2E3E2118), blurRadius: 32, offset: Offset(0, 14)),
  ];

  /// Para barras inferiores (sombra hacia arriba).
  static const barraInferior = [
    BoxShadow(color: Color(0x143E2118), blurRadius: 16, offset: Offset(0, -4)),
  ];

  /// Brillo de color para botones/tarjetas de marca.
  static List<BoxShadow> brillo(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.30),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppGradients {
  static const cacao = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cacao, AppColors.cacaoDark],
  );
  static const kraft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.kraftLight, AppColors.kraft],
  );
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryLight],
  );
  static const tomate = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.tomate, AppColors.tomateDark],
  );
  static const carbon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.carbon, AppColors.carbonDark],
  );
}

class AppRadius {
  static const double chico = 14;
  static const double medio = 20;
  static const double grande = 28;

  static const bChico = BorderRadius.all(Radius.circular(chico));
  static const bMedio = BorderRadius.all(Radius.circular(medio));
  static const bGrande = BorderRadius.all(Radius.circular(grande));
}

class AppSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class AppMotion {
  static const rapida = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 260);
  static const lenta = Duration(milliseconds: 350);
  static const stagger = Duration(milliseconds: 50);
  static const curva = Curves.easeOutCubic;
}

// ─────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────
final _textTheme = GoogleFonts.poppinsTextTheme()
    .apply(bodyColor: AppColors.dark, displayColor: AppColors.dark)
    .copyWith(
      headlineSmall: AppFonts.marca(size: 26),
      titleLarge: AppFonts.titulo(size: 24),
      titleMedium: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark),
      bodyMedium: GoogleFonts.poppins(
          fontSize: 14, color: AppColors.dark, height: 1.4),
      bodySmall: GoogleFonts.poppins(
          fontSize: 12, color: AppColors.gray, height: 1.35),
      labelLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
    );

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  fontFamily: GoogleFonts.poppins().fontFamily,
  splashFactory: InkRipple.splashFactory,
  splashColor: AppColors.primary.withValues(alpha: 0.08),
  highlightColor: AppColors.primary.withValues(alpha: 0.04),
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.tomate,
    onSecondary: Colors.white,
    tertiary: AppColors.albahaca,
    error: AppColors.danger,
    surface: AppColors.surface,
    onSurface: AppColors.dark,
    outline: AppColors.border,
  ),
  textTheme: _textTheme,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bg,
    foregroundColor: AppColors.dark,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: AppFonts.titulo(size: 26),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.medio),
      side: const BorderSide(color: AppColors.border),
    ),
    margin: EdgeInsets.zero,
  ),
  dividerTheme:
      const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.border,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.border,
      disabledForegroundColor: AppColors.gray,
      minimumSize: const Size.fromHeight(54),
      elevation: 0,
      textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.border,
      disabledForegroundColor: AppColors.gray,
      minimumSize: const Size.fromHeight(54),
      textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size.fromHeight(52),
      side: const BorderSide(color: AppColors.primary, width: 1.4),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(48, 48),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    extendedTextStyle:
        GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: GoogleFonts.poppins(color: AppColors.gray, fontSize: 14),
    floatingLabelStyle: GoogleFonts.poppins(
        color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
    hintStyle: GoogleFonts.poppins(color: AppColors.gray, fontSize: 14),
    errorStyle: GoogleFonts.poppins(color: AppColors.danger, fontSize: 12),
    prefixIconColor: AppColors.gray,
    suffixIconColor: AppColors.gray,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.chico),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.chico),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.chico),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.chico),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.chico),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: AppColors.primary,
    showCheckmark: false,
    labelStyle: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
    secondaryLabelStyle: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
    shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
    padding: const EdgeInsets.symmetric(horizontal: 8),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected)
          ? AppColors.primary
          : Colors.transparent,
    ),
    checkColor: const WidgetStatePropertyAll(Colors.white),
    side: const BorderSide(color: AppColors.gray, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected)
          ? AppColors.primary
          : AppColors.gray,
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: const WidgetStatePropertyAll(Colors.white),
    trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected)
          ? AppColors.albahaca
          : AppColors.lightGray,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.bg,
    surfaceTintColor: Colors.transparent,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.grande)),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
    contentTextStyle:
        GoogleFonts.poppins(fontSize: 14, color: AppColors.gray, height: 1.4),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.dark,
    contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
    actionTextColor: AppColors.mostaza,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
);

// ─────────────────────────────────────────────────────────────
// ESTADOS DE PEDIDO
// ─────────────────────────────────────────────────────────────
class EstadoPedidoUI {
  static const Map<String, Color> colores = {
    "PENDIENTE_PAGO": AppColors.mostaza,
    "CONFIRMADO": AppColors.info,
    "EN_PREPARACION": AppColors.naranja,
    "EN_CAMINO": AppColors.morado,
    "ENTREGADO": AppColors.albahaca,
    "CANCELADO": AppColors.danger,
  };

  /// Variante apta para TEXTO sobre fondo suave (contraste AA).
  static const Map<String, Color> _textos = {
    "PENDIENTE_PAGO": AppColors.mostazaDark,
    "CONFIRMADO": AppColors.info,
    "EN_PREPARACION": AppColors.naranja,
    "EN_CAMINO": AppColors.morado,
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

  static const Map<String, IconData> iconos = {
    "PENDIENTE_PAGO": Icons.schedule,
    "CONFIRMADO": Icons.check_circle_outline,
    "EN_PREPARACION": Icons.local_pizza_outlined,
    "EN_CAMINO": Icons.delivery_dining,
    "ENTREGADO": Icons.check_circle,
    "CANCELADO": Icons.cancel_outlined,
  };

  static Color color(String estado) => colores[estado] ?? AppColors.gray;
  static Color colorTexto(String estado) => _textos[estado] ?? AppColors.gray;
  static Color fondo(String estado) => color(estado).withValues(alpha: 0.14);
  static String etiqueta(String estado) => etiquetas[estado] ?? estado;
  static IconData icono(String estado) => iconos[estado] ?? Icons.info_outline;
  static bool esActivo(String estado) =>
      estado != "ENTREGADO" && estado != "CANCELADO";
}