import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../widgets/presionable.dart';
import '../widgets/ui_comunes.dart';
import 'seguimiento_screen.dart';
import 'main_shell.dart';

class PedidoExitoScreen extends StatefulWidget {
  final int pedidoId;
  final String codigo;
  const PedidoExitoScreen({super.key, required this.pedidoId, required this.codigo});

  @override
  State<PedidoExitoScreen> createState() => _PedidoExitoScreenState();
}

class _PedidoExitoScreenState extends State<PedidoExitoScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  void _copiarCodigo() {
    Clipboard.setData(ClipboardData(text: widget.codigo));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text("Código copiado")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _CheckAnimado(),
                      const SizedBox(height: 24),
                      Aparecer(
                        indice: 3,
                        child: Text(
                          "¡Pedido recibido!",
                          textAlign: TextAlign.center,
                          style: AppFonts.marca(size: 32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Aparecer(
                        indice: 4,
                        child: Text(
                          "Te avisaremos apenas confirmemos tu pago",
                          textAlign: TextAlign.center,
                          style: AppFonts.cuerpo(size: 14, color: AppColors.gray, altura: 1.4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Aparecer(indice: 5, child: _Ticket(codigo: widget.codigo, onCopiar: _copiarCodigo)),
                      const SizedBox(height: 20),
                      const Aparecer(indice: 6, child: _QueSigue()),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BotonPrincipal(
                    texto: "Ver seguimiento",
                    icono: Icons.delivery_dining,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        deslizarDesdeDerecha(SeguimientoScreen(pedidoId: widget.pedidoId)),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        desvanecer(const MainShell()),
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gray,
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text("Volver al menú"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Check con rebote elástico y halo que se expande.
class _CheckAnimado extends StatelessWidget {
  const _CheckAnimado();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Pedido recibido",
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, v, _) {
          final halo = Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
          return SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (1 - halo).clamp(0.0, 1.0) * 0.6 + 0.15,
                  child: Container(
                    width: 100 + 40 * halo,
                    height: 100 + 40 * halo,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.albahaca.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: v,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.albahaca,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.brillo(AppColors.albahaca),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Ticket kraft con el código del pedido.
class _Ticket extends StatelessWidget {
  final String codigo;
  final VoidCallback onCopiar;
  const _Ticket({required this.codigo, required this.onCopiar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      decoration: BoxDecoration(
        gradient: AppGradients.kraft,
        borderRadius: AppRadius.bMedio,
        border: Border.all(color: AppColors.kraftDark.withValues(alpha: 0.6)),
        boxShadow: AppShadows.suave,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tu código de pedido",
                  style: AppFonts.cuerpo(size: 12, peso: FontWeight.w600, color: AppColors.cacaoDark),
                ),
                const SizedBox(height: 2),
                Text(
                  codigo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.titulo(size: 38, color: AppColors.cacaoDark),
                ),
              ],
            ),
          ),
          Presionable(
            onTap: onCopiar,
            etiquetaSemantica: "Copiar código",
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.copy_rounded, color: AppColors.cacaoDark, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueSigue extends StatelessWidget {
  const _QueSigue();

  @override
  Widget build(BuildContext context) {
    const pasos = [
      (Icons.verified_outlined, "Confirmamos tu pedido"),
      (Icons.local_pizza_outlined, "Lo preparamos al momento"),
      (Icons.delivery_dining, "Te lo llevamos a tu puerta"),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.bMedio,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("¿Qué sigue?", style: AppFonts.titulo(size: 22)),
          const SizedBox(height: 12),
          for (var i = 0; i < pasos.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == pasos.length - 1 ? 0 : 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.kraftLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(pasos[i].$1, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pasos[i].$2,
                      style: AppFonts.cuerpo(size: 14, peso: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}