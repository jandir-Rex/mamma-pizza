class ItemPedido {
  final int cantidad;
  final double precioUnitario;
  final String nombre;
  ItemPedido({required this.cantidad, required this.precioUnitario, this.nombre = "Producto"});

  static String _nombre(Map<String, dynamic> j) {
    final p = j["producto"] ?? (j["variante"] is Map ? j["variante"]["producto"] : null);
    final base = (j["nombre"] ?? j["nombreProducto"] ?? (p is Map ? p["nombre"] : null) ?? "Producto").toString();
    final v = j["variante"];
    final t = (v is Map ? v["tamano"] : null) ?? j["tamano"];
    return t == null ? base : "$base ($t)";
  }

  factory ItemPedido.fromJson(Map<String, dynamic> json) => ItemPedido(
        cantidad: (json["cantidad"] as num).toInt(),
        precioUnitario: double.parse(json["precioUnitario"].toString()),
        nombre: _nombre(json),
      );

  double get subtotal => precioUnitario * cantidad;
}

class Pedido {
  final int id;
  final String codigo;
  final String canal;
  final String estado;
  final double total;
  final DateTime createdAt;
  final List<ItemPedido> items;

  /// Código de 4 dígitos que el cliente le dicta al repartidor.
  final String? codigoConfirmacion;
  final DateTime? confirmadoEn;
  final int intentosCodigoFallidos;

  // --- Pago ---
  final String metodoPago;
  final String comprobanteEstado; // SIN_COMPROBANTE | EN_REVISION | APROBADO | RECHAZADO
  final String? comprobanteMotivo;
  final String? yapeNombre;
  final double? pagaCon;

  /// Se llena cuando el pedido tardó demasiado en recibir respuesta.
  final DateTime? disculpaEnviadaEn;

  Pedido({
    required this.id,
    required this.codigo,
    required this.canal,
    required this.estado,
    required this.total,
    required this.createdAt,
    required this.items,
    this.codigoConfirmacion,
    this.confirmadoEn,
    this.intentosCodigoFallidos = 0,
    this.metodoPago = "EFECTIVO",
    this.comprobanteEstado = "SIN_COMPROBANTE",
    this.comprobanteMotivo,
    this.yapeNombre,
    this.pagaCon,
    this.disculpaEnviadaEn,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final pago = json["pago"] is Map ? Map<String, dynamic>.from(json["pago"] as Map) : <String, dynamic>{};
    return Pedido(
      id: (json["id"] as num).toInt(),
      codigo: json["codigo"].toString(),
      canal: json["canal"].toString(),
      estado: json["estado"].toString(),
      total: double.parse(json["total"].toString()),
      createdAt: DateTime.parse(json["createdAt"].toString()),
      items: (json["items"] as List? ?? const [])
          .map((i) => ItemPedido.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      codigoConfirmacion: json["codigoConfirmacion"]?.toString(),
      confirmadoEn: json["confirmadoEn"] != null
          ? DateTime.tryParse(json["confirmadoEn"].toString())?.toLocal()
          : null,
      intentosCodigoFallidos: (json["intentosCodigoFallidos"] as num?)?.toInt() ?? 0,
      metodoPago: (pago["metodo"] ?? "EFECTIVO").toString(),
      comprobanteEstado: (pago["comprobanteEstado"] ?? "SIN_COMPROBANTE").toString(),
      comprobanteMotivo: pago["comprobanteMotivo"]?.toString(),
      yapeNombre: pago["yapeNombre"]?.toString(),
      pagaCon: pago["pagaCon"] != null ? double.tryParse(pago["pagaCon"].toString()) : null,
      disculpaEnviadaEn: json["disculpaEnviadaEn"] != null
          ? DateTime.tryParse(json["disculpaEnviadaEn"].toString())?.toLocal()
          : null,
    );
  }

  int get cantidadItems => items.fold(0, (s, i) => s + i.cantidad);

  bool get esDelivery => canal == "DELIVERY";
  bool get activo => estado != "ENTREGADO" && estado != "CANCELADO";

  bool get yapePendiente => metodoPago == "YAPE" && estado == "PENDIENTE_PAGO";
  bool get demorado => estado == "PENDIENTE_PAGO" && disculpaEnviadaEn != null;
  double? get vuelto => (pagaCon != null && pagaCon! >= total) ? pagaCon! - total : null;
}