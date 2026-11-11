import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../models/item_carrito.dart';
import '../providers/carrito_provider.dart';
import '../widgets/tony_widgets.dart'; // PizzaPlaceholder + iconoCategoria
import '../widgets/ui_comunes.dart';
import 'checkout_screen.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final items = carrito.items;
    final unidades = items.fold<int>(0, (suma, i) => suma + i.cantidad);

    return Scaffold(
      appBar: AppBar(title: const Text("Tu pedido")),
      body: AnimatedSwitcher(
        duration: AppMotion.normal,
        child: items.isEmpty
            ? EstadoVacio(
                key: const ValueKey("vacio"),
                emoji: "🛒",
                titulo: "Tu carrito está vacío",
                mensaje: "Agrega tu pizza favorita y aparecerá aquí.",
                textoAccion: "Explorar el menú",
                onAccion: () => Navigator.of(context).maybePop(),
              )
            : Column(
                key: const ValueKey("lleno"),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "$unidades ${unidades == 1 ? 'producto' : 'productos'}",
                        style: AppFonts.cuerpo(size: 13, color: AppColors.gray),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Aparecer(
                          indice: index,
                          child: _TarjetaItem(
                            item: item,
                            onMenos: () => context.read<CarritoProvider>().cambiarCantidad(index, -1),
                            onMas: () => context.read<CarritoProvider>().cambiarCantidad(index, 1),
                          ),
                        );
                      },
                    ),
                  ),
                  BarraInferior(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total",
                              style: AppFonts.cuerpo(size: 15, peso: FontWeight.w600),
                            ),
                            PrecioAnimado(
                              valor: carrito.total,
                              estilo: AppFonts.precio(size: 30),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Siguiente: dirección y método de pago",
                            style: AppFonts.cuerpo(size: 12, color: AppColors.gray),
                          ),
                        ),
                        const SizedBox(height: 12),
                        BotonPrincipal(
                          texto: "Continuar",
                          icono: Icons.arrow_forward_rounded,
                          onPressed: () {
                            Navigator.of(context).push(deslizarDesdeDerecha(const CheckoutScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TarjetaItem extends StatelessWidget {
  final ItemCarrito item;
  final VoidCallback onMenos;
  final VoidCallback onMas;
  const _TarjetaItem({required this.item, required this.onMenos, required this.onMas});

  @override
  Widget build(BuildContext context) {
    final extras = <String>[
      if (item.agregados.isNotEmpty) "+ ${item.agregados.map((a) => a.nombre).join(', ')}",
      if (item.notas.isNotEmpty) "“${item.notas}”",
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.bMedio,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.suave,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PizzaPlaceholder(
            width: 72,
            height: 72,
            radius: 16,
            iconSize: 32,
            icono: iconoCategoria(item.producto.categoriaNombre),
            imagenUrl: item.producto.imagenUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.cuerpo(size: 15, peso: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.kraftLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    capitalizar(item.variante.tamano),
                    style: AppFonts.cuerpo(size: 12, peso: FontWeight.w600, color: AppColors.cacaoDark),
                  ),
                ),
                if (extras.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    extras.join("\n"),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.cuerpo(size: 12, color: AppColors.gray, altura: 1.3),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: PrecioAnimado(
                          valor: item.subtotal,
                          estilo: AppFonts.precio(size: 22),
                        ),
                      ),
                    ),
                    SelectorCantidad(
                      cantidad: item.cantidad,
                      menosEsEliminar: item.cantidad <= 1,
                      onMenos: onMenos,
                      onMas: onMas,
                    ),
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