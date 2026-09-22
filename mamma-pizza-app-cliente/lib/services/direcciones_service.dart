import '../core/api_client.dart';
import '../models/direccion.dart';

class DireccionesService {
  static Future<List<Direccion>> listar() async {
    final data = await ApiClient.get("/direcciones");
    return (data as List).map((d) => Direccion.fromJson(d)).toList();
  }

  static Future<Direccion> crear({
    required String zona,
    String? referencia,
    required double lat,
    required double lng,
  }) async {
    final data = await ApiClient.post("/direcciones", {
      "zona": zona,
      if (referencia != null && referencia.isNotEmpty) "referencia": referencia,
      "lat": lat,
      "lng": lng,
    });
    return Direccion.fromJson(data);
  }
}