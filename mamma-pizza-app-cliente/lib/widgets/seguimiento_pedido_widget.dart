import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/pedido.dart';

class SeguimientoPedidoWidget extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback? onVerDetalles;

  const SeguimientoPedidoWidget({
    super.key,
    required this.pedido,
    this.onVerDetalles,
  });

  static const Map<String, String> _titulos = {
    "PENDIENTE_PAGO": "Pendiente de pago",
    "CONFIRMADO": "Pedido confirmado",
    "EN_PREPARACION": "Preparando tu pedido",
    "EN_CAMINO": "En camino",
    "ENTREGADO": "Entregado",
    "CANCELADO": "Pedido cancelado",
  };

  static const Map<String, String> _subtitulos = {
    "PENDIENTE_PAGO": "Estamos esperando tu pago",
    "CONFIRMADO": "Recibimos tu pedido",
    "EN_PREPARACION": "Tu pizza está en el horno",
    "EN_CAMINO": "Tu pedido está en camino",
    "ENTREGADO": "¡Buen provecho!",
    "CANCELADO": "Este pedido fue cancelado",
  };

  static const Map<String, IconData> _iconos = {
    "PENDIENTE_PAGO": Icons.hourglass_top,
    "CONFIRMADO": Icons.receipt_long,
    "EN_PREPARACION": Icons.local_pizza,
    "EN_CAMINO": Icons.delivery_dining,
    "ENTREGADO": Icons.check_circle_outline,
    "CANCELADO": Icons.close,
  };

  @override
  Widget build(BuildContext context) {
    final colorEstado = pedido.estado == "CANCELADO"
        ? AppColors.danger
        : pedido.estado == "ENTREGADO"
            ? AppColors.success
            : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta de estado
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorEstado.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorEstado,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconos[pedido.estado] ?? Icons.receipt_long,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titulos[pedido.estado] ?? pedido.estado,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorEstado,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitulos[pedido.estado] ?? "",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Timeline
        _Timeline(pedido: pedido),

        const SizedBox(height: 20),

        // Mapa (solo si está en camino)
        if (pedido.estado == "EN_CAMINO") ...[
          _MapaWidget(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairline),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  "Tiempo estimado",
                  style: TextStyle(color: AppColors.gray, fontSize: 12),
                ),
                Spacer(),
                Text(
                  "12 min",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Detalle del pedido
        const Text(
          "Detalle del pedido",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _DetalleWidget(pedido: pedido),

        if (onVerDetalles != null) ...[
          const SizedBox(height: 16),
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
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final Pedido pedido;
  const _Timeline({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final pasos = [
      ("Confirmado", "10:20", Icons.receipt_long),
      ("Preparando", "10:35", Icons.local_pizza),
      ("En camino", "11:05", Icons.delivery_dining),
      ("Entregado", null, Icons.check),
    ];

    final indiceActual = pedido.estado == "CONFIRMADO"
        ? 0
        : pedido.estado == "EN_PREPARACION"
            ? 1
            : pedido.estado == "EN_CAMINO"
                ? 2
                : pedido.estado == "ENTREGADO"
                    ? 3
                    : -1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final espacio = ancho / pasos.length;

        return Stack(
          children: [
            // Línea de fondo
            Positioned(
              left: espacio / 2,
              top: 15,
              child: Container(
                width: espacio * (pasos.length - 1),
                height: 3,
                color: AppColors.hairline,
              ),
            ),
            // Línea de progreso
            if (indiceActual > 0)
              Positioned(
                left: espacio / 2,
                top: 15,
                child: Container(
                  width: espacio * indiceActual,
                  height: 3,
                  color: AppColors.primary,
                ),
              ),
            // Círculos
            Row(
              children: List.generate(pasos.length, (i) {
                final hecho = i <= indiceActual;
                return SizedBox(
                  width: espacio,
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hecho ? AppColors.primary : Colors.white,
                          border: Border.all(
                            color: hecho ? AppColors.primary : AppColors.hairline,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          pasos[i].$3,
                          size: 16,
                          color: hecho ? Colors.white : AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pasos[i].$1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: hecho ? FontWeight.w700 : FontWeight.w500,
                          color: hecho ? AppColors.dark : AppColors.gray,
                        ),
                      ),
                      if (pasos[i].$2 != null)
                        Text(
                          pasos[i].$2!,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.gray,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _MapaWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.map, size: 60, color: AppColors.lightGray),
          ),
          Positioned(
            left: 30,
            top: 60,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: 40,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.home,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleWidget extends StatelessWidget {
  final Pedido pedido;
  const _DetalleWidget({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          for (final item in pedido.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.nombre,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    "x${item.cantidad}",
                    style: const TextStyle(
                      color: AppColors.gray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "S/. ${item.subtotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          Row(
            children: [
              const Text(
                "Total",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                "S/. ${pedido.total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
