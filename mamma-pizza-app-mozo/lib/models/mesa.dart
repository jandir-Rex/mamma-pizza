class PedidoActivo {
  final int id;
  final String codigo;
  final String estado;
  PedidoActivo({required this.id, required this.codigo, required this.estado});

  factory PedidoActivo.fromJson(Map<String, dynamic> json) =>
      PedidoActivo(id: json["id"], codigo: json["codigo"], estado: json["estado"]);
}

class Mesa {
  final int id;
  final int numero;
  final int? capacidad;
  final bool ocupada;
  final PedidoActivo? pedidoActivo;

  Mesa({required this.id, required this.numero, this.capacidad, required this.ocupada, this.pedidoActivo});

  factory Mesa.fromJson(Map<String, dynamic> json) => Mesa(
        id: json["id"],
        numero: json["numero"],
        capacidad: json["capacidad"],
        ocupada: json["ocupada"],
        pedidoActivo: json["pedidoActivo"] != null ? PedidoActivo.fromJson(json["pedidoActivo"]) : null,
      );
}