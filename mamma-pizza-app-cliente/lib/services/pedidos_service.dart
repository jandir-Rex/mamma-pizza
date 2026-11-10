import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/pedido.dart';

class ConfigPago {
  final String? yapeNumero;
  final String? yapeTitular;
  ConfigPago({this.yapeNumero, this.yapeTitular});
}

class PedidosService {
  static Future<List<Pedido>> misPedidos() async {
    final data = await ApiClient.get("/pedidos/mios");
    return (data as List).map((p) => Pedido.fromJson(p)).toList();
  }

  static Future<Pedido> obtenerPorId(int id) async {
    final data = await ApiClient.get("/pedidos/$id");
    return Pedido.fromJson(data);
  }

  static Future<Pedido> crear({
    required String canal,
    int? direccionId,
    int? mesaId,
    required String metodoPago,
    double? pagaCon,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await ApiClient.post("/pedidos", {
      "canal": canal,
      if (direccionId != null) "direccionId": direccionId,
      if (mesaId != null) "mesaId": mesaId,
      "metodoPago": metodoPago,
      if (pagaCon != null) "pagaCon": pagaCon,
      "items": items,
    });
    return Pedido.fromJson(data);
  }

  static Future<ConfigPago> configPago() async {
    final data = await ApiClient.get("/pedidos/config-pago");
    return ConfigPago(
      yapeNumero: data["yapeNumero"]?.toString(),
      yapeTitular: data["yapeTitular"]?.toString(),
    );
  }

  /// Sube la captura del Yape (multipart) y la nota con el nombre de quien yapeó.
  static Future<Pedido> subirComprobante(
    int pedidoId, {
    required XFile imagen,
    required String yapeNombre,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final req = http.MultipartRequest("POST", Uri.parse("${ApiClient.baseUrl}/pedidos/$pedidoId/comprobante"));
    if (token != null) req.headers["Authorization"] = "Bearer $token";
    req.fields["yapeNombre"] = yapeNombre;
    req.files.add(http.MultipartFile.fromBytes("imagen", await imagen.readAsBytes(), filename: "yape.jpg"));

    final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 40)));
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data["error"] ?? "No se pudo subir el comprobante");
    }
    return Pedido.fromJson(data);
  }
}