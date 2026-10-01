import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/pedido.dart';
import '../services/pedidos_service.dart';
import '../services/socket_service.dart';
import '../widgets/pizza_loading.dart';
import '../widgets/seguimiento_widgets.dart';

class SeguimientoScreen extends StatefulWidget {
  final int pedidoId;
  const SeguimientoScreen({super.key, required this.pedidoId});

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  Pedido? _pedido;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
    _escucharSocket();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final pedido = await PedidosService.obtenerPorId(widget.pedidoId);
      if (!mounted) return;
      setState(() => _pedido = pedido);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _escucharSocket() async {
    final socket = await SocketService.conectar();
    if (socket == null) return;
    socket.emit("pedido:seguir", widget.pedidoId);
    socket.on("pedido:actualizado", (data) {
      if (mounted && data["id"] == widget.pedidoId) _cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Mi pedido", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        actions: [
          if (_pedido != null)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE6DA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("#${_pedido!.codigo}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray)),
                ),
              ),
            ),
        ],
      ),
      body: _cargando && _pedido == null
          ? const Center(child: PizzaLoading(mensaje: "Cargando tu pedido..."))
          : _pedido == null
              ? const Center(child: Text("No se pudo cargar el pedido"))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [SeguimientoPedido(pedido: _pedido!)],
                  ),
                ),
    );
  }
}
