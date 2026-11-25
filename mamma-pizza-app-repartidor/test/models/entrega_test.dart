import 'package:flutter_test/flutter_test.dart';
import 'package:mamma_pizza_app_repartidor/models/entrega.dart';

void main() {
  test('ItemEntrega lee producto, tamaño y agregados del backend', () {
    final item = ItemEntrega.fromJson({
      'cantidad': 1,
      'precioUnitario': 81.0,
      'productoVariante': {
        'tamano': 'Familiar',
        'producto': {'nombre': 'Pizza'},
      },
      'agregados': [
        {
          'agregado': {'nombre': 'Queso extra'},
        },
      ],
    });

    expect(item.titulo, 'Pizza (Familiar)');
    expect(item.agregados, ['Queso extra']);
    expect(item.subtotal, 81);
  });
}
