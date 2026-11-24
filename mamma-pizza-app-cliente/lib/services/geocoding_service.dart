import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/secrets.dart';

class LugarEncontrado {
  final String titulo;
  final String detalle;
  final LatLng punto;
  const LugarEncontrado({
    required this.titulo,
    required this.detalle,
    required this.punto,
  });
}

/// Zona donde se entrega: Trujillo, Víctor Larco, La Esperanza, El Porvenir,
/// Huanchaco, Moche y Laredo. Cambia los números aquí y se actualiza todo.
class ZonaServicio {
  static const double minLat = -8.25;
  static const double maxLat = -8.00;
  static const double minLng = -79.20;
  static const double maxLng = -78.80;

  static const LatLng suroeste = LatLng(minLat, minLng);
  static const LatLng noreste = LatLng(maxLat, maxLng);

  /// Formato Mapbox: minLng,minLat,maxLng,maxLat
  static const String bbox = '$minLng,$minLat,$maxLng,$maxLat';

  static bool contiene(LatLng p) =>
      p.latitude >= minLat &&
      p.latitude <= maxLat &&
      p.longitude >= minLng &&
      p.longitude <= maxLng;
}

/// Configuración de Mapbox.
/// Prioridad del token: --dart-define=MAPBOX_TOKEN=pk... y, si no hay, secrets.dart.
class MapboxConfig {
  static const String _definido = String.fromEnvironment('MAPBOX_TOKEN');
  static const String _permanente = String.fromEnvironment('MAPBOX_PERMANENT');

  static String get token => _definido.isNotEmpty ? _definido : kMapboxToken;

  /// Solo acepta tokens públicos (pk.). Un sk. nunca debe ir dentro de la app.
  static bool get configurado =>
      token.isNotEmpty && token.startsWith('pk.') && !token.contains('PEGA_AQUI');

  static bool get permanente => _permanente.toLowerCase() == 'true';

  static String get urlTiles =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
}

/// Búsqueda de calles y conversión coordenadas -> texto (Mapbox Geocoding v6).
class GeocodingService {
  static const _host = 'api.mapbox.com';
  static const _timeout = Duration(seconds: 10);
  static const _cercaDeTrujillo = '-79.0287,-8.1116'; // lng,lat

  static void _validarToken() {
    if (!MapboxConfig.configurado) {
      throw Exception('Falta el token de Mapbox (MAPBOX_TOKEN)');
    }
  }

  /// Busca direcciones dentro de la zona de servicio, priorizando Trujillo.
  static Future<List<LugarEncontrado>> buscar(String consulta) async {
    _validarToken();

    final uri = Uri.https(_host, '/search/geocode/v6/forward', {
      'q': consulta,
      'country': 'pe',
      'language': 'es',
      'limit': '6',
      'proximity': _cercaDeTrujillo,
      'bbox': ZonaServicio.bbox, // descarta resultados fuera de la zona
      if (MapboxConfig.permanente) 'permanent': 'true',
      'access_token': MapboxConfig.token,
    });

    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('No se pudo buscar la dirección (${resp.statusCode})');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final features = (json['features'] as List?) ?? [];

    final resultados = <LugarEncontrado>[];
    for (final f in features) {
      final lugar = _aLugar(f as Map<String, dynamic>);
      if (lugar != null) resultados.add(lugar);
    }
    return resultados;
  }

  /// Convierte coordenadas en una dirección legible. Devuelve null si falla.
  /// Prueba del tipo más preciso (dirección con número) al más general.
  static Future<String?> direccionDe(LatLng punto) async {
    if (!MapboxConfig.configurado) return null;

    for (final tipo in const ['address', 'street', 'neighborhood', 'locality']) {
      try {
        final uri = Uri.https(_host, '/search/geocode/v6/reverse', {
          'longitude': punto.longitude.toString(),
          'latitude': punto.latitude.toString(),
          'language': 'es',
          'types': tipo,
          'limit': '1',
          if (MapboxConfig.permanente) 'permanent': 'true',
          'access_token': MapboxConfig.token,
        });

        final resp = await http.get(uri).timeout(_timeout);
        if (resp.statusCode != 200) continue;

        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final features = (json['features'] as List?) ?? [];
        if (features.isEmpty) continue;

        final lugar = _aLugar(features.first as Map<String, dynamic>);
        if (lugar != null) return lugar.titulo;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Mapbox entrega coordenadas como [lng, lat]: ojo con el orden.
  static LugarEncontrado? _aLugar(Map<String, dynamic> feature) {
    final props = (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

    double? lat;
    double? lng;

    final coords = (props['coordinates'] as Map?)?.cast<String, dynamic>();
    if (coords != null) {
      lat = double.tryParse(coords['latitude'].toString());
      lng = double.tryParse(coords['longitude'].toString());
    }
    if (lat == null || lng == null) {
      final geom = ((feature['geometry'] as Map?)?['coordinates']) as List?;
      if (geom != null && geom.length >= 2) {
        lng = double.tryParse(geom[0].toString());
        lat = double.tryParse(geom[1].toString());
      }
    }
    if (lat == null || lng == null) return null;

    final nombre = (props['name_preferred'] ?? props['name'] ?? '').toString().trim();
    final contexto = (props['place_formatted'] ?? '').toString().trim();
    final completo = (props['full_address'] ?? '').toString().trim();

    final titulo = nombre.isEmpty
        ? completo
        : (contexto.isEmpty ? nombre : '$nombre, $contexto');
    if (titulo.isEmpty) return null;

    return LugarEncontrado(
      titulo: titulo,
      detalle: completo.isEmpty ? titulo : completo,
      punto: LatLng(lat, lng),
    );
  }
}