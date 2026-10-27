import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io_client;
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
  static const _respaldo = Duration(seconds: 30);

  Pedido? _pedido;
  bool _cargando = true;
  bool _fallo = false;

  io_client.Socket? _socket;
  Timer? _debounce;
  Timer? _timerRespaldo;

  @override
  void initState() {
    super.initState();
    _cargar();
    _escucharSocket();

    // Red de seguridad: si el socket falla o la app estuvo en segundo plano,
    // el estado y el código se refrescan solos mientras el pedido siga activo.
    _timerRespaldo = Timer.periodic(_respaldo, (_) {
      if (_pedido?.activo ?? true) _cargar(silencioso: true);
    });
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!mounted) return;
    if (!silencioso) setState(() => _cargando = true);
    try {
      final pedido = await PedidosService.obtenerPorId(widget.pedidoId);
      if (!mounted) return;
      setState(() {
        _pedido = pedido;
        _fallo = false;
      });
    } catch (_) {
      if (mounted && _pedido == null) setState(() => _fallo = true);
    } finally {
      if (mounted && !silencioso) setState(() => _cargando = false);
    }
  }

  Future<void> _escucharSocket() async {
    final socket = await SocketService.conectar();
    if (socket == null || !mounted) return;
    _socket = socket;

    socket.on("connect", _alConectar);
    socket.on("pedido:actualizado", _alActualizar);

    // Si ya estaba conectado, 'connect' no volverá a dispararse
    if (socket.connected) _alConectar(null);
  }

  // Al conectar y RE-conectar: hay que volver a unirse a la sala del pedido
  // y traer lo que pasó mientras estuvo desconectado.
  void _alConectar(dynamic _) {
    _socket?.emit("pedido:seguir", widget.pedidoId);
    if (mounted) _cargar(silencioso: true);
  }

  void _alActualizar(dynamic data) {
    final id = data is Map ? data["id"] : null;
    if (id != widget.pedidoId) return;
    // Varios eventos seguidos => una sola recarga
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _cargar(silencioso: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _timerRespaldo?.cancel();
    _socket?.off("connect", _alConectar);
    _socket?.off("pedido:actualizado", _alActualizar);
    super.dispose();
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
                  child: Text(
                    "#${_pedido!.codigo}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _cargando && _pedido == null
          ? const Center(child: PizzaLoading(mensaje: "Cargando tu pedido..."))
          : _pedido == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_fallo ? "No se pudo cargar el pedido" : "Pedido no encontrado"),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _cargar,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reintentar"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [SeguimientoPedido(pedido: _pedido!)],
                  ),
                ),
    );
  }
}