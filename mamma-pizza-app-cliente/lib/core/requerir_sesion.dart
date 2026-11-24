import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

/// Devuelve true si el usuario ya tiene sesión o si la inicia ahora.
/// Si cierra el login, devuelve false.
Future<bool> requerirSesion(NavigatorState nav, AuthProvider auth) async {
  if (auth.usuario != null) return true;
  await nav.push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => const LoginScreen(),
    ),
  );
  return auth.usuario != null;
}