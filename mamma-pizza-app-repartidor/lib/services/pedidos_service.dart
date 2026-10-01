import '../core/api_client.dart';
import '../models/entrega.dart';

class PedidosService {
  // Ajusta estas rutas a las del backend si difieren.
  static const String rutaMisEntregas = "/pedidos/mis-entregas";
  static String rutaEstado(int id) => "/pedidos/$id/estado";

  static Future<List<Entrega>> misEntregas() async {
    final data = await ApiClient.get(rutaMisEntregas);
    return (data as List).map((e) => Entrega.fromJson(e)).toList();
  }

  static Future<void> cambiarEstado(int id, String estado) async {
    await ApiClient.patch(rutaEstado(id), {"estado": estado});
  }
}
