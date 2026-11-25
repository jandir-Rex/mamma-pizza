import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/push_notifications_service.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? usuario;
  bool cargando = true;

  Future<void> intentarSesionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final nombre = prefs.getString("nombre");
    final email = prefs.getString("email");
    final rol = prefs.getString("rol");
    final id = prefs.getInt("id");

    if (token != null &&
        nombre != null &&
        email != null &&
        rol != null &&
        id != null) {
      usuario = Usuario(id: id, nombre: nombre, email: email, rol: rol);
      unawaited(PushNotificationsService.syncInstallation());
    }
    cargando = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final resultado = await AuthService.login(email, password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", resultado.token);
    await prefs.setInt("id", resultado.usuario.id);
    await prefs.setString("nombre", resultado.usuario.nombre);
    await prefs.setString("email", resultado.usuario.email);
    await prefs.setString("rol", resultado.usuario.rol);
    usuario = resultado.usuario;
    notifyListeners();
    unawaited(PushNotificationsService.syncInstallation());
  }

  Future<void> logout() async {
    await PushNotificationsService.unregisterDevice();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    usuario = null;
    notifyListeners();
  }
}
