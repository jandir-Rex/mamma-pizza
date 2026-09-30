import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// IMPORTANTE: en el emulador de Android, "localhost" apunta al propio
// emulador, no a tu PC. Se usa 10.0.2.2 para llegar a tu máquina.
// Si pruebas en un dispositivo físico, reemplaza por la IP de tu PC en la red local (ej. 192.168.1.X).
class ApiClient {
  static const String baseUrl = "http://localhost:4000/api";

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

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse("$baseUrl$path"),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data["error"] ?? "Error inesperado");
    }
    return data;
  }

  static Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse("$baseUrl$path"), headers: await _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data["error"] ?? "Error inesperado");
    }
    return data;
  }

  static Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(
      Uri.parse("$baseUrl$path"),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data["error"] ?? "Error inesperado");
    }
    return data;
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(Uri.parse("$baseUrl$path"), headers: await _headers());
    if (res.statusCode >= 400) {
      final data = jsonDecode(res.body);
      throw Exception(data["error"] ?? "Error inesperado");
    }
  }
}