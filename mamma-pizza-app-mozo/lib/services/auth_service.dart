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
    final usuario = Usuario.fromJson(data["usuario"]);

    if (usuario.rol != "MOZO") {
      throw Exception("Esta cuenta no tiene permisos de mozo");
    }

    return AuthResultado(token: data["token"], usuario: usuario);
  }
}