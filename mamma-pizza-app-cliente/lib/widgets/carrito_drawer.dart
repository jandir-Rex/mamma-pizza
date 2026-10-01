import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/carrito_provider.dart';
import '../core/page_transitions.dart';
import '../screens/checkout_screen.dart';
import 'tony_widgets.dart';

class CarritoDrawer {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const _CarritoBottomSheet(),
    );
  }
}

class _CarritoBottomSheet extends StatelessWidget {
  const _CarritoBottomSheet();

  Widget _control(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: const Color(0xFFF7F3ED),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 16, color: AppColors.dark),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      snap: true,
      snapSizes: const [0.72, 0.94],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(20))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 14, 12),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text("Mi carrito",
                            style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dark))),
                    if (carrito.items.isNotEmpty)
                      IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.primary, size: 21),
                          onPressed: () =>
                              context.read<CarritoProvider>().vaciar()),
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close,
                            color: AppColors.dark, size: 22),
                        onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.hairline),
              Expanded(
                child: carrito.items.isEmpty
                    ? const Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 50, color: AppColors.lightGray),
                        SizedBox(height: 12),
                        Text("Tu carrito está vacío",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark)),
                        SizedBox(height: 4),
                        Text("Agrega una pizza para comenzar",
                            style:
                                TextStyle(fontSize: 12, color: AppColors.gray))
                      ]))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        children: [
                            for (var i = 0; i < carrito.items.length; i++)
                              _producto(context, carrito, i),
                            const SizedBox(height: 8),
                            const Text("Resumen",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.dark)),
                            const SizedBox(height: 10),
                            Row(children: [
                              const Text("Subtotal",
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.gray)),
                              const Spacer(),
                              Text("S/. ${carrito.total.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dark))
                            ]),
                            const SizedBox(height: 6),
                            const Row(children: [
                              Text("Delivery",
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.gray)),
                              Spacer(),
                              Text("Al pagar",
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.gray))
                            ]),
                          ]),
              ),
              if (carrito.items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(children: [
                          const Text("Total",
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dark)),
                          const Spacer(),
                          Text("S/. ${carrito.total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary))
                        ]),
                        const SizedBox(height: 11),
                        SizedBox(
                          width: double.infinity,
                          height: 47,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Future.delayed(const Duration(milliseconds: 180),
                                  () {
                                if (!context.mounted) return;
                                Navigator.of(context).push(deslizarDesdeDerecha(
                                    const CheckoutScreen()));
                              });
                            },
                            child: const Text("Continuar al pago",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _producto(BuildContext context, CarritoProvider carrito, int index) {
    final item = carrito.items[index];
    final extras = item.agregados.map((a) => a.nombre).join(", ");
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PizzaPlaceholder(
              width: 64,
              height: 64,
              radius: 12,
              iconSize: 30,
              icono: iconoCategoria(item.producto.categoriaNombre)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark)),
                const SizedBox(height: 3),
                Text(
                    extras.isEmpty
                        ? item.variante.tamano
                        : "${item.variante.tamano} · $extras",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11.5, color: AppColors.gray)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text("S/. ${item.subtotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const Spacer(),
                    _control(
                        Icons.remove,
                        () => context
                            .read<CarritoProvider>()
                            .cambiarCantidad(index, -1)),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: Text("${item.cantidad}",
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                    _control(
                        Icons.add,
                        () => context
                            .read<CarritoProvider>()
                            .cambiarCantidad(index, 1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
