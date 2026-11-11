import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as io_client;
import '../core/theme.dart';
import '../models/pedido.dart';
import '../services/pedidos_service.dart';
import '../services/socket_service.dart';
import '../widgets/pizza_loading.dart';
import '../widgets/presionable.dart';
import '../widgets/seguimiento_widgets.dart';
import '../widgets/ui_comunes.dart';
import '../widgets/yape_pago_widgets.dart';

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

  void _copiarCodigo(String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text("Código copiado")));
  }

  Widget _insigniaCodigo(String codigo) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Presionable(
          onTap: () => _copiarCodigo(codigo),
          etiquetaSemantica: "Copiar código $codigo",
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.kraftLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.kraft),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "#$codigo",
                    style: AppFonts.cuerpo(size: 12, peso: FontWeight.w600, color: AppColors.cacaoDark),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.cacaoDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuerpo() {
    final pedido = _pedido;

    if (_cargando && pedido == null) {
      return const Center(
        key: ValueKey("carga"),
        child: PizzaLoading(mensaje: "Cargando tu pedido..."),
      );
    }

    if (pedido == null) {
      if (_fallo) {
        return EstadoError(
          key: const ValueKey("error"),
          mensaje: "No pudimos cargar tu pedido.",
          onReintentar: () => _cargar(),
        );
      }
      return EstadoVacio(
        key: const ValueKey("no-encontrado"),
        emoji: "🔎",
        titulo: "Pedido no encontrado",
        mensaje: "No encontramos este pedido. Puede que ya no esté disponible.",
        textoAccion: "Reintentar",
        onAccion: () => _cargar(),
      );
    }

    return RefreshIndicator(
      key: const ValueKey("pedido"),
      onRefresh: _cargar,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (pedido.demorado)
            Aparecer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AvisoDemora(enRevision: pedido.comprobanteEstado == "EN_REVISION"),
              ),
            ),
          if (pedido.yapePendiente)
            Aparecer(
              indice: 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ComprobanteYapeCard(
                  pedido: pedido,
                  onEnviado: () => _cargar(silencioso: true),
                ),
              ),
            ),
          Aparecer(indice: 2, child: SeguimientoPedido(pedido: pedido)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Desliza hacia abajo para actualizar",
              style: AppFonts.cuerpo(size: 12, color: AppColors.gray),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedido = _pedido;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Mi pedido"),
        actions: [
          if (pedido != null) _insigniaCodigo(pedido.codigo),
        ],
      ),
      body: AnimatedSwitcher(duration: AppMotion.normal, child: _cuerpo()),
    );
  }
}