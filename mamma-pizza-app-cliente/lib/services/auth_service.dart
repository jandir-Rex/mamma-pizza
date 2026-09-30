import '../core/api_client.dart';
import '../models/usuario.dart';

class AuthResultado {
  final String token;
  final Usuario usuario;
  AuthResultado({required this.token, required this.usuario});
}

class AuthService {
  static Future<AuthResultado> login(String email, String password) async {
    final data = await ApiClient.post("/auth/login", {"email": email, "password": password});
    return AuthResultado(token: data["token"], usuario: Usuario.fromJson(data["usuario"]));
  }

  static Future<AuthResultado> registro({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    final data = await ApiClient.post("/auth/registro", {
      "nombre": nombre,
      "email": email,
      "password": password,
      if (telefono != null && telefono.isNotEmpty) "telefono": telefono,
    });
    return AuthResultado(token: data["token"], usuario: Usuario.fromJson(data["usuario"]));
  }

  static Future<Usuario> actualizarPerfil({String? nombre, String? telefono}) async {
    final data = await ApiClient.patch("/auth/perfil", {
      if (nombre != null && nombre.isNotEmpty) "nombre": nombre,
      if (telefono != null) "telefono": telefono,
    });
    return Usuario.fromJson(data);
  }
}