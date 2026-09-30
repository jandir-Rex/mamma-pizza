import '../core/api_client.dart';

class RepartidorService {
  static Future<void> actualizarUbicacion(double lat, double lng) async {
    await ApiClient.patch("/repartidores/ubicacion", {"lat": lat, "lng": lng});
  }

  static Future<void> actualizarDisponibilidad(bool disponible) async {
    await ApiClient.patch("/repartidores/disponibilidad", {"disponible": disponible});
  }
}