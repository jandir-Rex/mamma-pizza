import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:provider/provider.dart';
import '../core/app_config.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/entrega.dart';
import '../providers/auth_provider.dart';
import '../providers/entregas_provider.dart';
import '../services/ruta_service.dart';
import '../widgets/codigo_entrega_sheet.dart';
import '../widgets/ruta_widgets.dart';
import '../widgets/slide_action.dart';

class RutaScreen extends StatefulWidget {
  const RutaScreen({super.key});

  @override
  State<RutaScreen> createState() => _RutaScreenState();
}

class _RutaScreenState extends State<RutaScreen> {
  static const double _hojaInicial = 0.42;
  static const double _hojaMin = 0.16;
  static const double _hojaMax = 0.92;

  // El mapa se crea UNA sola vez (no se reconstruye con cada cambio del provider)
  late final Widget _mapaWidget = mb.MapWidget(
    key: const ValueKey("mapa-ruta"),
    styleUri: "mapbox://styles/mapbox/streets-v12",
    cameraOptions: mb.CameraOptions(
      center: mb.Point(coordinates: mb.Position(-79.0215, -8.1091)), // Trujillo
      zoom: 13.5,
    ),
    onMapCreated: _alCrearMapa,
  );

  mb.MapboxMap? _mapaCtrl;
  mb.PolylineAnnotationManager? _lineas;
  mb.CircleAnnotationManager? _circulos;

  int? _seleccionId;
  int? _entregaIdRuta;
  RutaInfo? _ruta;
  mb.Position? _destino;
  double? _origenLat;
  double? _origenLng;
  bool _calculando = false;

  // ---------------------------------------------------------------- Mapa

