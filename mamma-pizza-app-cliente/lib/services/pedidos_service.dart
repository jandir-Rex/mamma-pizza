import '../core/api_client.dart';
import '../models/pedido.dart';

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
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await ApiClient.post("/pedidos", {
      "canal": canal,
      if (direccionId != null) "direccionId": direccionId,
      if (mesaId != null) "mesaId": mesaId,
      "metodoPago": metodoPago,
      "items": items,
    });
    return Pedido.fromJson(data);
  }
}