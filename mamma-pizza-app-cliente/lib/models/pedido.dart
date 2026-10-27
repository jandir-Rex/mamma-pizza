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
  /// El backend lo genera solo al pasar a EN_CAMINO.
  final String? codigoConfirmacion;
  final DateTime? confirmadoEn;
  final int intentosCodigoFallidos;

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
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
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
      );

  int get cantidadItems => items.fold(0, (s, i) => s + i.cantidad);

  bool get esDelivery => canal == "DELIVERY";
  bool get activo => estado != "ENTREGADO" && estado != "CANCELADO";
}