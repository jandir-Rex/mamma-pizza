import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

/// Muestra al CLIENTE el código de 4 dígitos que debe dictarle al repartidor.
/// Solo es visible con canal DELIVERY + estado EN_CAMINO + código generado.
class CodigoEntregaCard extends StatefulWidget {
  final String? codigo;
  final String estado;
  final String canal;
  final int intentosFallidos;
  final int maxIntentos;

  const CodigoEntregaCard({
    super.key,
    required this.codigo,
    required this.estado,
    required this.canal,
    this.intentosFallidos = 0,
    this.maxIntentos = 3,
  });

  @override
  State<CodigoEntregaCard> createState() => _CodigoEntregaCardState();
}

class _CodigoEntregaCardState extends State<CodigoEntregaCard> {
  bool _oculto = false;

  bool get _visible =>
      widget.canal == "DELIVERY" &&
      widget.estado == "EN_CAMINO" &&
      widget.codigo != null &&
      widget.codigo!.length == 4;

  bool get _bloqueado => widget.intentosFallidos >= widget.maxIntentos;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final digitos = widget.codigo!.split("");

    return Semantics(
      container: true,
      label: _oculto ? "Código de entrega oculto" : "Código de entrega ${digitos.join(' ')}",
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Tu código de entrega",
                    style: TextStyle(color: AppColors.dark, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: _oculto ? "Mostrar código" : "Ocultar código",
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _oculto = !_oculto),
                  icon: Icon(
                    _oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.gray,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Díctaselo al repartidor cuando llegue con tu pedido. "
              "No lo compartas antes: así confirmamos que la entrega es tuya.",
              style: TextStyle(color: AppColors.gray, fontSize: 12.5, height: 1.35),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final d in digitos)
                  Container(
                    width: 52,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _oculto ? "•" : d,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _oculto
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: widget.codigo!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Código copiado"), duration: Duration(seconds: 1)),
                        );
                      },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text("Copiar"),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
            if (_bloqueado) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "El repartidor agotó los intentos. Comunícate con el local para que reinicien tu código.",
                  style: TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner que aparece cuando el pedido se entregó validando el código.
class EntregaConfirmadaBanner extends StatelessWidget {
  final String estado;
  final DateTime? confirmadoEn;

  const EntregaConfirmadaBanner({
    super.key,
    required this.estado,
    required this.confirmadoEn,
  });

  @override
  Widget build(BuildContext context) {
    if (estado != "ENTREGADO" || confirmadoEn == null) return const SizedBox.shrink();
    final h = confirmadoEn!.hour.toString().padLeft(2, "0");
    final m = confirmadoEn!.minute.toString().padLeft(2, "0");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Entrega confirmada con tu código a las $h:$m. ¡Buen provecho!",
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}