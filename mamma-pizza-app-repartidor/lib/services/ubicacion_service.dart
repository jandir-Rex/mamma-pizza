import 'package:geolocator/geolocator.dart' as geo;

class UbicacionService {
  /// Pide permiso si hace falta. Devuelve true si ya podemos leer la ubicación.
  static Future<bool> asegurarPermiso() async {
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) return false;
      var permiso = await geo.Geolocator.checkPermission();
      if (permiso == geo.LocationPermission.denied) {
        permiso = await geo.Geolocator.requestPermission();
      }
      return permiso == geo.LocationPermission.whileInUse ||
          permiso == geo.LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  static Future<geo.Position?> actual() async {
    try {
      return await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  /// Flujo de posiciones: una actualización cada ~20 m
  static Stream<geo.Position> flujo() => geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          distanceFilter: 20,
        ),
      );

  static Future<void> abrirAjustes() async {
    await geo.Geolocator.openAppSettings();
    await geo.Geolocator.openLocationSettings();
  }
}