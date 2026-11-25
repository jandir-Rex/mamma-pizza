import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // URL de tu backend en Render (sin "/" al final)
  static const String serverUrl = "https://mamma-pizza-backend.onrender.com";

  static const String baseUrl = "$serverUrl/api";

  // Render gratis se duerme: la primera petición puede tardar ~30-60s
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

  /// Decodifica el body sin romperse si el servidor responde algo que no es JSON
  /// (por ejemplo un 502 en HTML cuando Render está despertando).
  static dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  static String _errorMsg(dynamic data, int status) {
    if (data is Map && data["error"] != null) return data["error"].toString();
    if (status == 502 || status == 503) {
      return "El servidor está iniciando, intenta de nuevo en unos segundos";
    }
    return "Error inesperado";
  }

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl$path"),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    final data = _decode(res);
    if (res.statusCode >= 400) {
      throw Exception(_errorMsg(data, res.statusCode));
    }
    return (data as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  static Future<dynamic> get(String path) async {
    final res = await http
        .get(Uri.parse("$baseUrl$path"), headers: await _headers())
        .timeout(_timeout);
    final data = _decode(res);
    if (res.statusCode >= 400) {
      throw Exception(_errorMsg(data, res.statusCode));
    }
    return data;
  }

  static Future<dynamic> patch(String path,
      [Map<String, dynamic>? body]) async {
    final res = await http
        .patch(
          Uri.parse("$baseUrl$path"),
          headers: await _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    final data = _decode(res);
    if (res.statusCode >= 400) {
      throw Exception(_errorMsg(data, res.statusCode));
    }
    return data;
  }

  static Future<void> delete(String path, [Map<String, dynamic>? body]) async {
    final res = await http
        .delete(
          Uri.parse("$baseUrl$path"),
          headers: await _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    if (res.statusCode >= 400) {
      throw Exception(_errorMsg(_decode(res), res.statusCode));
    }
  }
}
