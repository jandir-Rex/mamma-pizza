import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../models/pedido.dart';
import '../services/pedidos_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/presionable.dart';
import '../widgets/seguimiento_pedido_widget.dart';
import '../widgets/ui_comunes.dart';
import 'seguimiento_screen.dart';

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

  Future<void> _cargarPedidos({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      // Verificar autenticación
      final usuario = context.read<AuthProvider>().usuario;
      if (usuario == null) {
        if (!mounted) return;
        setState(() {
          _error = "Inicia sesión para ver tus pedidos.";
          _cargando = false;
        });
        return;
      }

      final pedidos = await PedidosService.misPedidos();

      // Más reciente primero
      pedidos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _pedidos = pedidos;
        _error = null;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_pedidos.isEmpty) {
        setState(() {
          _error = "No pudimos cargar tus pedidos.";
          _cargando = false;
        });
      } else {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo actualizar tus pedidos")),
        );
      }
    }
  }

  Widget _cuerpo() {
    if (_cargando) {
      return ListView(
        key: const ValueKey("carga"),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: const [
          EsqueletoTarjeta(alto: 120),
          EsqueletoTarjeta(alto: 120),
          EsqueletoTarjeta(alto: 120),
        ],
      );
    }

    if (_error != null) {
      return EstadoError(
        key: const ValueKey("error"),
        mensaje: _error!,
        onReintentar: _cargarPedidos,
      );
    }

    if (_pedidos.isEmpty) {
      return const EstadoVacio(
        key: ValueKey("vacio"),
        emoji: "🍕",
        titulo: "Todavía no tienes pedidos",
        mensaje: "Cuando hagas tu primer pedido lo verás aquí, con su seguimiento en vivo.",
      );
    }

    final activos = _pedidos.where((p) => EstadoPedidoUI.esActivo(p.estado)).toList();
    final anteriores = _pedidos.where((p) => !EstadoPedidoUI.esActivo(p.estado)).toList();

    final filas = <Widget>[];
    var n = 0;
    if (activos.isNotEmpty) {
      filas.add(_TituloSeccion(texto: "En curso", cantidad: activos.length));
      for (final p in activos) {
        filas.add(Aparecer(indice: n++, child: _TarjetaPedido(pedido: p)));
      }
    }
    if (anteriores.isNotEmpty) {
      filas.add(_TituloSeccion(texto: "Anteriores", cantidad: anteriores.length));
      for (final p in anteriores) {
        filas.add(Aparecer(indice: n++, child: _TarjetaPedido(pedido: p)));
      }
    }

    return RefreshIndicator(
      key: const ValueKey("lista"),
      onRefresh: () => _cargarPedidos(silencioso: true),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        itemCount: filas.length,
        itemBuilder: (context, i) => filas[i],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text("Mis pedidos", style: AppFonts.titulo(size: 32)),
            ),
            Expanded(
              child: AnimatedSwitcher(duration: AppMotion.normal, child: _cuerpo()),
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String texto;
  final int cantidad;
  const _TituloSeccion({required this.texto, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Row(
        children: [
          Text(texto, style: AppFonts.titulo(size: 22)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.kraftLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$cantidad",
              style: AppFonts.cuerpo(size: 12, peso: FontWeight.w700, color: AppColors.cacaoDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPedido extends StatelessWidget {
  final Pedido pedido;
  const _TarjetaPedido({required this.pedido});

  void _verDetalle(BuildContext context) {
    Navigator.of(context).push(deslizarDesdeDerecha(SeguimientoScreen(pedidoId: pedido.id)));
  }

  String _fecha(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  @override
  Widget build(BuildContext context) {
    final esActivo = EstadoPedidoUI.esActivo(pedido.estado);
    final esDelivery = pedido.canal == "DELIVERY";

    final contenido = esActivo
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: SeguimientoPedidoWidget(
              pedido: pedido,
              onVerDetalles: () => _verDetalle(context),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Pedido #${pedido.codigo}",
                        style: AppFonts.cuerpo(size: 15, peso: FontWeight.w700),
                      ),
                    ),
                    InsigniaEstado(estado: pedido.estado),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      esDelivery ? Icons.delivery_dining : Icons.storefront,
                      size: 18,
                      color: AppColors.gray,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${esDelivery ? "Delivery" : "Recojo"} · ${pedido.cantidadItems} items",
                      style: AppFonts.cuerpo(size: 12, color: AppColors.gray),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fecha(pedido.createdAt),
                        style: AppFonts.cuerpo(size: 12, color: AppColors.gray),
                      ),
                    ),
                    Text(
                      "S/. ${pedido.total.toStringAsFixed(2)}",
                      style: AppFonts.precio(size: 24),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.gray, size: 22),
                  ],
                ),
              ],
            ),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.bMedio,
        border: Border.all(
          color: esActivo
              ? EstadoPedidoUI.color(pedido.estado).withValues(alpha: 0.5)
              : AppColors.border,
          width: esActivo ? 1.4 : 1,
        ),
        boxShadow: AppShadows.suave,
      ),
      child: esActivo
          ? contenido
          : Presionable(
              onTap: () => _verDetalle(context),
              etiquetaSemantica: "Ver pedido ${pedido.codigo}",
              child: contenido,
            ),
    );
  }
}