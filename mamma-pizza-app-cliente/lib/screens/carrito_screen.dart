import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../providers/carrito_provider.dart';
import 'checkout_screen.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Tu pedido")),
      body: carrito.items.isEmpty
          ? const Center(
              child: Text("Aún no has agregado nada",
                  style: TextStyle(color: AppColors.gray)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: carrito.items.length,
                    itemBuilder: (context, index) {
                      final item = carrito.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                              "${item.producto.nombre} (${item.variante.tamano})"),
                          subtitle: Text(
                            [
                              if (item.agregados.isNotEmpty)
                                "+ ${item.agregados.map((a) => a.nombre).join(', ')}",
                              if (item.notas.isNotEmpty) '"${item.notas}"',
                            ].join("\n"),
                          ),
                          trailing: SizedBox(
                            width: 110,
                            height: 70,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("S/. ${item.subtotal.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () => context
                                          .read<CarritoProvider>()
                                          .cambiarCantidad(index, -1),
                                    ),
                                    Text("${item.cantidad}"),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => context
                                          .read<CarritoProvider>()
                                          .cambiarCantidad(index, 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, -2))
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            Text("S/. ${carrito.total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                                deslizarDesdeDerecha(const CheckoutScreen()));
                          },
                          child: const Text("Continuar"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