  Future<void> _alCrearMapa(mb.MapboxMap mapa) async {
    _mapaCtrl = mapa;
    try {
      _lineas = await mapa.annotations.createPolylineAnnotationManager();
      _circulos = await mapa.annotations.createCircleAnnotationManager();
      await mapa.location.updateSettings(
        mb.LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          pulsingColor: AppColors.primary.toARGB32(),
        ),
      );
      await mapa.scaleBar.updateSettings(mb.ScaleBarSettings(enabled: false));
      await mapa.compass.updateSettings(mb.CompassSettings(enabled: false));
    } catch (_) {
      // Si el permiso de ubicación no está dado, el mapa igual funciona sin el punto azul
    }
    await _pintar();
  }

  Future<void> _pintar() async {
    final lineas = _lineas;
    final circulos = _circulos;
    if (lineas == null || circulos == null || !mounted) return;

    try {
      await lineas.deleteAll();
      await circulos.deleteAll();

      final destino = _destino;
      if (destino == null) return;

      final ruta = _ruta;
      if (ruta != null && ruta.puntos.length > 1) {
        // Borde blanco + línea de marca encima: se lee bien sobre cualquier calle
        await lineas.create(mb.PolylineAnnotationOptions(
          geometry: mb.LineString(coordinates: ruta.puntos),
          lineColor: Colors.white.toARGB32(),
          lineWidth: 10,
        ));
        await lineas.create(mb.PolylineAnnotationOptions(
          geometry: mb.LineString(coordinates: ruta.puntos),
          lineColor: AppColors.primary.toARGB32(),
          lineWidth: 6,
        ));
      }

      await circulos.create(mb.CircleAnnotationOptions(
        geometry: mb.Point(coordinates: destino),
        circleRadius: 24,
        circleColor: AppColors.primary.toARGB32(),
        circleOpacity: 0.18,
      ));
      await circulos.create(mb.CircleAnnotationOptions(
        geometry: mb.Point(coordinates: destino),
        circleRadius: 9,
        circleColor: AppColors.primary.toARGB32(),
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3.5,
      ));
    } catch (_) {}

    await _encuadrar();
  }

  /// Centra el mapa para que se vea la ruta completa en la zona NO tapada por la hoja
  Future<void> _encuadrar() async {
    final mapa = _mapaCtrl;
    final destino = _destino;
    if (mapa == null || destino == null || !mounted) return;

    final prov = context.read<EntregasProvider>();
    final puntos = <mb.Position>[destino, ...?_ruta?.puntos];
    if (prov.lat != null && prov.lng != null) puntos.add(mb.Position(prov.lng!, prov.lat!));

    var minLat = puntos.first.lat.toDouble(), maxLat = minLat;
    var minLng = puntos.first.lng.toDouble(), maxLng = minLng;
    for (final p in puntos) {
      minLat = math.min(minLat, p.lat.toDouble());
      maxLat = math.max(maxLat, p.lat.toDouble());
      minLng = math.min(minLng, p.lng.toDouble());
      maxLng = math.max(maxLng, p.lng.toDouble());
    }

    final pantalla = MediaQuery.of(context).size;
    final altoMapa = (context.size?.height ?? pantalla.height * 0.7) - 90;
    const padArriba = 210.0;
    final padAbajo = altoMapa * _hojaInicial;
    final visibleAncho = pantalla.width - 48;
    final visibleAlto = math.max(altoMapa - padArriba - padAbajo, 120.0);

    double zoomPara(double spanGrados, double px) =>
        spanGrados <= 0 ? 17 : math.log(px * 360 / (256 * spanGrados)) / math.ln2;

    final zoom = math
        .min(
          math.min(zoomPara(maxLng - minLng, visibleAncho), zoomPara(maxLat - minLat, visibleAlto)),
          16.5,
        )
        .clamp(10.0, 16.5)
        .toDouble();

    try {
      await mapa.flyTo(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position((minLng + maxLng) / 2, (minLat + maxLat) / 2)),
          zoom: zoom,
          padding: mb.MbxEdgeInsets(top: padArriba, left: 24, bottom: padAbajo, right: 24),
        ),
        mb.MapAnimationOptions(duration: 900),
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------- Ruta

  void _programarRuta(Entrega? sel, EntregasProvider prov) {
    if (sel == null) {
      if (_entregaIdRuta != null) {
        _entregaIdRuta = null;
        _ruta = null;
        _destino = null;
        _origenLat = null;
        _origenLng = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => _pintar());
      }
      return;
    }

    final dir = sel.direccion;
    if (dir == null || _calculando) return;

    final lat = prov.lat;
    final lng = prov.lng;
    final cambioEntrega = _entregaIdRuta != sel.id;
    final llegoUbicacion = lat != null && lng != null && _origenLat == null;
    final seMovio = lat != null &&
        lng != null &&
        _origenLat != null &&
        distanciaMetros(_origenLat!, _origenLng!, lat, lng) > 250;

    if (!cambioEntrega && !llegoUbicacion && !seMovio) return;

    _calculando = true;
    _entregaIdRuta = sel.id;
    _destino = mb.Position(dir.lng, dir.lat);
    WidgetsBinding.instance.addPostFrameCallback((_) => _calcularRuta(lat, lng));
  }

  Future<void> _calcularRuta(double? lat, double? lng) async {
    final destino = _destino;
    RutaInfo? ruta;
    if (lat != null && lng != null && destino != null) {
      ruta = await RutaService.obtener(mb.Position(lng, lat), destino);
    }
    if (!mounted) {
      _calculando = false;
      return;
    }
    setState(() {
      _ruta = ruta;
      _origenLat = lat;
      _origenLng = lng;
      _calculando = false;
    });
    await _pintar();
  }

  // ---------------------------------------------------------------- Acciones

  Entrega? _seleccionada(List<Entrega> activas) {
    if (activas.isEmpty) return null;
    for (final e in activas) {
      if (e.id == _seleccionId) return e;
    }
    return activas.first;
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _iniciar(Entrega e) async {
    try {
      await context.read<EntregasProvider>().iniciarEntrega(e);
      if (mounted) _aviso("¡Buen viaje! El cliente ya tiene su código de entrega");
    } catch (err) {
      if (mounted) _aviso(mensajeError(err));
    }
  }

  Future<void> _confirmar(Entrega e) async {
    final ok = await mostrarCodigoEntrega(context, e);
    if (ok == true && mounted) _aviso("Entrega registrada · ${e.codigo}");
  }

  Future<void> _soltar(Entrega e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Soltar ${e.codigo}?"),
        content: const Text("El pedido volverá al pool y se le buscará otro repartidor."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Soltar", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<EntregasProvider>().soltar(e);
      if (mounted) _aviso("Pedido liberado");
    } catch (err) {
      if (mounted) _aviso(mensajeError(err));
    }
  }

  void _mostrarSos() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 16),
              const Text("¿Necesitas ayuda?", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _TileSos(icono: Icons.storefront_rounded, titulo: "Llamar al local", color: AppColors.primary, telefono: AppConfig.telefonoLocal),
              _TileSos(icono: Icons.local_police_rounded, titulo: "Policía · 105", color: AppColors.info, telefono: "105"),
              _TileSos(icono: Icons.local_fire_department_rounded, titulo: "Bomberos · 116", color: AppColors.danger, telefono: "116"),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EntregasProvider>();
    final nombre = context.watch<AuthProvider>().usuario?.nombre ?? "Repartidor";
    final activas = prov.activas;
    final sel = _seleccionada(activas);
    _programarRuta(sel, prov);

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _mapaWidget),

              // Cabecera + ETA flotando sobre el mapa
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Column(
                      children: [
                        _CabeceraRuta(
                          nombre: nombre,
                          estado: sel?.estaEnCamino == true
                              ? PildoraEstado(texto: "En entrega", color: AppColors.primary)
                              : prov.disponible
                                  ? PildoraEstado(texto: "Disponible", color: AppColors.success)
                                  : const PildoraEstado(texto: "En pausa", color: AppColors.gray),
                          onSos: _mostrarSos,
                        ),
                        if (sel?.direccion != null) ...[
                          const SizedBox(height: 10),
                          TarjetaEta(
                            ruta: _ruta,
                            calculando: _calculando,
                            tieneUbicacion: prov.lat != null,
                            destino: sel!.direccion!,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: BotonRedondo(icono: Icons.my_location_rounded, onTap: _encuadrar),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (sel != null) _hoja(sel, activas) else _PanelEspera(prov: prov, onAviso: _aviso),
            ],
          ),
        ),
        if (sel != null) _barraAccion(sel),
      ],
    );
  }

  // ---------------------------------------------------------------- Hoja deslizable

  Widget _hoja(Entrega e, List<Entrega> activas) {
    final puedeSoltar = e.estaConfirmado || e.estaEnPreparacion;

    return Positioned.fill(
      child: DraggableScrollableSheet(
        key: const ValueKey("hoja-entrega"),
        initialChildSize: _hojaInicial,
        minChildSize: _hojaMin,
        maxChildSize: _hojaMax,
        snap: true,
        snapSizes: const [_hojaMin, _hojaInicial, _hojaMax],
        builder: (context, scroll) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: AppShadows.hoja,
            ),
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 14),
                if (activas.length > 1) ...[
                  _selectorEntregas(activas, e),
                  const SizedBox(height: 14),
                ],
                _encabezadoComanda(e),
                const SizedBox(height: 16),
                ProgresoEntrega(estado: e.estado),
                const SizedBox(height: 16),
                if (puedeSoltar) ...[
                  _avisoRecojo(e),
                  const SizedBox(height: 12),
                ],
                TarjetaCobro(key: ValueKey("cobro-${e.id}"), entrega: e),
                const SizedBox(height: 12),
                TarjetaCliente(entrega: e),
                const SizedBox(height: 12),
                ListaPedido(entrega: e),
                if (puedeSoltar)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () => _soltar(e),
                      icon: const Icon(Icons.undo_rounded, size: 18, color: AppColors.gray),
                      label: const Text("Soltar este pedido", style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _selectorEntregas(List<Entrega> activas, Entrega sel) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: activas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final e = activas[i];
          final activo = e.id == sel.id;
          final color = EstadoPedidoUI.color(e.estado);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _seleccionId = e.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activo ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activo ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: activo ? Colors.white : color, shape: BoxShape.circle)),
                  const SizedBox(width: 7),
                  Text(
                    e.codigo,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: activo ? Colors.white : AppColors.dark),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _encabezadoComanda(Entrega e) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("COMANDA ACTIVA", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.gray, letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      e.codigo,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: e.codigo));
                      _aviso("Código copiado");
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.copy_rounded, size: 16, color: AppColors.gray),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("Despacho", style: TextStyle(fontSize: 11, color: AppColors.gray)),
            Text("${hora(e.creadoEn)} hrs", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            Text(haceCuanto(e.creadoEn), style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          ],
        ),
      ],
    );
  }

  Widget _avisoRecojo(Entrega e) {
    final enCocina = e.estaConfirmado;
    final color = enCocina ? AppColors.info : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(enCocina ? Icons.soup_kitchen_rounded : Icons.storefront_rounded, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              enCocina
                  ? "La cocina aún no empieza este pedido. Se activará cuando esté en preparación."
                  : "Pasa por el local a recoger el pedido y desliza abajo para iniciar la entrega.",
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Barra de acción (fija)

  Widget _barraAccion(Entrega e) {
    final Widget contenido;
    if (e.estaEnCamino) {
      contenido = ElevatedButton.icon(
        onPressed: () => _confirmar(e),
        icon: const Icon(Icons.verified_rounded),
        label: const Text("Confirmar entrega con código"),
      );
    } else if (e.estaEnPreparacion) {
      contenido = SlideAction(
        texto: "Desliza · Salí con el pedido",
        onCompletado: () => _iniciar(e),
      );
    } else {
      contenido = Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.gray),
            SizedBox(width: 8),
            Text("Esperando a cocina", style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: contenido,
    );
  }
}

// ===========================================================================
// Cabecera flotante
// ===========================================================================
class _CabeceraRuta extends StatelessWidget {
  final String nombre;
  final Widget estado;
  final VoidCallback onSos;
  const _CabeceraRuta({required this.nombre, required this.estado, required this.onSos});

  @override
  Widget build(BuildContext context) {
    final primerNombre = nombre.trim().split(' ').first;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(gradient: AppGradients.brand, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Mamma Pizza Delivery", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                Text("Hola, $primerNombre · Trujillo", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.gray)),
              ],
            ),
          ),
          estado,
          const SizedBox(width: 8),
          Material(
            color: AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSos,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                child: Text("SOS", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900, fontSize: 12.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TileSos extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color color;
  final String telefono;
  const _TileSos({required this.icono, required this.titulo, required this.color, required this.telefono});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
        child: Icon(icono, color: color),
      ),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.call_rounded, color: AppColors.success),
      onTap: () {
        Navigator.of(context).pop();
        abrirLlamada(telefono);
      },
    );
  }
}

