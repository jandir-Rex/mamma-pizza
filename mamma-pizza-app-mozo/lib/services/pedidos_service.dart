import '../core/api_client.dart';

class PedidosService {
  static Future<void> crear({required int mesaId, required List<Map<String, dynamic>> items}) async {
    await ApiClient.post("/pedidos", {
      "canal": "SALON",
      "mesaId": mesaId,
      "metodoPago": "EFECTIVO",
      "items": items,
    });
  }
}