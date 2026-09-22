import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../models/pedido.dart';
import '../services/pedidos_service.dart';
import 'seguimiento_screen.dart';

class PedidosHistorialScreen extends StatefulWidget {
  const PedidosHistorialScreen({super.key});

  @override
  State<PedidosHistorialScreen> createState() => _PedidosHistorialScreenState();
}

class _PedidosHistorialScreenState extends State<PedidosHistorialScreen> {
  List<Pedido> _pedidos = [];
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
      final pedidos = await PedidosService.misPedidos();
      if (!mounted) return;
      setState(() => _pedidos = pedidos);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis pedidos")),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _pedidos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🍕", style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text("Todavía no tienes pedidos",
                          style: TextStyle(color: AppColors.gray, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pedidos.length,
                    itemBuilder: (context, index) {
                      final p = _pedidos[index];
                      final color = EstadoPedidoUI.color(p.estado);
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(deslizarDesdeDerecha(SeguimientoScreen(pedidoId: p.id)));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(p.codigo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      EstadoPedidoUI.etiqueta(p.estado),
                                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(p.canal == "DELIVERY" ? Icons.delivery_dining : Icons.storefront,
                                      size: 16, color: AppColors.gray),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${p.canal == "DELIVERY" ? "Delivery" : "Recojo en local"} · ${p.cantidadItems} items",
                                    style: const TextStyle(color: AppColors.gray, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}",
                                    style: const TextStyle(color: AppColors.gray, fontSize: 12),
                                  ),
                                  Text("S/. ${p.total.toStringAsFixed(2)}",
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}