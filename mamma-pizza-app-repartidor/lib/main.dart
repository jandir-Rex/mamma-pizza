import 'package:flutter/material.dart';

import 'core/auth/auth_controller.dart';
import 'core/models/sesion.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const MammaRepartidorApp());
}

class MammaRepartidorApp extends StatefulWidget {
  const MammaRepartidorApp({super.key});

  @override
  State<MammaRepartidorApp> createState() => _MammaRepartidorAppState();
}

class _MammaRepartidorAppState extends State<MammaRepartidorApp> {
  // El rol se fija aqui: si el login devuelve otro, el AuthController lo
  // rechaza y no guarda la sesion.
  final _auth = AuthController(rolApp: Rol.repartidor);

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _auth,
      child: MaterialApp(
        title: 'Mamma Pizza - Repartidor',
        debugShowCheckedModeBanner: false,
        theme: MammaTheme.build(),
        home: AuthGate(
          auth: _auth,
          login: (_) => const LoginScreen(),
          inicio: (_) => const HomeScreen(),
        ),
      ),
    );
  }
}