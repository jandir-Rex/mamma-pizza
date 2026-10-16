import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show Position;
import '../core/mapbox_config.dart';

class RutaInfo {
  final List<Position> puntos;
  final double distanciaM;
  final double duracionS;
  RutaInfo(this.puntos, this.distanciaM, this.duracionS);

  String get minutos => "${(duracionS / 60).ceil()} min";
  String get km => "${(distanciaM / 1000).toStringAsFixed(1)} km";
}

class RutaService {
  static List<Position> _coords(List coords) =>
      coords.map((c) => Position((c[0] as num).toDouble(), (c[1] as num).toDouble())).toList();

  /// Ruta real por calles con tráfico hacia UN destino.
  static Future<RutaInfo?> obtener(Position origen, Position destino) async {
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/'
        '${origen.lng},${origen.lat};${destino.lng},${destino.lat}'
        '?geometries=geojson&overview=full&access_token=$mapboxToken',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final rutas = jsonDecode(res.body)['routes'] as List?;
      if (rutas == null || rutas.isEmpty) return null;

      final r = rutas.first;
      return RutaInfo(
        _coords(r['geometry']['coordinates']),
        (r['distance'] as num).toDouble(),
        (r['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Orden óptimo para VARIAS entregas (máx. 12 puntos en total).
  /// Sale desde [origen] y termina en la última entrega (sin volver al local).
  static Future<RutaInfo?> optimizada(Position origen, List<Position> destinos) async {
    try {
      final todos = [origen, ...destinos];
      final coords = todos.map((p) => '${p.lng},${p.lat}').join(';');
      final url = Uri.parse(
        'https://api.mapbox.com/optimized-trips/v1/mapbox/driving/$coords'
        '?source=first&destination=any&roundtrip=false'
        '&geometries=geojson&overview=full&access_token=$mapboxToken',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final trips = jsonDecode(res.body)['trips'] as List?;
      if (trips == null || trips.isEmpty) return null;

      final t = trips.first;
      return RutaInfo(
        _coords(t['geometry']['coordinates']),
        (t['distance'] as num).toDouble(),
        (t['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}