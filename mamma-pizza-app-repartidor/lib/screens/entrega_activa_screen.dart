import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/entrega.dart';
import '../services/pedidos_service.dart';

class EntregaActivaScreen extends StatefulWidget {
  final Entrega entrega;
  const EntregaActivaScreen({super.key, required this.entrega});

  @override
  State<EntregaActivaScreen> createState() => _EntregaActivaScreenState();
}

class _EntregaActivaScreenState extends State<EntregaActivaScreen> {
  late String _estado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estado = widget.entrega.estado;
  }

  String? get _siguiente {
    switch (_estado) {
      case "CONFIRMADO":
      case "EN_PREPARACION":
        return "EN_CAMINO";
      case "EN_CAMINO":
        return "ENTREGADO";
      default:
        return null;
    }
  }

  String get _textoBoton => _siguiente == "EN_CAMINO" ? "Salí con el pedido" : "Marcar como entregado";

  Future<void> _avanzar() async {
    final nuevo = _siguiente;
    if (nuevo == null) return;
    setState(() => _guardando = true);
    try {
      final int idPedido = widget.entrega.id is int 
          ? widget.entrega.id 
          : int.parse(widget.entrega.id.toString());

      if (nuevo == "EN_CAMINO") {
        await PedidosService.iniciarEntrega(idPedido);
      } else if (nuevo == "ENTREGADO") {
        // En caso de entregarse mediante código directo
        await PedidosService.entregarConCodigo(idPedido, widget.entrega.codigo);
      }

      if (!mounted) return;
      setState(() => _estado = nuevo);
      if (nuevo == "ENTREGADO") Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entrega;
    final color = EstadoPedidoUI.color(_estado);
    final efectivo = e.metodoPago == "EFECTIVO";

    return Scaffold(
      appBar: AppBar(title: Text(e.codigo)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(EstadoPedidoUI.etiqueta(_estado), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 14),
                const Text("Destino", style: TextStyle(color: AppColors.gray, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(e.direccion?.zona ?? "Sin dirección", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                Text(efectivo ? "Cobrar en efectivo" : "Pago: ${e.metodoPago}", style: const TextStyle(color: AppColors.gray, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text("S/. ${e.total.toStringAsFixed(2)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: efectivo ? AppColors.warning : AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_siguiente != null)
            ElevatedButton(
              onPressed: _guardando ? null : _avanzar,
              child: _guardando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_textoBoton),
            ),
        ],
      ),
    );
  }
}