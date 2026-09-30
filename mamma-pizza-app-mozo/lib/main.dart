import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/mesas_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..intentarSesionGuardada(),
      child: const MammaPizzaMozoApp(),
    ),
  );
}

class MammaPizzaMozoApp extends StatelessWidget {
  const MammaPizzaMozoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Mamma Pizza — Mozo', debugShowCheckedModeBanner: false, theme: appTheme, home: const _Arrancador());
  }
}

class _Arrancador extends StatelessWidget {
  const _Arrancador();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.cargando) {
      return const Scaffold(backgroundColor: AppColors.bg, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return auth.usuario != null ? const MesasScreen() : const LoginScreen();
  }
}