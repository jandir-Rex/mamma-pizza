import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Marcadores del mapa dibujados con Canvas (no necesitas assets).
/// Se dibujan a 3x y el mapa los muestra con iconSize = 1 / escala, así se ven nítidos.
class MarcadoresMapa {
  static const double escala = 3;

  static TextPainter _texto(String texto, {required double size, required Color color, double? maxAncho}) {
    return TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w700),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxAncho ?? double.infinity);
  }

  static TextPainter _icono(IconData icono, {required double size, required Color color}) {
    return TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icono.codePoint),
        style: TextStyle(
          fontSize: size,
          color: color,
          fontFamily: icono.fontFamily,
          package: icono.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static Future<Uint8List> _aPng(ui.PictureRecorder rec, double ancho, double alto) async {
    final imagen = await rec.endRecording().toImage(ancho.ceil(), alto.ceil());
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return datos!.buffer.asUint8List();
  }

  /// Etiqueta oscura con ícono de casa + pin rojo debajo.
  /// Se ancla por ABAJO: la punta del pin queda justo sobre el destino.
  static Future<Uint8List> destino(String texto) async {
    const e = escala;
    final etiqueta = _texto(
      texto.isEmpty ? 'Destino' : texto,
      size: 12.5 * e,
      color: Colors.white,
      maxAncho: 170 * e,
    );
    final casa = _icono(Icons.home_rounded, size: 15 * e, color: Colors.white);

    const padH = 12 * e;
    const padV = 8 * e;
    const radio = 16 * e;
    const punta = 9 * e;
    const separacion = 7 * e;

    final altoPildora = math.max(etiqueta.height, casa.height) + padV * 2;
    final anchoPildora = padH + casa.width + 5 * e + etiqueta.width + padH;
    final ancho = math.max(anchoPildora, radio * 2) + 10 * e;
    final alto = 4 * e + altoPildora + separacion + radio * 2 + punta + 1 * e;

    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final cx = ancho / 2;

    // Píldora oscura
    final pildora = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - anchoPildora / 2, 3 * e, anchoPildora, altoPildora),
      Radius.circular(altoPildora / 2),
    );
    c.drawShadow(Path()..addRRect(pildora), Colors.black, 4 * e, true);
    c.drawRRect(pildora, Paint()..color = AppColors.dark);
    casa.paint(c, Offset(pildora.left + padH, pildora.top + (altoPildora - casa.height) / 2));
    etiqueta.paint(
      c,
      Offset(pildora.left + padH + casa.width + 5 * e, pildora.top + (altoPildora - etiqueta.height) / 2),
    );

    // Pin rojo
    final cy = pildora.bottom + separacion + radio;
    const rojo = Color(0xFFD32F2F);

    final puntaPath = Path()
      ..moveTo(cx - 7 * e, cy + radio - 4 * e)
      ..lineTo(cx, cy + radio + punta)
      ..lineTo(cx + 7 * e, cy + radio - 4 * e)
      ..close();
    c.drawPath(puntaPath, Paint()..color = rojo);

    c.drawCircle(
      Offset(cx, cy + 2 * e),
      radio,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4 * e),
    );
    c.drawCircle(Offset(cx, cy), radio, Paint()..color = rojo);
    c.drawCircle(
      Offset(cx, cy),
      radio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * e
        ..color = Colors.white,
    );
    final pin = _icono(Icons.place_rounded, size: 19 * e, color: Colors.white);
    pin.paint(c, Offset(cx - pin.width / 2, cy - pin.height / 2));

    return _aPng(rec, ancho, alto);
  }

  /// Marcador del repartidor: círculo oscuro con moto y halo suave. Se ancla al CENTRO.
  static Future<Uint8List> repartidor() async {
    const e = escala;
    const lado = 64 * e;
    const centro = Offset(lado / 2, lado / 2);

    final rec = ui.PictureRecorder();
    final c = Canvas(rec);

    c.drawCircle(centro, 30 * e, Paint()..color = AppColors.primary.withValues(alpha: 0.16));
    c.drawCircle(
      centro + const Offset(0, 1.5 * e),
      17 * e,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3 * e),
    );
    c.drawCircle(centro, 17 * e, Paint()..color = AppColors.primaryDark);
    c.drawCircle(
      centro,
      17 * e,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * e
        ..color = Colors.white,
    );
    final moto = _icono(Icons.two_wheeler_rounded, size: 19 * e, color: Colors.white);
    moto.paint(c, Offset(centro.dx - moto.width / 2, centro.dy - moto.height / 2));

    return _aPng(rec, lado, lado);
  }
}