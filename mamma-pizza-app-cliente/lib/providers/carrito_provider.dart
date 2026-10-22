import 'package:flutter/material.dart';
import '../models/item_carrito.dart';

class CarritoProvider extends ChangeNotifier {
  /// Tope de unidades por línea del carrito.
  static const int maxPorItem = 20;

  final List<ItemCarrito> items = [];

  void agregar(ItemCarrito nuevo) {
    if (nuevo.cantidad > maxPorItem) nuevo.cantidad = maxPorItem;
    items.add(nuevo);
    notifyListeners();
  }

  /// Quita un ítem por índice (protegido contra índices inválidos).
  void quitar(int index) {
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    notifyListeners();
  }

  /// Suma o resta cantidad. Si baja de 1, el ítem se elimina.
  /// Si supera [maxPorItem], se queda en el tope.
  void cambiarCantidad(int index, int delta) {
    if (index < 0 || index >= items.length) return;
    final nueva = items[index].cantidad + delta;
    if (nueva < 1) {
      items.removeAt(index);
    } else if (nueva <= maxPorItem) {
      items[index].cantidad = nueva;
    } else {
      return; // ya está en el tope, no notifica
    }
    notifyListeners();
  }

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get cantidadItems => items.fold(0, (sum, item) => sum + item.cantidad);

  void vaciar() {
    if (items.isEmpty) return;
    items.clear();
    notifyListeners();
  }
}