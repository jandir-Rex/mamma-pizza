import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/pedido.dart';
import 'codigo_entrega_card.dart';

String _hora(DateTime d) {
  final l = d.toLocal();
  return "${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}";
}

/// Contenido de la pantalla "Mi pedido" (igual al diseño).
class SeguimientoPedido extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback? onVerDetalles;
  const SeguimientoPedido({super.key, required this.pedido, this.onVerDetalles});

  static const _pasosDelivery = ["CONFIRMADO", "EN_PREPARACION", "EN_CAMINO", "ENTREGADO"];
  static const _pasosSalon = ["CONFIRMADO", "EN_PREPARACION", "ENTREGADO"];

  static const _nombrePaso = {
    "CONFIRMADO": "Confirmado",
    "EN_PREPARACION": "Preparando",
    "EN_CAMINO": "En camino",
    "ENTREGADO": "Entregado",
  };

  static const _iconoPaso = {
    "CONFIRMADO": Icons.receipt_long,
    "EN_PREPARACION": Icons.local_pizza,
    "EN_CAMINO": Icons.delivery_dining,
    "ENTREGADO": Icons.check,
  };

  static const _titulos = {
    "PENDIENTE_PAGO": "Pendiente de pago",
    "CONFIRMADO": "Pedido confirmado",
    "EN_PREPARACION": "Preparando tu pedido",
    "EN_CAMINO": "En camino",
    "ENTREGADO": "Entregado",
    "CANCELADO": "Pedido cancelado",
  };

  static const _subtitulos = {
    "PENDIENTE_PAGO": "Estamos esperando tu pago",
    "CONFIRMADO": "Recibimos tu pedido",
    "EN_PREPARACION": "Tu pizza está en el horno",
    "EN_CAMINO": "Tu pedido está en camino",
    "ENTREGADO": "¡Buen provecho!",
    "CANCELADO": "Este pedido fue cancelado",
  };

  static const _iconoEstado = {
    "PENDIENTE_PAGO": Icons.hourglass_top,
    "CONFIRMADO": Icons.receipt_long,
    "EN_PREPARACION": Icons.local_pizza,
    "EN_CAMINO": Icons.delivery_dining,
    "ENTREGADO": Icons.check_circle_outline,
    "CANCELADO": Icons.close,
  };

  @override
  Widget build(BuildContext context) {
    final esDelivery = pedido.canal == "DELIVERY";
    final pasos = esDelivery ? _pasosDelivery : _pasosSalon;
    final cancelado = pedido.estado == "CANCELADO";
    final entregado = pedido.estado == "ENTREGADO";
    final indice = pasos.indexOf(pedido.estado);
    final colorEstado = cancelado
        ? AppColors.danger
        : entregado
            ? AppColors.success
            : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado actual
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: colorEstado, borderRadius: BorderRadius.circular(16)),
              child: Icon(_iconoEstado[pedido.estado] ?? Icons.receipt_long, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titulos[pedido.estado] ?? pedido.estado,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorEstado),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitulos[pedido.estado] ?? "",
                    style: const TextStyle(fontSize: 13, color: AppColors.gray),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (!cancelado) ...[
          const SizedBox(height: 24),
          _Pasos(pasos: pasos, indice: indice, creado: pedido.createdAt),
        ],

        // Código de entrega (solo delivery en camino)
        if (esDelivery && pedido.estado == "EN_CAMINO") ...[
          const SizedBox(height: 22),
          CodigoEntregaCard(
            codigo: pedido.codigoConfirmacion,
            estado: pedido.estado,
            canal: pedido.canal,
            intentosFallidos: pedido.intentosCodigoFallidos,
          ),
        ],

        // Confirmación posterior a la entrega
        if (entregado && pedido.confirmadoEn != null) ...[
          const SizedBox(height: 22),
          EntregaConfirmadaBanner(estado: pedido.estado, confirmadoEn: pedido.confirmadoEn),
        ],

        // Mapa (solo delivery en camino)
        if (esDelivery && pedido.estado == "EN_CAMINO") ...[
          const SizedBox(height: 22),
          const _Mapa(minutos: "15 min"),
        ],

        const SizedBox(height: 24),
        const Text("Detalle del pedido", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark)),
        const SizedBox(height: 10),
        _Detalle(pedido: pedido),

        if (onVerDetalles != null) ...[
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onVerDetalles,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFFBE4E0),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Ver detalles",
                style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Pasos extends StatelessWidget {
  final List<String> pasos;
  final int indice;
  final DateTime creado;
  const _Pasos({required this.pasos, required this.indice, required this.creado});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final seg = c.maxWidth / pasos.length;
        return Stack(
          children: [
            Positioned(
              left: seg / 2,
              top: 15,
              child: Container(width: seg * (pasos.length - 1), height: 3, color: AppColors.hairline),
            ),
            if (indice > 0)
              Positioned(
                left: seg / 2,
                top: 15,
                child: Container(width: seg * indice, height: 3, color: AppColors.primary),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < pasos.length; i++)
                  SizedBox(
                    width: seg,
                    child: Column(
                      children: [
                        _circulo(pasos[i], hecho: i <= indice, actual: i == indice),
                        const SizedBox(height: 8),
                        Text(
                          SeguimientoPedido._nombrePaso[pasos[i]] ?? pasos[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: i <= indice ? FontWeight.w700 : FontWeight.w500,
                            color: i <= indice ? AppColors.dark : AppColors.gray,
                          ),
                        ),
                        if (i == 0)
                          Text(_hora(creado), style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _circulo(String paso, {required bool hecho, required bool actual}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hecho ? AppColors.primary : Colors.white,
        border: Border.all(color: hecho ? AppColors.primary : AppColors.hairline, width: 2),
        boxShadow: actual
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
      child: Icon(
        SeguimientoPedido._iconoPaso[paso] ?? Icons.circle,
        size: 16,
        color: hecho ? Colors.white : AppColors.lightGray,
      ),
    );
  }
}

class _Mapa extends StatelessWidget {
  final String minutos;
  const _Mapa({required this.minutos});

  Widget _burbuja(IconData icono) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Icon(icono, color: AppColors.primary, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEFE7DB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _MapaPainter())),
              Positioned(left: w * 0.2 - 21, top: h * 0.28 - 21, child: _burbuja(Icons.delivery_dining)),
              Positioned(left: w * 0.82 - 21, top: h * 0.3 - 21, child: _burbuja(Icons.home)),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Tiempo estimado", style: TextStyle(fontSize: 11, color: AppColors.gray)),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(minutos, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.dark)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final calle = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 9;
    for (double x = s.width * 0.1; x < s.width; x += s.width * 0.21) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), calle);
    }
    for (double y = s.height * 0.12; y < s.height; y += s.height * 0.28) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), calle);
    }

    final ruta = Path()
      ..moveTo(s.width * 0.2, s.height * 0.28)
      ..lineTo(s.width * 0.2, s.height * 0.55)
      ..lineTo(s.width * 0.82, s.height * 0.55)
      ..lineTo(s.width * 0.82, s.height * 0.3);
    final trazo = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final m in ruta.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 7), trazo);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Detalle extends StatelessWidget {
  final Pedido pedido;
  const _Detalle({required this.pedido});

  @override
  Widget build(BuildContext context) {
    const gris = TextStyle(fontSize: 13, color: AppColors.gray);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          for (final it in pedido.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(it.nombre, style: gris, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text("x${it.cantidad}", style: gris),
                  const SizedBox(width: 18),
                  Text("S/. ${it.subtotal.toStringAsFixed(2)}", style: gris),
                ],
              ),
            ),
          const Divider(height: 18),
          Row(
            children: [
              const Text("Total", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const Spacer(),
              Text(
                "S/. ${pedido.total.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}