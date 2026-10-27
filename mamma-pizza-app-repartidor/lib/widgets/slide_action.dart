import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

/// Botón "desliza para confirmar". Evita toques accidentales en acciones importantes.
class SlideAction extends StatefulWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final Future<void> Function() onCompletado;

  const SlideAction({
    super.key,
    required this.texto,
    required this.onCompletado,
    this.icono = Icons.two_wheeler_rounded,
    this.color = AppColors.primary,
  });

  @override
  State<SlideAction> createState() => _SlideActionState();
}

class _SlideActionState extends State<SlideAction> with SingleTickerProviderStateMixin {
  static const double _alto = 62;
  static const double _perilla = 54;

  late final AnimationController _ctrl;
  double _x = 0;
  double _origen = 0;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() => setState(() => _x = _origen * (1 - Curves.easeOutCubic.transform(_ctrl.value))));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _soltar(double recorrido) async {
    if (_x >= recorrido * 0.85) {
      HapticFeedback.mediumImpact();
      setState(() {
        _x = recorrido;
        _procesando = true;
      });
      try {
        await widget.onCompletado();
      } finally {
        if (mounted) {
          setState(() {
            _procesando = false;
            _x = 0;
          });
        }
      }
    } else {
      _origen = _x;
      _ctrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return LayoutBuilder(builder: (context, c) {
      final recorrido = (c.maxWidth - _perilla - 8).clamp(1.0, double.infinity).toDouble();
      final progreso = (_x / recorrido).clamp(0.0, 1.0).toDouble();

      return Container(
        height: _alto,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(_alto / 2),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Stack(
          children: [
            // Relleno que sigue a la perilla
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: _perilla + 8 + _x,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(_alto / 2),
                  ),
                ),
              ),
            ),
            // Texto (se desvanece al deslizar)
            Center(
              child: Opacity(
                opacity: 1 - progreso,
                child: Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    widget.texto,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                ),
              ),
            ),
            // Perilla
            Positioned(
              left: 4 + _x,
              top: 4,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  if (_procesando) return;
                  setState(() => _x = (_x + d.delta.dx).clamp(0.0, recorrido).toDouble());
                },
                onHorizontalDragEnd: (_) {
                  if (!_procesando) _soltar(recorrido);
                },
                child: Container(
                  width: _perilla,
                  height: _perilla,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: _procesando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Icon(widget.icono, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}