import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

enum Haptico { ninguno, seleccion, ligero, medio }

/// Envuelve cualquier widget tocable: escala 0.97 al presionar + háptico.
class Presionable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Haptico haptico;
  final double escala;
  final String? etiquetaSemantica;

  const Presionable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.haptico = Haptico.seleccion,
    this.escala = 0.97,
    this.etiquetaSemantica,
  });

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _presionado = false;

  void _setPresionado(bool v) {
    if (widget.onTap == null || _presionado == v) return;
    setState(() => _presionado = v);
  }

  void _vibrar() {
    switch (widget.haptico) {
      case Haptico.ninguno:
        break;
      case Haptico.seleccion:
        HapticFeedback.selectionClick();
      case Haptico.ligero:
        HapticFeedback.lightImpact();
      case Haptico.medio:
        HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.etiquetaSemantica,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPresionado(true),
        onTapUp: (_) => _setPresionado(false),
        onTapCancel: () => _setPresionado(false),
        onTap: widget.onTap == null
            ? null
            : () {
                _vibrar();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _presionado ? widget.escala : 1,
          duration: const Duration(milliseconds: 120),
          curve: AppMotion.curva,
          child: widget.child,
        ),
      ),
    );
  }
}