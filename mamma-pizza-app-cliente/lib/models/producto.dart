class Variante {
  final int id;
  final String tamano;
  final double precio;
  final bool disponible;

  Variante({
    required this.id,
    required this.tamano,
    required this.precio,
    required this.disponible,
  });

  factory Variante.fromJson(Map<String, dynamic> json) {
    return Variante(
      id: _aInt(json["id"]),
      tamano: (json["tamano"] ?? "").toString(),
      precio: double.tryParse(json["precio"]?.toString() ?? "") ?? 0,
      disponible: json["disponible"] ?? true,
    );
  }
}

class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;
  final String categoriaNombre;
  final List<Variante> variantes;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
    required this.categoriaNombre,
    required this.variantes,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    final imagen = json["imagenUrl"]?.toString().trim();

    return Producto(
      id: _aInt(json["id"]),
      nombre: (json["nombre"] ?? "").toString(),
      descripcion: json["descripcion"]?.toString(),
      imagenUrl: (imagen == null || imagen.isEmpty) ? null : imagen,
      categoriaNombre: json["categoria"]?["nombre"]?.toString() ?? "Otros",
      variantes: ((json["variantes"] as List?) ?? [])
          .map((v) => Variante.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Precio mínimo entre variantes disponibles; si todas están agotadas,
  /// cae al mínimo general para nunca mostrar "Infinity".
  double get precioDesde {
    final disponibles = variantes.where((v) => v.disponible).map((v) => v.precio);
    final base = disponibles.isNotEmpty ? disponibles : variantes.map((v) => v.precio);
    if (base.isEmpty) return 0;
    return base.reduce((a, b) => a < b ? a : b);
  }

  /// Agotado = no hay ninguna variante disponible.
  bool get agotado => variantes.isEmpty || variantes.every((v) => !v.disponible);
}

/// Convierte int, double o String a int sin crashear.
int _aInt(dynamic valor) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return int.tryParse(valor?.toString() ?? "") ?? 0;
}