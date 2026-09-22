import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

class PizzaLoading extends StatefulWidget {
  final double size;
  final String? mensaje;
  const PizzaLoading({super.key, this.size = 110, this.mensaje});

  @override
  State<PizzaLoading> createState() => _PizzaLoadingState();
}

class _PizzaLoadingState extends State<PizzaLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
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
          const SizedBox(height: 12),
          Text(widget.mensaje!, style: const TextStyle(color: AppColors.gray, fontSize: 13)),
        ],
      ],
    );
  }
}

class _PizzaPainter extends CustomPainter {
  final double t;
  _PizzaPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    const slices = 8;
    final sliceAngle = 2 * math.pi / slices;

    for (int i = 0; i < slices; i++) {
      final delay = i / slices;
      double local = (t - delay) % 1.0;
      if (local < 0) local += 1;
      final opacity = local < 0.5 ? (0.15 + 0.85 * (local / 0.5)) : (1.0 - 0.85 * ((local - 0.5) / 0.5));

      final paint = Paint()..color = AppColors.warning.withValues(alpha: opacity.clamp(0.12, 1.0));

      final startAngle = -math.pi / 2 + i * sliceAngle;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius), startAngle, sliceAngle, false)
        ..close();
      canvas.drawPath(path, paint);

      final midAngle = startAngle + sliceAngle / 2;
      final dotCenter = center + Offset(math.cos(midAngle), math.sin(midAngle)) * (radius * 0.55);
      canvas.drawCircle(
        dotCenter,
        radius * 0.07,
        Paint()..color = AppColors.primary.withValues(alpha: (opacity * 0.9).clamp(0.1, 0.9)),
      );
    }

    canvas.drawCircle(center, radius * 0.06, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter oldDelegate) => oldDelegate.t != t;
}