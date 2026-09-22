import '../core/api_client.dart';
import '../models/producto.dart';
import '../models/agregado.dart';

class ProductosService {
  static Future<List<Producto>> obtenerMenu() async {
    final data = await ApiClient.get("/productos/menu");
    return (data as List).map((p) => Producto.fromJson(p)).toList();
  }

  static Future<List<Agregado>> obtenerAgregados() async {
    final data = await ApiClient.get("/agregados");
    return (data as List).map((a) => Agregado.fromJson(a)).toList();
  }
}