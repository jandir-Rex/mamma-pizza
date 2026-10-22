import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import '../models/direccion.dart';
import '../services/direcciones_service.dart';
import '../services/geocoding_service.dart';

/// Pantalla para elegir la ubicación exacta de entrega.
/// Al confirmar, guarda la dirección en el backend y devuelve la [Direccion] creada.
class SeleccionarUbicacionScreen extends StatefulWidget {
  const SeleccionarUbicacionScreen({super.key});

  @override
  State<SeleccionarUbicacionScreen> createState() => _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState extends State<SeleccionarUbicacionScreen> {
  static const LatLng _trujillo = LatLng(-8.1116, -79.0287);

  final _mapCtrl = MapController();
  final _busquedaCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  Timer? _debounce;
  LatLng _centro = _trujillo;
  List<LugarEncontrado> _resultados = [];

  bool _mapaListo = false;
  bool _ubicacionElegida = false; // evita guardar el punto por defecto sin querer
  bool _buscando = false;
  bool _ubicando = false;
  bool _resolviendo = false;
  bool _guardando = false;
  int _reqId = 0; // descarta respuestas viejas de reverse geocoding
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _mapCtrl.dispose();
    _busquedaCtrl.dispose();
    _direccionCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  // ---------- Mapa ----------

  void _alMoverMapa(MapCamera camera, bool porGesto) {
    _centro = camera.center;
    if (porGesto) {
      _ubicacionElegida = true;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 700), _resolverDireccion);
    }
  }

  Future<void> _resolverDireccion() async {
    final punto = _centro;
    final id = ++_reqId;
    if (mounted) setState(() => _resolviendo = true);
    final texto = await GeocodingService.direccionDe(punto);
    if (!mounted || id != _reqId) return;
    setState(() {
      _resolviendo = false;
      if (texto != null) _direccionCtrl.text = texto;
    });
  }

  // ---------- GPS ----------

  Future<void> _usarMiUbicacion({bool silencioso = false}) async {
    if (!_mapaListo || _ubicando) return;
    setState(() {
      _ubicando = true;
      if (!silencioso) _error = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activa el GPS de tu teléfono');
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw Exception('Sin permiso de ubicación. Puedes buscar tu calle o mover el mapa.');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;

      final punto = LatLng(pos.latitude, pos.longitude);
      _mapCtrl.move(punto, 17.5);
      _centro = punto;
      _ubicacionElegida = true;
      await _resolverDireccion();
    } catch (e) {
      if (!mounted || silencioso) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _ubicando = false);
    }
  }

  // ---------- Búsqueda ----------

  Future<void> _buscar() async {
    final consulta = _busquedaCtrl.text.trim();
    if (consulta.length < 3) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _buscando = true;
      _error = null;
    });

    try {
      final r = await GeocodingService.buscar(consulta);
      if (!mounted) return;
      setState(() {
        _resultados = r;
        if (r.isEmpty) {
          _error = 'No encontramos esa dirección. Prueba con otra o mueve el mapa.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg.startsWith('Falta') ? msg : 'No se pudo buscar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _elegirResultado(LugarEncontrado lugar) {
    _mapCtrl.move(lugar.punto, 17.5);
    setState(() {
      _centro = lugar.punto;
      _ubicacionElegida = true;
      _resultados = [];
      _busquedaCtrl.text = lugar.titulo;
      _direccionCtrl.text = lugar.titulo;
    });
  }

  // ---------- Guardar ----------

  Future<void> _confirmar() async {
    final texto = _direccionCtrl.text.trim();

    if (!_ubicacionElegida) {
      setState(() => _error = 'Usa tu ubicación, busca tu calle o mueve el mapa hasta tu puerta.');
      return;
    }
    if (texto.isEmpty) {
      setState(() => _error = 'Escribe la dirección de entrega');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final nueva = await DireccionesService.crear(
        zona: texto,
        referencia: _refCtrl.text.trim(),
        lat: _centro.latitude,
        lng: _centro.longitude,
      );
      if (!mounted) return;
      Navigator.of(context).pop(nueva);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación de entrega')),
      body: Column(
        children: [
          if (!MapboxConfig.configurado)
            Container(
              width: double.infinity,
              color: const Color(0xFFFDECEA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'Falta un token público de Mapbox (pk.). Revisa lib/core/secrets.dart o usa --dart-define=MAPBOX_TOKEN=pk...',
                style: TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _trujillo,
                    initialZoom: 15,
                    minZoom: 5,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady: () {
                      _mapaListo = true;
                      _usarMiUbicacion(silencioso: true);
                    },
                    onPositionChanged: (camera, porGesto) => _alMoverMapa(camera, porGesto),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapboxConfig.urlTiles,
                      userAgentPackageName: 'com.example.mamma_pizza_app_cliente',
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© Mapbox'),
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),

                // Pin fijo al centro (la punta queda justo sobre el punto elegido)
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(Icons.location_on, size: 48, color: AppColors.primary),
                    ),
                  ),
                ),

                // Buscador + resultados
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    children: [
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(14),
                        child: TextField(
                          controller: _busquedaCtrl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _buscar(),
                          decoration: InputDecoration(
                            hintText: 'Busca tu calle o avenida',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                            suffixIcon: _buscando
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                                    onPressed: _buscar,
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      if (_resultados.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          constraints: const BoxConstraints(maxHeight: 240),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _resultados.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: AppColors.hairline),
                              itemBuilder: (_, i) {
                                final l = _resultados[i];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.place_outlined,
                                      color: AppColors.primary),
                                  title: Text(l.titulo,
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(l.detalle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11)),
                                  onTap: () => _elegirResultado(l),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Botón "mi ubicación"
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'mi_ubicacion',
                    backgroundColor: Colors.white,
                    onPressed: _ubicando ? null : () => _usarMiUbicacion(),
                    child: _ubicando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Panel inferior
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _direccionCtrl,
                    decoration: InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: _resolviendo
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Referencia (opcional)',
                      hintText: 'Ej. Casa verde, portón negro, 2.º piso',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _guardando ? null : _confirmar,
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : const Text('Confirmar ubicación'),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}