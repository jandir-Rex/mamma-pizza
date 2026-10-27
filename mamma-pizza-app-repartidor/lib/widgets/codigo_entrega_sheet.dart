import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_config.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/entrega.dart';
import '../providers/entregas_provider.dart';

/// Devuelve true si la entrega quedó confirmada.
Future<bool?> mostrarCodigoEntrega(BuildContext context, Entrega entrega) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CodigoSheet(entrega: entrega),
  );
}

class _CodigoSheet extends StatefulWidget {
  final Entrega entrega;
  const _CodigoSheet({required this.entrega});

  @override
  State<_CodigoSheet> createState() => _CodigoSheetState();
}

class _CodigoSheetState extends State<_CodigoSheet> {
  final _ctrl = TextEditingController();
  final _foco = FocusNode();
  bool _enviando = false;
  bool _exito = false;
  bool _bloqueado = false;
  String? _error;
  int _fallosLocales = 0;

  @override
  void initState() {
    super.initState();
    _bloqueado = widget.entrega.bloqueada;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  int get _restantes => math.max(
        0,
        AppConfig.maxIntentosCodigo - widget.entrega.intentosCodigoFallidos - _fallosLocales,
      );

  Future<void> _confirmar() async {
    if (_ctrl.text.length != 4 || _enviando || _bloqueado) return;
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await context.read<EntregasProvider>().entregarConCodigo(widget.entrega, _ctrl.text);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _exito = true;
        _enviando = false;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final mensaje = mensajeError(e);
      final bloqueo = RegExp('bloque', caseSensitive: false).hasMatch(mensaje);
      final incorrecto = RegExp('incorrecto', caseSensitive: false).hasMatch(mensaje);
      HapticFeedback.heavyImpact();
      setState(() {
        _enviando = false;
        _error = mensaje;
        _ctrl.clear();
        if (bloqueo) {
          _bloqueado = true;
        } else if (incorrecto) {
          _fallosLocales++;
        }
      });
      if (!_bloqueado) _foco.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _exito
                  ? _vistaExito()
                  : _bloqueado
                      ? _vistaBloqueado()
                      : _vistaFormulario(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _asa() => Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
        ),
      );

  // ---------- Formulario ----------
  Widget _vistaFormulario() {
    final texto = _ctrl.text;
    return Column(
      key: const ValueKey("form"),
      mainAxisSize: MainAxisSize.min,
      children: [
        _asa(),
        const SizedBox(height: 20),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pin_outlined, color: AppColors.primary, size: 30),
        ),
        const SizedBox(height: 14),
        const Text("Confirmar entrega", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          "Pídele al cliente el código de 4 dígitos que le llegó a su app · ${widget.entrega.codigo}",
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.gray, fontSize: 12.5),
        ),
        const SizedBox(height: 22),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _foco.requestFocus,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _caja(i, texto),
                    ),
                ],
              ),
              // Campo real, invisible: captura el teclado numérico
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _foco,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    enableInteractiveSelection: false,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: (_restantes <= 1 ? AppColors.danger : AppColors.gray).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "$_restantes intento${_restantes == 1 ? '' : 's'} restante${_restantes == 1 ? '' : 's'}",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _restantes <= 1 ? AppColors.danger : AppColors.gray,
            ),
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: (_ctrl.text.length == 4 && !_enviando) ? _confirmar : null,
          child: _enviando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : const Text("Confirmar entrega"),
        ),
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text("Cancelar", style: TextStyle(color: AppColors.gray)),
        ),
      ],
    );
  }

  Widget _caja(int i, String texto) {
    final lleno = i < texto.length;
    final activa = i == texto.length;
    final hayError = _error != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 62,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lleno ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hayError
              ? AppColors.danger.withValues(alpha: 0.6)
              : activa
                  ? AppColors.primary
                  : AppColors.border,
          width: activa ? 2 : 1.4,
        ),
      ),
      child: Text(
        lleno ? texto[i] : "",
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.dark),
      ),
    );
  }

  // ---------- Éxito ----------
  Widget _vistaExito() {
    return Padding(
      key: const ValueKey("exito"),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(gradient: AppGradients.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: 18),
          const Text("¡Entrega confirmada!", style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text("Buen trabajo 🛵", style: TextStyle(color: AppColors.gray)),
        ],
      ),
    );
  }

  // ---------- Bloqueado ----------
  Widget _vistaBloqueado() {
    return Column(
      key: const ValueKey("bloqueado"),
      mainAxisSize: MainAxisSize.min,
      children: [
        _asa(),
        const SizedBox(height: 22),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.10), shape: BoxShape.circle),
          child: const Icon(Icons.lock_rounded, color: AppColors.danger, size: 30),
        ),
        const SizedBox(height: 14),
        const Text("Entrega bloqueada", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          "Agotaste los ${AppConfig.maxIntentosCodigo} intentos. Llama al local para que reinicien el código de ${widget.entrega.codigo}.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.gray, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => abrirLlamada(AppConfig.telefonoLocal),
          icon: const Icon(Icons.call_rounded),
          label: const Text("Llamar al local"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cerrar", style: TextStyle(color: AppColors.gray)),
        ),
      ],
    );
  }
}