class PrecioAgregado {
  final String tamano;
  final double precio;
  PrecioAgregado({required this.tamano, required this.precio});

  factory PrecioAgregado.fromJson(Map<String, dynamic> json) {
    return PrecioAgregado(tamano: json["tamano"], precio: double.parse(json["precio"].toString()));
  }
}

class Agregado {
  final int id;
  final String nombre;
  final bool disponible;
  final List<PrecioAgregado> precios;

  Agregado({required this.id, required this.nombre, required this.disponible, required this.precios});

  factory Agregado.fromJson(Map<String, dynamic> json) {
    return Agregado(
      id: json["id"],
      nombre: json["nombre"],
      disponible: json["disponible"],
      precios: (json["precios"] as List).map((p) => PrecioAgregado.fromJson(p)).toList(),
    );
  }

  double? precioParaTamano(String tamano) {
    final match = precios.where((p) => p.tamano == tamano);
    return match.isEmpty ? null : match.first.precio;
  }
}