import 'producto.dart';
import 'agregado.dart';

class ItemCarrito {
  final Producto producto;
  final Variante variante;
  final List<Agregado> agregados;
  int cantidad;
  String notas;

  ItemCarrito({
    required this.producto,
    required this.variante,
    required this.agregados,
    this.cantidad = 1,
    this.notas = "",
  });

  double get precioUnitario {
    double precio = variante.precio;
    for (final ag in agregados) {
      precio += ag.precioParaTamano(variante.tamano) ?? 0;
    }
    return precio;
  }

  double get subtotal => precioUnitario * cantidad;
}