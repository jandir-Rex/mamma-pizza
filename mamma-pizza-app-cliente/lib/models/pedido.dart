class ItemPedido {
  final int cantidad;
  final double precioUnitario;
  ItemPedido({required this.cantidad, required this.precioUnitario});

  factory ItemPedido.fromJson(Map<String, dynamic> json) => ItemPedido(
        cantidad: json["cantidad"],
        precioUnitario: double.parse(json["precioUnitario"].toString()),
      );
}

class Pedido {
  final int id;
  final String codigo;
  final String canal;
  final String estado;
  final double total;
  final DateTime createdAt;
  final List<ItemPedido> items;

  Pedido({
    required this.id,
    required this.codigo,
    required this.canal,
    required this.estado,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
        id: json["id"],
        codigo: json["codigo"],
        canal: json["canal"],
        estado: json["estado"],
        total: double.parse(json["total"].toString()),
        createdAt: DateTime.parse(json["createdAt"]),
        items: (json["items"] as List).map((i) => ItemPedido.fromJson(i)).toList(),
      );

  int get cantidadItems => items.fold(0, (s, i) => s + i.cantidad);
}