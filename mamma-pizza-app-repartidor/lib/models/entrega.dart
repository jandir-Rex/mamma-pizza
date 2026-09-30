class ItemEntrega {
  final int cantidad;
  final double precioUnitario;
  final String? notas;
  ItemEntrega({required this.cantidad, required this.precioUnitario, this.notas});

  factory ItemEntrega.fromJson(Map<String, dynamic> json) => ItemEntrega(
        cantidad: json["cantidad"],
        precioUnitario: double.parse(json["precioUnitario"].toString()),
        notas: json["notas"],
      );
}

class DireccionEntrega {
  final String zona;
  final String? referencia;
  final double lat;
  final double lng;
  DireccionEntrega({required this.zona, this.referencia, required this.lat, required this.lng});

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
  final String? clienteNombre;
  final String? clienteTelefono;
  final DireccionEntrega? direccion;
  final List<ItemEntrega> items;

  Entrega({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.total,
    required this.metodoPago,
    this.clienteNombre,
    this.clienteTelefono,
    this.direccion,
    required this.items,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) => Entrega(
        id: json["id"],
        codigo: json["codigo"],
        estado: json["estado"],
        total: double.parse(json["total"].toString()),
        metodoPago: json["pago"]?["metodo"] ?? "EFECTIVO",
        clienteNombre: json["cliente"]?["nombre"],
        clienteTelefono: json["cliente"]?["telefono"],
        direccion: json["direccion"] != null ? DireccionEntrega.fromJson(json["direccion"]) : null,
        items: (json["items"] as List).map((i) => ItemEntrega.fromJson(i)).toList(),
      );

  bool get esActiva => estado != "ENTREGADO" && estado != "CANCELADO";
}