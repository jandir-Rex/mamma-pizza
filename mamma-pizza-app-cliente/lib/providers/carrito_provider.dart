import 'package:flutter/material.dart';
import '../models/item_carrito.dart';

class CarritoProvider extends ChangeNotifier {
  final List<ItemCarrito> items = [];

  void agregar(ItemCarrito nuevo) {
    items.add(nuevo);
    notifyListeners();
  }

  void quitar(int index) {
    items.removeAt(index);
    notifyListeners();
  }

  void cambiarCantidad(int index, int delta) {
    final nueva = items[index].cantidad + delta;
    if (nueva < 1) return;
    items[index].cantidad = nueva;
    notifyListeners();
  }

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get cantidadItems => items.fold(0, (sum, item) => sum + item.cantidad);

  void vaciar() {
    items.clear();
    notifyListeners();
  }
}