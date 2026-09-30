import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

class PizzaLoading extends StatefulWidget {
  final double size;
  final String? mensaje;
  const PizzaLoading({super.key, this.size = 120, this.mensaje});

  @override
  State<PizzaLoading> createState() => _PizzaLoadingState();
}

class _PizzaLoadingState extends State<PizzaLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(painter: _PizzaPainter(_controller.value)),
          ),
        ),
        if (widget.mensaje != null) ...[
          const SizedBox(height: 14),
          Text(widget.mensaje!, style: const TextStyle(color: AppColors.gray, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class _PizzaPainter extends CustomPainter {
  final double t;
  _PizzaPainter(this.t);

  static const _crustColor = Color(0xFFE0A55C);
  static const _crustDark = Color(0xFFC17D3A);
  static const _cheeseColor = Color(0xFFF6C24C);
  static const _sauceColor = Color(0xFFB8432E);
  static const _pepperoniColor = Color(0xFFA6321F);
  static const int slices = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final sliceAngle = 2 * math.pi / slices;

    // Leve "respiración" de escala, como si la pizza saliera del horno
    final escala = 0.97 + 0.03 * math.sin(t * 2 * math.pi);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(escala);
    canvas.translate(-center.dx, -center.dy);

    // Borde de masa (crust) completo, siempre visible de fondo
    canvas.drawCircle(center, radius, Paint()..color = _crustColor);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _crustDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Base de queso/salsa completa (más tenue) para que nunca se vea "vacía"
    canvas.drawCircle(center, radius * 0.88, Paint()..color = _sauceColor.withValues(alpha: 0.18));

    for (int i = 0; i < slices; i++) {
      final delay = i / slices;
      double local = (t - delay) % 1.0;
      if (local < 0) local += 1;
      // curva suave: sube rápido, se mantiene, baja rápido
      final opacity = local < 0.45
          ? Curves.easeOut.transform(local / 0.45)
          : local < 0.7
              ? 1.0
              : Curves.easeIn.transform(1 - (local - 0.7) / 0.3);

      final startAngle = -math.pi / 2 + i * sliceAngle;

      // Queso derretido de la tajada
      final paintQueso = Paint()..color = _cheeseColor.withValues(alpha: (0.25 + 0.75 * opacity).clamp(0.0, 1.0));
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius * 0.88), startAngle, sliceAngle, false)
        ..close();
      canvas.drawPath(path, paintQueso);

      // Línea divisoria de la tajada
      canvas.drawLine(
        center,
        center + Offset(math.cos(startAngle), math.sin(startAngle)) * radius * 0.88,
        Paint()
          ..color = _crustDark.withValues(alpha: 0.25)
          ..strokeWidth = 1.4,
      );

      // Pepperoni (2 por tajada, tamaño ligeramente distinto para look orgánico)
      final midAngle = startAngle + sliceAngle / 2;
      for (final f in [0.38, 0.68]) {
        final posAngle = midAngle + (f == 0.38 ? -0.09 : 0.11);
        final dotCenter = center + Offset(math.cos(posAngle), math.sin(posAngle)) * (radius * f);
        canvas.drawCircle(
          dotCenter,
          radius * 0.085,
          Paint()..color = _pepperoniColor.withValues(alpha: (opacity * 0.95).clamp(0.0, 0.95)),
        );
        canvas.drawCircle(
          dotCenter,
          radius * 0.085,
          Paint()
            ..color = Colors.black.withValues(alpha: opacity * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // Centro (donde se juntan las tajadas)
    canvas.drawCircle(center, radius * 0.05, Paint()..color = _crustDark);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter oldDelegate) => oldDelegate.t != t;
}