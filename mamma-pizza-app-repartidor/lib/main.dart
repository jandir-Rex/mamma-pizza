import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show MapboxOptions;
import 'package:provider/provider.dart';
import 'core/mapbox_config.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/entregas_provider.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Mapbox necesita el token público antes de crear cualquier MapWidget
  MapboxOptions.setAccessToken(mapboxToken);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..intentarSesionGuardada()),
        ChangeNotifierProvider(create: (_) => EntregasProvider()),
      ],
      child: const MammaPizzaRepartidorApp(),
    ),
  );
}

class MammaPizzaRepartidorApp extends StatelessWidget {
  const MammaPizzaRepartidorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamma Pizza — Repartidor',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const _Arrancador(),
    );
  }
}

/// Decide qué pantalla mostrar según la sesión.
/// Al iniciar o cerrar sesión, AuthProvider notifica y esto cambia solo (sin Navigator).
class _Arrancador extends StatelessWidget {
  const _Arrancador();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.cargando) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return auth.usuario != null ? const HomeShell() : const LoginScreen();
  }
}