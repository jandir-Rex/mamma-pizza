import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../core/app_config.dart';
import '../core/utils.dart';
import '../models/entrega.dart';
import '../services/pedidos_service.dart';
import '../services/repartidor_service.dart';
import '../services/ubicacion_service.dart';

class EntregasProvider extends ChangeNotifier {
  List<Entrega> _entregas = [];
  bool _cargando = true;
  bool _disponible = true;
  String? _error;
  double? _lat;
  double? _lng;
  bool _permisoUbicacion = false;
  bool _activo = false;
  Timer? _timer;
  StreamSubscription<geo.Position>? _posSub;
  DateTime _ultimoEnvioUbicacion = DateTime.fromMillisecondsSinceEpoch(0);

  List<Entrega> get entregas => _entregas;
  bool get cargando => _cargando;
  bool get disponible => _disponible;
  String? get error => _error;
  double? get lat => _lat;
  double? get lng => _lng;
  bool get permisoUbicacion => _permisoUbicacion;

  /// Entregas en curso, la más antigua primero
  List<Entrega> get activas =>
      _entregas.where((e) => e.esActiva).toList()..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));

  List<Entrega> get entregadasHoy {
    final hoy = DateTime.now();
    return _entregas
        .where((e) =>
            e.estado == "ENTREGADO" &&
            e.creadoEn.year == hoy.year &&
            e.creadoEn.month == hoy.month &&
            e.creadoEn.day == hoy.day)
        .toList();
  }

  // ---------- Ciclo de vida ----------

  Future<void> iniciar() async {
    _activo = true;
    _entregas = [];
    _cargando = true;
    _error = null;
    notifyListeners();

    await cargar();
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: AppConfig.refrescoEntregasSeg),
      (_) => cargar(silencioso: true),
    );
    unawaited(_iniciarUbicacion());
  }

  void detener() {
    _activo = false;
    _timer?.cancel();
    _posSub?.cancel();
    _timer = null;
    _posSub = null;
  }

  @override
  void dispose() {
    detener();
    super.dispose();
  }

  // ---------- Datos ----------

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _cargando = true;
      notifyListeners();
    }
    try {
      final lista = await PedidosService.misEntregas();
      if (!_activo) return;
      _entregas = lista;
      _error = null;
    } catch (e) {
      if (!silencioso) _error = mensajeError(e);
    } finally {
      _cargando = false;
      if (_activo) notifyListeners();
    }
  }

  /// Devuelve un mensaje de error si falló (y revierte el switch)
  Future<String?> cambiarDisponibilidad(bool valor) async {
    final previo = _disponible;
    _disponible = valor;
    notifyListeners();
    try {
      await RepartidorService.actualizarDisponibilidad(valor);
      return null;
    } catch (e) {
      _disponible = previo;
      notifyListeners();
      return mensajeError(e);
    }
  }

  // ---------- Acciones sobre una entrega (lanzan Exception si fallan) ----------

  Future<void> iniciarEntrega(Entrega e) async {
    await PedidosService.iniciarEntrega(e.id);
    await cargar(silencioso: true);
  }

  Future<void> entregarConCodigo(Entrega e, String codigo) async {
    await PedidosService.entregarConCodigo(e.id, codigo);
    await cargar(silencioso: true);
  }

  Future<void> soltar(Entrega e) async {
    await PedidosService.soltar(e.id);
    await cargar(silencioso: true);
  }

  // ---------- Ubicación ----------

  Future<void> reintentarUbicacion() => _iniciarUbicacion();

  Future<void> _iniciarUbicacion() async {
    final ok = await UbicacionService.asegurarPermiso();
    _permisoUbicacion = ok;
    notifyListeners();
    if (!ok || !_activo) return;

    final actual = await UbicacionService.actual();
    if (actual != null) _registrarPosicion(actual);

    await _posSub?.cancel();
    _posSub = UbicacionService.flujo().listen(_registrarPosicion, onError: (_) {});
  }

  void _registrarPosicion(geo.Position p) {
    _lat = p.latitude;
    _lng = p.longitude;
    notifyListeners();

    // El backend usa esta posición para sugerir/asignar pedidos: se envía cada 15 s como máximo
    final ahora = DateTime.now();
    if (ahora.difference(_ultimoEnvioUbicacion).inSeconds >= 15) {
      _ultimoEnvioUbicacion = ahora;
      RepartidorService.actualizarUbicacion(p.latitude, p.longitude).catchError((_) {});
    }
  }
}