import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../models/direccion.dart';
import '../services/direcciones_service.dart';
import '../services/pedidos_service.dart';
import '../providers/carrito_provider.dart';
import 'pedido_exito_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Direccion> _direcciones = [];
  Direccion? _direccionSeleccionada;
  String _metodoPago = "YAPE";
  bool _cargandoDirecciones = true;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    if (!mounted) return;
    setState(() => _cargandoDirecciones = true);
    try {
      final direcciones = await DireccionesService.listar();
      if (!mounted) return;
      setState(() {
        _direcciones = direcciones;
        if (direcciones.isNotEmpty) _direccionSeleccionada = direcciones.first;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargandoDirecciones = false);
    }
  }

  Future<void> _agregarDireccion() async {
    final zonaCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Nueva dirección", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: zonaCtrl, decoration: const InputDecoration(labelText: "Zona / Dirección")),
            const SizedBox(height: 12),
            TextField(controller: refCtrl, decoration: const InputDecoration(labelText: "Referencia (opcional)")),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Guardar dirección")),
          ],
        ),
      ),
    );

    if (resultado == true && zonaCtrl.text.trim().isNotEmpty) {
      try {
        // Coordenadas de referencia (centro de Trujillo). Seleccionar la
        // ubicación exacta en un mapa (OSM/Leaflet) queda como siguiente
        // mejora de esta pantalla.
        final nueva = await DireccionesService.crear(
          zona: zonaCtrl.text.trim(),
          referencia: refCtrl.text.trim(),
          lat: -8.1116,
          lng: -79.0287,
        );
        if (!mounted) return;
        setState(() {
          _direcciones = [nueva, ..._direcciones];
          _direccionSeleccionada = nueva;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))));
      }
    }
  }

  Future<void> _confirmarPedido() async {
    final carrito = context.read<CarritoProvider>();

    if (_direccionSeleccionada == null) {
      setState(() => _error = "Agrega o elige una dirección de entrega");
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final items = carrito.items
          .map((item) => {
                "productoVarianteId": item.variante.id,
                "cantidad": item.cantidad,
                if (item.notas.isNotEmpty) "notas": item.notas,
                if (item.agregados.isNotEmpty) "agregados": item.agregados.map((a) => {"agregadoId": a.id}).toList(),
              })
          .toList();

      final pedido = await PedidosService.crear(
        canal: "DELIVERY",
        direccionId: _direccionSeleccionada!.id,
        metodoPago: _metodoPago,
        items: items,
      );

      carrito.vaciar();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        desvanecer(PedidoExitoScreen(pedidoId: pedido.id, codigo: pedido.codigo)),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Confirmar pedido")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text("Dirección de entrega", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  if (_cargandoDirecciones)
                    const Center(
                        child:
                            Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary)))
                  else ...[
                    ..._direcciones.map((d) {
                      final activa = d.id == _direccionSeleccionada?.id;
                      return GestureDetector(
                        onTap: () => setState(() => _direccionSeleccionada = d),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: activa ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: activa ? AppColors.primary : const Color(0xFFE8E2DA), width: activa ? 1.6 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: activa ? AppColors.primary : AppColors.gray, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.zona, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    if (d.referencia != null && d.referencia!.isNotEmpty)
                                      Text(d.referencia!, style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: _agregarDireccion,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Agregar dirección"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  const Text("Método de pago", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  _OpcionPago(
                    icono: Icons.qr_code_2,
                    titulo: "Yape",
                    activo: _metodoPago == "YAPE",
                    onTap: () => setState(() => _metodoPago = "YAPE"),
                  ),
                  _OpcionPago(
                    icono: Icons.payments_outlined,
                    titulo: "Efectivo",
                    activo: _metodoPago == "EFECTIVO",
                    onTap: () => setState(() => _metodoPago = "EFECTIVO"),
                  ),
                  _OpcionPago(
                    icono: Icons.credit_card,
                    titulo: "Tarjeta",
                    subtitulo: "Próximamente",
                    activo: false,
                    habilitado: false,
                    onTap: () {},
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(12)),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total a pagar", style: TextStyle(fontWeight: FontWeight.w600)),
                        Text("S/. ${carrito.total.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _enviando ? null : _confirmarPedido,
                      child: _enviando
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                          : const Text("Confirmar pedido"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionPago extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final bool activo;
  final bool habilitado;
  final VoidCallback onTap;
  const _OpcionPago({
    required this.icono,
    required this.titulo,
    this.subtitulo,
    required this.activo,
    this.habilitado = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: habilitado ? 1 : 0.45,
      child: GestureDetector(
        onTap: habilitado ? onTap : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: activo ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: activo ? AppColors.primary : const Color(0xFFE8E2DA), width: activo ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Icon(icono, color: activo ? AppColors.primary : AppColors.gray),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (subtitulo != null) Text(subtitulo!, style: const TextStyle(color: AppColors.gray, fontSize: 11)),
                  ],
                ),
              ),
              if (habilitado)
                Icon(activo ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: activo ? AppColors.primary : AppColors.gray, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}