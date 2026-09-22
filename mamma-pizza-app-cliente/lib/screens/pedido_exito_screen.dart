import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import 'seguimiento_screen.dart';
import 'main_shell.dart';

class PedidoExitoScreen extends StatelessWidget {
  final int pedidoId;
  final String codigo;
  const PedidoExitoScreen({super.key, required this.pedidoId, required this.codigo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 46),
              ),
              const SizedBox(height: 24),
              const Text("¡Pedido recibido!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 8),
              Text("Código: $codigo", style: const TextStyle(color: AppColors.gray, fontSize: 14)),
              const SizedBox(height: 4),
              const Text("Te avisaremos apenas confirmemos tu pago",
                  style: TextStyle(color: AppColors.gray, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(deslizarDesdeDerecha(SeguimientoScreen(pedidoId: pedidoId)));
                },
                child: const Text("Ver seguimiento"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(desvanecer(const MainShell()), (route) => false);
                },
                child: const Text("Volver al menú", style: TextStyle(color: AppColors.gray)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}