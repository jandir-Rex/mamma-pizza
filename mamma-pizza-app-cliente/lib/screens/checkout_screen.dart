import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../models/direccion.dart';
import '../services/direcciones_service.dart';
import '../services/pedidos_service.dart';
import '../providers/carrito_provider.dart';
import '../widgets/ui_comunes.dart';
import '../widgets/yape_pago_widgets.dart';
import 'pedido_exito_screen.dart';
import 'seleccionar_ubicacion_screen.dart';

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
  bool _errorDirecciones = false;
  bool _enviando = false;
  String? _error;

  XFile? _captura;
  final _yapeNombre = TextEditingController();
  final _pagaCon = TextEditingController();
  bool _montoExacto = true;

  @override
  void initState() {
    super.initState();
    _yapeNombre.addListener(_refrescar);
    _pagaCon.addListener(_refrescar);
    _cargarDirecciones();
  }

  @override
  void dispose() {
    _yapeNombre.dispose();
    _pagaCon.dispose();
    super.dispose();
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarDirecciones() async {
    if (!mounted) return;
    setState(() {
      _cargandoDirecciones = true;
      _errorDirecciones = false;
    });
    try {
      final direcciones = await DireccionesService.listar();
      if (!mounted) return;
      setState(() {
        _direcciones = direcciones;
        if (direcciones.isNotEmpty) _direccionSeleccionada = direcciones.first;
      });
    } catch (_) {
      if (mounted) setState(() => _errorDirecciones = true);
    } finally {
      if (mounted) setState(() => _cargandoDirecciones = false);
    }
  }

  /// Abre el mapa para elegir la ubicación exacta; devuelve la dirección ya guardada.
  Future<void> _agregarDireccion() async {
    final nueva = await Navigator.of(context).push<Direccion>(
      MaterialPageRoute<Direccion>(builder: (_) => const SeleccionarUbicacionScreen()),
    );
    if (nueva == null || !mounted) return;
    setState(() {
      _direcciones = [nueva, ..._direcciones];
      _direccionSeleccionada = nueva;
      _errorDirecciones = false;
      _error = null;
    });
  }

  /// Motivo visible por el que el botón está deshabilitado (null = listo).
  String? _motivoBloqueo(double total) {
    if (_cargandoDirecciones) return "Cargando tus direcciones…";
    if (_direccionSeleccionada == null) return "Elige o agrega una dirección de entrega";
    if (_metodoPago == "YAPE") {
      if (_captura == null) return "Adjunta la captura de tu Yape";
      if (_yapeNombre.text.trim().length < 2) return "Indica el nombre de quien yapeó";
    }
    if (_metodoPago == "EFECTIVO" && !_montoExacto) {
      final v = double.tryParse(_pagaCon.text.replaceAll(",", "."));
      if (v == null || v < total) {
        return "Indica con cuánto pagarás (mínimo S/. ${total.toStringAsFixed(2)})";
      }
    }
    return null;
  }

  Future<void> _confirmarPedido() async {
    final carrito = context.read<CarritoProvider>();

    if (_direccionSeleccionada == null) {
      setState(() => _error = "Agrega o elige una dirección de entrega");
      return;
    }

    double? pagaCon;
    if (_metodoPago == "YAPE") {
      if (_captura == null) {
        setState(() => _error = "Adjunta la captura de tu Yape");
        return;
      }
      if (_yapeNombre.text.trim().length < 2) {
        setState(() => _error = "Indica el nombre de quien yapeó");
        return;
      }
    }
    if (_metodoPago == "EFECTIVO" && !_montoExacto) {
      pagaCon = double.tryParse(_pagaCon.text.replaceAll(",", "."));
      if (pagaCon == null || pagaCon < carrito.total) {
        setState(() => _error = "Indica con cuánto pagarás (mínimo S/. ${carrito.total.toStringAsFixed(2)})");
        return;
      }
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
        pagaCon: pagaCon,
        items: items,
      );

      if (_metodoPago == "YAPE") {
        try {
          await PedidosService.subirComprobante(pedido.id, imagen: _captura!, yapeNombre: _yapeNombre.text.trim());
        } catch (_) {
          // El pedido ya existe: en el seguimiento podrá reintentar la subida
        }
      }

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

  void _elegirMetodo(String metodo) {
    setState(() {
      _metodoPago = metodo;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final motivo = _motivoBloqueo(carrito.total);

    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        appBar: AppBar(title: const Text("Confirmar pedido")),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Aparecer(indice: 0, child: _resumen(carrito)),
                  const SizedBox(height: 24),
                  Aparecer(
                    indice: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _titulo("Dirección de entrega"),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: AppMotion.normal,
                          child: _direccionesContenido(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Aparecer(
                    indice: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _titulo("Método de pago"),
                        const SizedBox(height: 10),
                        _opcionPago(
                          icono: Icons.qr_code_2_rounded,
                          titulo: "Yape",
                          subtitulo: "Paga con QR y adjunta tu captura",
                          metodo: "YAPE",
                        ),
                        _opcionPago(
                          icono: Icons.payments_outlined,
                          titulo: "Efectivo",
                          subtitulo: "Pagas al recibir tu pedido",
                          metodo: "EFECTIVO",
                        ),
                        _opcionPago(
                          icono: Icons.credit_card_rounded,
                          titulo: "Tarjeta",
                          subtitulo: "Próximamente",
                          metodo: "TARJETA",
                          habilitado: false,
                        ),
                        AnimatedSize(
                          duration: AppMotion.normal,
                          curve: AppMotion.curva,
                          alignment: Alignment.topCenter,
                          child: _formularioPago(carrito.total),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            BarraInferior(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CajaError(mensaje: _error),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total a pagar", style: AppFonts.cuerpo(size: 15, peso: FontWeight.w600)),
                      PrecioAnimado(valor: carrito.total, estilo: AppFonts.precio(size: 30)),
                    ],
                  ),
                  AnimatedSize(
                    duration: AppMotion.normal,
                    curve: AppMotion.curva,
                    alignment: Alignment.topCenter,
                    child: (motivo != null && !_enviando)
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: AppColors.mostazaDark),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    motivo,
                                    style: AppFonts.cuerpo(size: 12, color: AppColors.mostazaDark, peso: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 12),
                  BotonPrincipal(
                    texto: "Confirmar pedido",
                    icono: Icons.check_circle_outline_rounded,
                    cargando: _enviando,
                    onPressed: (motivo == null && !_enviando) ? _confirmarPedido : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String texto) => Text(texto, style: AppFonts.titulo(size: 24));

  Widget _resumen(CarritoProvider carrito) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.bMedio,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.suave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _titulo("Tu pedido")),
              TextButton(
                onPressed: _enviando ? null : () => Navigator.of(context).maybePop(),
                child: const Text("Editar"),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final item in carrito.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${item.cantidad}×",
                    style: AppFonts.cuerpo(size: 13, peso: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${item.producto.nombre} · ${capitalizar(item.variante.tamano)}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.cuerpo(size: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "S/. ${item.subtotal.toStringAsFixed(2)}",
                    style: AppFonts.cuerpo(size: 13, color: AppColors.gray),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _direccionesContenido() {
    if (_cargandoDirecciones) {
      return const Column(
        key: ValueKey("dir-carga"),
        children: [
          EsqueletoTarjeta(alto: 72),
          EsqueletoTarjeta(alto: 72),
        ],
      );
    }

    return Column(
      key: const ValueKey("dir-lista"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorDirecciones)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "No pudimos cargar tus direcciones",
                    style: AppFonts.cuerpo(size: 13, color: AppColors.danger),
                  ),
                ),
                TextButton(onPressed: _cargarDirecciones, child: const Text("Reintentar")),
              ],
            ),
          )
        else if (_direcciones.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kraftLight,
              borderRadius: AppRadius.bChico,
            ),
            child: Row(
              children: [
                const Text("📍", style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Aún no tienes direcciones. Agrega dónde recibirás tu pedido.",
                    style: AppFonts.cuerpo(size: 13, color: AppColors.cacaoDark, altura: 1.35),
                  ),
                ),
              ],
            ),
          ),
        for (final d in _direcciones) _tarjetaDireccion(d),
        OutlinedButton.icon(
          onPressed: _agregarDireccion,
          icon: const Icon(Icons.add_location_alt_outlined, size: 18),
          label: const Text("Agregar dirección en el mapa"),
        ),
      ],
    );
  }

  Widget _tarjetaDireccion(Direccion d) {
    final activa = d.id == _direccionSeleccionada?.id;
    return TarjetaSeleccion(
      activo: activa,
      onTap: () => setState(() {
        _direccionSeleccionada = d;
        _error = null;
      }),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppMotion.rapida,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activa ? AppColors.primary : AppColors.kraftLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              size: 20,
              color: activa ? Colors.white : AppColors.cacao,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.zona, style: AppFonts.cuerpo(size: 14, peso: FontWeight.w600)),
                if (d.referencia != null && d.referencia!.isNotEmpty)
                  Text(
                    d.referencia!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.cuerpo(size: 12, color: AppColors.gray),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IndicadorSeleccion(activo: activa),
        ],
      ),
    );
  }

  Widget _opcionPago({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required String metodo,
    bool habilitado = true,
  }) {
    final activo = habilitado && _metodoPago == metodo;
    return TarjetaSeleccion(
      activo: activo,
      habilitado: habilitado,
      onTap: () => _elegirMetodo(metodo),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppMotion.rapida,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activo ? AppColors.primary : AppColors.kraftLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 20, color: activo ? Colors.white : AppColors.cacao),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppFonts.cuerpo(size: 14, peso: FontWeight.w600)),
                Text(subtitulo, style: AppFonts.cuerpo(size: 12, color: AppColors.gray)),
              ],
            ),
          ),
          if (habilitado) ...[
            const SizedBox(width: 8),
            IndicadorSeleccion(activo: activo),
          ],
        ],
      ),
    );
  }

  Widget _formularioPago(double total) {
    if (_metodoPago == "YAPE") {
      return Padding(
        key: const ValueKey("form-yape"),
        padding: const EdgeInsets.only(top: 6),
        child: YapeFormulario(
          total: total,
          captura: _captura,
          nombreCtrl: _yapeNombre,
          onCaptura: (f) => setState(() => _captura = f),
        ),
      );
    }
    if (_metodoPago == "EFECTIVO") {
      return Padding(
        key: const ValueKey("form-efectivo"),
        padding: const EdgeInsets.only(top: 6),
        child: PagaConSelector(
          total: total,
          exacto: _montoExacto,
          ctrl: _pagaCon,
          onExacto: (v) => setState(() => _montoExacto = v),
        ),
      );
    }
    return const SizedBox(width: double.infinity);
  }
}