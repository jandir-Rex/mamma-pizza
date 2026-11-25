import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Error de la API con el código HTTP (400, 403, 409, 423...).
/// Implementa Exception y su toString() es solo el mensaje, así que
/// mensajeError() y los `catch (e)` actuales siguen funcionando igual.
class ApiException implements Exception {
  final String mensaje;
  final int status;
  const ApiException(this.mensaje, this.status);

  /// El backend responde 423 (Locked) cuando el código de entrega se bloqueó.
  bool get esBloqueo => status == 423;

  @override
  String toString() => mensaje;
}

class ApiClient {
  static const String serverUrl = "https://mamma-pizza-backend.onrender.com";
  static const String baseUrl = "$serverUrl/api";
  static const Duration _timeout = Duration(seconds: 60);

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  /// Decodifica la respuesta y lanza ApiException si el status es >= 400.
  static dynamic _procesar(http.Response res) {
    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = null; // el servidor devolvió algo que no es JSON
    }
    if (res.statusCode >= 400) {
      final mensaje = (data is Map && data["error"] is String)
          ? data["error"] as String
          : "Error inesperado";
      throw ApiException(mensaje, res.statusCode);
    }
    return data;
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl$path"),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _procesar(res) as Map<String, dynamic>;
  }

  static Future<dynamic> get(String path) async {
    final res = await http
        .get(Uri.parse("$baseUrl$path"), headers: await _headers())
        .timeout(_timeout);
    return _procesar(res);
  }

  static Future<dynamic> patch(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final res = await http
        .patch(
          Uri.parse("$baseUrl$path"),
          headers: await _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _procesar(res);
  }

  static Future<void> delete(String path, [Map<String, dynamic>? body]) async {
    final res = await http
        .delete(
          Uri.parse("$baseUrl$path"),
          headers: await _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    _procesar(res);
  }
}
