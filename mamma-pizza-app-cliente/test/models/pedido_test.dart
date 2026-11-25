import 'package:flutter_test/flutter_test.dart';
import 'package:mamma_pizza_cliente/models/pedido.dart';

void main() {
  group('ItemPedido.fromJson', () {
    test('lee nombre y tamaño desde productoVariante del backend', () {
      final item = ItemPedido.fromJson({
        'cantidad': 2,
        'precioUnitario': 27.0,
        'productoVariante': {
          'tamano': 'Familiar',
          'producto': {'nombre': 'Pizza'},
        },
      });

      expect(item.nombre, 'Pizza (Familiar)');
      expect(item.subtotal, 54);
    });

    test('mantiene compatibilidad con nombres planos', () {
      final item = ItemPedido.fromJson({
        'cantidad': 1,
        'precioUnitario': 8.0,
        'nombreProducto': 'Pan de ajo',
      });

      expect(item.nombre, 'Pan de ajo');
    });
  });
}
