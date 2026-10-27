import '../core/api_client.dart';
import '../models/entrega.dart';

class PedidosService {
  /// Pedidos asignados al repartidor (activos + últimos entregados)
  static Future<List<Entrega>> misEntregas() async {
    final data = await ApiClient.get("/pedidos/repartidor/mis-entregas");
    return (data as List).map((e) => Entrega.fromJson(e)).toList();
  }

  /// EN_PREPARACION -> EN_CAMINO. El backend genera el código de 4 dígitos para el cliente.
  static Future<void> iniciarEntrega(int id) async {
    await ApiClient.patch("/pedidos/$id/estado", {"estado": "EN_CAMINO"});
  }

  /// El repartidor ya NO puede marcar ENTREGADO directo: debe ingresar el código del cliente.
  static Future<void> entregarConCodigo(int id, String codigo) async {
    await ApiClient.patch("/pedidos/$id/entregar", {"codigo": codigo});
  }

  /// Suelta el pedido (vuelve al pool). Solo antes de salir (no en EN_CAMINO).
  static Future<void> soltar(int id) async {
    await ApiClient.patch("/pedidos/$id/liberar-repartidor");
  }

  /// Historial de un día (local) del repartidor
  static Future<List<Entrega>> historial(DateTime dia) async {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fin = inicio.add(const Duration(days: 1));
    final desde = Uri.encodeQueryComponent(inicio.toUtc().toIso8601String());
    final hasta = Uri.encodeQueryComponent(fin.toUtc().toIso8601String());
    final data = await ApiClient.get("/pedidos/historial?desde=$desde&hasta=$hasta");
    return (data as List).map((e) => Entrega.fromJson(e)).toList();
  }
}