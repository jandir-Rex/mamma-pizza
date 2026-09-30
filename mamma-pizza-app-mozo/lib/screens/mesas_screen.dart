import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/mesa.dart';
import '../services/mesas_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/pizza_loading.dart';
import 'tomar_pedido_screen.dart';
import 'login_screen.dart';

class MesasScreen extends StatefulWidget {
  const MesasScreen({super.key});

  @override
  State<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends State<MesasScreen> {
  List<Mesa> _mesas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final mesas = await MesasService.estado();
      if (!mounted) return;
      setState(() => _mesas = mesas);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis mesas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              }
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: PizzaLoading(mensaje: "Cargando mesas..."))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: AppColors.primary,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text("¡Hola, ${usuario?.nombre.split(' ').first ?? ''}! 👋",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: _mesas.length,
                      itemBuilder: (context, index) {
                        final mesa = _mesas[index];
                        return _TarjetaMesa(
                          mesa: mesa,
                          onTap: () async {
                            if (!mesa.ocupada) {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => TomarPedidoScreen(mesa: mesa)),
                              );
                              _cargar();
                            } else {
                              _mostrarResumen(context, mesa);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _mostrarResumen(BuildContext context, Mesa mesa) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mesa ${mesa.numero}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Pedido: ${mesa.pedidoActivo?.codigo ?? '-'}", style: const TextStyle(color: AppColors.gray)),
            Text("Estado: ${mesa.pedidoActivo?.estado ?? '-'}", style: const TextStyle(color: AppColors.gray)),
            const SizedBox(height: 12),
            const Text(
              "Este pedido ya fue enviado y está en manos de caja/cocina. No se puede editar desde aquí.",
              style: TextStyle(fontSize: 12, color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaMesa extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onTap;
  const _TarjetaMesa({required this.mesa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = mesa.ocupada ? AppColors.primary : AppColors.success;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.4),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.table_restaurant, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text("Mesa ${mesa.numero}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.dark)),
              const SizedBox(height: 4),
              Text(
                mesa.ocupada ? (mesa.pedidoActivo?.codigo ?? "Ocupada") : "Libre",
                style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}