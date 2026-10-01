import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/pedido.dart';
import '../services/pedidos_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/seguimiento_pedido_widget.dart';

class PedidosHistorialScreen extends StatefulWidget {
  const PedidosHistorialScreen({super.key});

  @override
  State<PedidosHistorialScreen> createState() => _PedidosHistorialScreenState();
}

class _PedidosHistorialScreenState extends State<PedidosHistorialScreen> {
  List<Pedido> _pedidos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // Obtener el usuario actual para verificar autenticación
      final authProvider = context.read<AuthProvider>();
      final usuario = authProvider.usuario;
      
      if (usuario == null) {
        setState(() {
          _error = "No estás autenticado";
          _cargando = false;
        });
        return;
      }

      print('📦 Cargando pedidos para usuario: ${usuario.email}');
      
      // Obtener todos los pedidos
      final pedidos = await PedidosService.misPedidos();
      
      print('✅ Se obtuvieron ${pedidos.length} pedidos');
      
      // Ordenar por fecha (más reciente primero)
      pedidos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _pedidos = pedidos;
          _cargando = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar pedidos: $e');
      if (mounted) {
        setState(() {
          _error = "Error al cargar pedidos: $e";
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Text(
                    "Mis pedidos",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _cargarPedidos,
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(color: AppColors.danger),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _cargarPedidos,
                                child: const Text("Reintentar"),
                              ),
                            ],
                          ),
                        )
                      : _pedidos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("🍕", style: TextStyle(fontSize: 64)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Todavía no tienes pedidos",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Realiza tu primer pedido para verlo aquí",
                                    style: TextStyle(color: AppColors.gray),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarPedidos,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                                itemCount: _pedidos.length,
                                itemBuilder: (context, index) {
                                  final pedido = _pedidos[index];
                                  return _TarjetaPedido(pedido: pedido);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPedido extends StatelessWidget {
  final Pedido pedido;

  const _TarjetaPedido({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final colorEstado = EstadoPedidoUI.color(pedido.estado);
    final esActivo = pedido.estado != "ENTREGADO" && pedido.estado != "CANCELADO";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Si es pedido activo, mostrar seguimiento completo
          if (esActivo)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SeguimientoPedidoWidget(
                pedido: pedido,
                onVerDetalles: () {
                  // Aquí puedes navegar al detalle completo
                },
              ),
            )
          else
            // Si es pedido completado/cancelado, mostrar versión simplificada
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Pedido #${pedido.codigo}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorEstado.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          EstadoPedidoUI.etiqueta(pedido.estado),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorEstado,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        pedido.canal == "DELIVERY" ? Icons.delivery_dining : Icons.storefront,
                        size: 16,
                        color: AppColors.gray,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${pedido.canal == "DELIVERY" ? "Delivery" : "Recojo"} · ${pedido.cantidadItems} items",
                        style: const TextStyle(color: AppColors.gray, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${pedido.createdAt.day}/${pedido.createdAt.month}/${pedido.createdAt.year}",
                        style: const TextStyle(color: AppColors.gray, fontSize: 12),
                      ),
                      Text(
                        "S/. ${pedido.total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
