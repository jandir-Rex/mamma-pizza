import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/pedido.dart';
import '../services/pedidos_service.dart';
import '../services/socket_service.dart';
import '../widgets/pizza_loading.dart';

class SeguimientoScreen extends StatefulWidget {
  final int pedidoId;
  const SeguimientoScreen({super.key, required this.pedidoId});

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  Pedido? _pedido;
  bool _cargando = true;

  static const _pasosDelivery = ["CONFIRMADO", "EN_PREPARACION", "EN_CAMINO", "ENTREGADO"];
  static const _pasosSalon = ["CONFIRMADO", "EN_PREPARACION", "ENTREGADO"];

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
    final pasos = _pedido?.canal == "DELIVERY" ? _pasosDelivery : _pasosSalon;
    final indiceActual = _pedido == null ? -1 : pasos.indexOf(_pedido!.estado);

    return Scaffold(
      appBar: AppBar(title: Text(_pedido != null ? _pedido!.codigo : "Seguimiento")),
      body: _cargando
          ? const Center(child: PizzaLoading(mensaje: "Cargando tu pedido..."))
          : _pedido == null
              ? const Center(child: Text("No se pudo cargar el pedido"))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pedido!.estado == "CANCELADO" ? "Pedido cancelado" : "¡Vamos por buen camino! 🍕",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
                      ),
                      const SizedBox(height: 24),
                      if (_pedido!.estado == "CANCELADO")
                        const Text("Este pedido fue cancelado.", style: TextStyle(color: AppColors.danger))
                      else
                        ...List.generate(pasos.length, (i) {
                          return _PasoTimeline(
                            titulo: EstadoPedidoUI.etiqueta(pasos[i]),
                            completado: i <= indiceActual,
                            esActual: i == indiceActual,
                            esUltimo: i == pasos.length - 1,
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _PasoTimeline extends StatelessWidget {
  final String titulo;
  final bool completado;
  final bool esActual;
  final bool esUltimo;
  const _PasoTimeline({required this.titulo, required this.completado, required this.esActual, required this.esUltimo});

  @override
  Widget build(BuildContext context) {
    final color = completado ? AppColors.success : AppColors.gray.withValues(alpha: 0.35);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: esActual ? 26 : 20,
                height: esActual ? 26 : 20,
                decoration:
                    BoxDecoration(color: completado ? color : Colors.white, shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
                child: completado ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              if (!esUltimo)
                Expanded(child: Container(width: 2, color: color, margin: const EdgeInsets.symmetric(vertical: 2))),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 28, top: 2),
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 15,
                fontWeight: esActual ? FontWeight.w700 : FontWeight.w500,
                color: completado ? AppColors.dark : AppColors.gray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}