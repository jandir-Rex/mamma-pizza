class Variante {
  final int id;
  final String tamano;
  final double precio;
  final bool disponible;

  Variante({required this.id, required this.tamano, required this.precio, required this.disponible});

  factory Variante.fromJson(Map<String, dynamic> json) {
    return Variante(
      id: json["id"],
      tamano: json["tamano"],
      precio: double.parse(json["precio"].toString()),
      disponible: json["disponible"],
    );
  }
}

class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final String categoriaNombre;
  final List<Variante> variantes;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.categoriaNombre,
    required this.variantes,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json["id"],
      nombre: json["nombre"],
      descripcion: json["descripcion"],
      categoriaNombre: json["categoria"]?["nombre"] ?? "Otros",
      variantes: (json["variantes"] as List).map((v) => Variante.fromJson(v)).toList(),
    );
  }

  double get precioDesde =>
      variantes.where((v) => v.disponible).map((v) => v.precio).fold(double.infinity, (a, b) => a < b ? a : b);
}