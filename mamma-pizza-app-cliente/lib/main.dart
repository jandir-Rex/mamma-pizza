import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/carrito_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..intentarSesionGuardada()),
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
      ],
      child: const MammaPizzaApp(),
    ),
  );
}

class MammaPizzaApp extends StatelessWidget {
  const MammaPizzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamma Pizza',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const _Arrancador(),
    );
  }
}

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

    return auth.usuario != null ? const MainShell() : const LoginScreen();
  }
}