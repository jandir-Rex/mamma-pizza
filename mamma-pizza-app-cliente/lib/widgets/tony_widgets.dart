import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../models/producto.dart';
import '../providers/carrito_provider.dart';
import '../screens/carrito_screen.dart';

/// Ícono según el nombre de la categoría.
IconData iconoCategoria(String nombre) {
  final n = nombre.toLowerCase();
  if (n.contains('pizza')) return Icons.local_pizza;
  if (n.contains('entrada')) return Icons.restaurant;
  if (n.contains('bebida')) return Icons.local_drink;
  if (n.contains('postre')) return Icons.cake;
  return Icons.restaurant_menu;
}

/// Logo "MammaPizza PIZZA HOUSE"
class TonysLogo extends StatelessWidget {
  const TonysLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_pizza_outlined, size: 46, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "MammaPizza",
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "PIZZA HOUSE",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Imagen provisional: fondo cálido + ícono de pizza (luego se cambia por la foto).
class PizzaPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final double iconSize;
  final IconData icono;
  final bool circular;

  const PizzaPlaceholder({
    super.key,
    this.width,
    this.height,
    this.radius = 14,
    this.iconSize = 40,
    this.icono = Icons.local_pizza,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7DDB4), Color(0xFFE9B56E)],
        ),
      ),
      child: Center(
        child: Icon(icono, size: iconSize, color: AppColors.primary),
      ),
    );
  }
}

/// Botón del carrito con globito rojo de cantidad.
class BotonCarrito extends StatelessWidget {
  final CarritoProvider carrito;
  const BotonCarrito({super.key, required this.carrito});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(deslizarDesdeDerecha(const CarritoScreen())),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 23),
          ),
          if (carrito.cantidadItems > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  "${carrito.cantidadItems}",
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta de producto (misma en Inicio y Menú).
class TarjetaProducto extends StatelessWidget {
  final Producto producto;
  final bool agotado;
  final VoidCallback? onTap;

  const TarjetaProducto({
    super.key,
    required this.producto,
    this.agotado = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final descripcion = (producto.descripcion ?? "").trim();
    return Opacity(
      opacity: agotado ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              PizzaPlaceholder(
                width: 84,
                height: 84,
                radius: 14,
                iconSize: 42,
                icono: iconoCategoria(producto.categoriaNombre),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descripcion.isEmpty ? "Deliciosa opción de la casa" : descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.25),
                    ),
                    const SizedBox(height: 8),
                    if (agotado)
                      const Text("Agotado", style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600))
                    else
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.gold, size: 15),
                          const SizedBox(width: 3),
                          const Text("4.8", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark)),
                          const SizedBox(width: 14),
                          Text(
                            "S/. ${producto.precioDesde.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                          ),
                          const Spacer(),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
