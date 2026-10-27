import '../core/app_config.dart';

class ItemEntrega {
  final int cantidad;
  final double precioUnitario; // ya incluye los agregados
  final String? notas;
  final String? nombre; // requiere el include del backend (ver nota en la guía)
  final String? tamano;
  final List<String> agregados;

  const ItemEntrega({
    required this.cantidad,
    required this.precioUnitario,
    this.notas,
    this.nombre,
    this.tamano,
    this.agregados = const [],
  });

  factory ItemEntrega.fromJson(Map<String, dynamic> json) {
    final variante = json["productoVariante"];
    final agregados = (json["agregados"] as List?) ?? const [];
    return ItemEntrega(
      cantidad: json["cantidad"] as int,
      precioUnitario: double.parse(json["precioUnitario"].toString()),
      notas: json["notas"] as String?,
      nombre: variante?["producto"]?["nombre"] as String?,
      tamano: variante?["tamano"] as String?,
      agregados: agregados
          .map((a) => (a as Map)["agregado"]?["nombre"])
          .whereType<String>()
          .toList(),
    );
  }

  String get titulo {
    if (nombre == null) return "Producto";
    return tamano == null ? nombre! : "$nombre ($tamano)";
  }

  double get subtotal => cantidad * precioUnitario;
}

class DireccionEntrega {
  final String zona;
  final String? referencia;
  final double lat;
  final double lng;
  const DireccionEntrega({required this.zona, this.referencia, required this.lat, required this.lng});

  factory DireccionEntrega.fromJson(Map<String, dynamic> json) => DireccionEntrega(
        zona: json["zona"],
        referencia: json["referencia"],
        lat: double.parse(json["lat"].toString()),
        lng: double.parse(json["lng"].toString()),
      );
}

class Entrega {
  final int id;
  final String codigo;
  final String estado;
  final double total;
  final String metodoPago;
  final String pagoEstado;
  final DateTime creadoEn;
  final String? clienteNombre;
  final String? clienteTelefono;
  final DireccionEntrega? direccion;
  final List<ItemEntrega> items;
  final int intentosCodigoFallidos;
  final DateTime? confirmadoEn;

  const Entrega({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.total,
    required this.metodoPago,
    required this.pagoEstado,
    required this.creadoEn,
    this.clienteNombre,
    this.clienteTelefono,
    this.direccion,
    required this.items,
    this.intentosCodigoFallidos = 0,
    this.confirmadoEn,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) => Entrega(
        id: json["id"] as int,
        codigo: json["codigo"] as String,
        estado: json["estado"] as String,
        total: double.parse(json["total"].toString()),
        metodoPago: json["pago"]?["metodo"] ?? "EFECTIVO",
        pagoEstado: json["pago"]?["estado"] ?? "pendiente",
        creadoEn: DateTime.tryParse(json["createdAt"]?.toString() ?? "")?.toLocal() ?? DateTime.now(),
        clienteNombre: json["cliente"]?["nombre"],
        clienteTelefono: json["cliente"]?["telefono"],
        direccion: json["direccion"] != null ? DireccionEntrega.fromJson(json["direccion"]) : null,
        items: ((json["items"] as List?) ?? const []).map((i) => ItemEntrega.fromJson(i)).toList(),
        intentosCodigoFallidos: (json["intentosCodigoFallidos"] as int?) ?? 0,
        confirmadoEn: DateTime.tryParse(json["confirmadoEn"]?.toString() ?? "")?.toLocal(),
      );

  bool get esActiva => estado != "ENTREGADO" && estado != "CANCELADO";
  bool get estaConfirmado => estado == "CONFIRMADO";
  bool get estaEnPreparacion => estado == "EN_PREPARACION";
  bool get estaEnCamino => estado == "EN_CAMINO";
  bool get esEfectivo => metodoPago == "EFECTIVO";
  bool get bloqueada => intentosCodigoFallidos >= AppConfig.maxIntentosCodigo;
  int get totalProductos => items.fold(0, (suma, i) => suma + i.cantidad);
}