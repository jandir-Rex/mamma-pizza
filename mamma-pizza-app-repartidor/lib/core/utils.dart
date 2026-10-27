import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

Future<bool> abrirLlamada(String telefono) =>
    launchUrl(Uri(scheme: 'tel', path: telefono.replaceAll(' ', '')));

Future<bool> abrirGoogleMaps(double lat, double lng) => launchUrl(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'),
      mode: LaunchMode.externalApplication,
    );

Future<bool> abrirWaze(double lat, double lng) => launchUrl(
      Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes'),
      mode: LaunchMode.externalApplication,
    );

String soles(double v) => 'S/. ${v.toStringAsFixed(2)}';

String hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String haceCuanto(DateTime d) {
  final m = DateTime.now().difference(d).inMinutes;
  if (m < 1) return 'ahora';
  if (m < 60) return 'hace $m min';
  return 'hace ${m ~/ 60} h';
}

String iniciales(String? nombre) {
  if (nombre == null || nombre.trim().isEmpty) return '?';
  final partes = nombre.trim().split(RegExp(r'\s+'));
  if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
  return (partes[0].substring(0, 1) + partes[1].substring(0, 1)).toUpperCase();
}

String mensajeError(Object e) => e.toString().replaceFirst('Exception: ', '');

/// Distancia en metros entre dos coordenadas (Haversine)
double distanciaMetros(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double g) => g * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a.toDouble()));
}