// ===========================================================================
// Pantalla de espera (sin entregas activas)
// ===========================================================================
class _PanelEspera extends StatelessWidget {
  final EntregasProvider prov;
  final void Function(String) onAviso;
  const _PanelEspera({required this.prov, required this.onAviso});

  @override
  Widget build(BuildContext context) {
    final hoy = prov.entregadasHoy.length;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppShadows.hoja,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 18),
            const _PulsoMoto(),
            const SizedBox(height: 12),
            Text(
              prov.disponible ? "Esperando asignación…" : "Estás en pausa",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              prov.disponible
                  ? "Cuando haya un pedido para ti, aparecerá aquí al instante."
                  : "Activa tu disponibilidad para recibir pedidos nuevos.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            TarjetaDisponibilidad(prov: prov, onError: onAviso),
            if (hoy > 0) ...[
              const SizedBox(height: 12),
              Text(
                "Hoy llevas $hoy entrega${hoy == 1 ? '' : 's'} 🎉",
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PulsoMoto extends StatefulWidget {
  const _PulsoMoto();

  @override
  State<_PulsoMoto> createState() => _PulsoMotoState();
}

class _PulsoMotoState extends State<_PulsoMoto> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56 + 40 * t,
                height: 56 + 40 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.18 * (1 - t)),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
                child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 30),
              ),
            ],
          );
        },
      ),
    );
  }
}