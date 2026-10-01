import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/producto.dart';
import '../models/agregado.dart';
import '../services/productos_service.dart';
import '../providers/auth_provider.dart';
import '../providers/carrito_provider.dart';
import '../widgets/pizza_loading.dart';
import '../widgets/tony_widgets.dart';
import 'producto_detalle_sheet.dart';

class HomeScreen extends StatefulWidget {
  final void Function(String categoria) onVerMenu;
  const HomeScreen({super.key, required this.onVerMenu});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Producto> _productos = [];
  List<Agregado> _agregados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final p = await ProductosService.obtenerMenu();
      List<Agregado> a = [];
      try {
        a = await ProductosService.obtenerAgregados();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _productos = p;
          _agregados = a;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return "Buenos días,";
    if (h < 19) return "Buenas tardes,";
    return "Buenas noches,";
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final carrito = context.watch<CarritoProvider>();
    final nombre = usuario?.nombre.split(' ').first ?? '';
    final recomendados = _productos
        .where((p) => p.variantes.any((v) => v.disponible))
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _cargando
            ? const Center(child: PizzaLoading(mensaje: "Cargando..."))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + carrito
                    Row(
                      children: [
                        const TonysLogo(),
                        const Spacer(),
                        BotonCarrito(carrito: carrito),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Saludo
                    Text(_saludo(), style: const TextStyle(fontSize: 14, color: AppColors.gray)),
                    const SizedBox(height: 2),
                    Text(
                      nombre.isEmpty ? "👋" : "$nombre 👋",
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.dark, height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    const Text("¿Qué antojo tienes hoy?", style: TextStyle(fontSize: 14, color: AppColors.gray)),
                    const SizedBox(height: 16),

                    // Buscador
                    GestureDetector(
                      onTap: () => widget.onVerMenu("Todas"),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: AppColors.dark, size: 20),
                            SizedBox(width: 10),
                            Text("Buscar pizzas, bebidas, etc...", style: TextStyle(color: AppColors.gray, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Banner
                    Container(
                      height: 172,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFB71C1C), Color(0xFF7F1214)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -34,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFF7DDB4), Color(0xFFE9B56E)],
                                  ),
                                ),
                                child: const Icon(Icons.local_pizza, size: 96, color: AppColors.primary),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("La verdadera", style: TextStyle(color: Colors.white, fontSize: 15)),
                                const Text(
                                  "pizza, siempre",
                                  style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, height: 1.15),
                                ),
                                const Text("es una buena idea", style: TextStyle(color: Colors.white, fontSize: 15)),
                                const SizedBox(height: 8),
                                Container(width: 64, height: 2, color: AppColors.gold),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => widget.onVerMenu("Todas"),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Ver menú", style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                                        SizedBox(width: 6),
                                        Icon(Icons.arrow_forward, color: AppColors.primary, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Categorías
                    Row(
                      children: [
                        const Text("Categorías", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.dark)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => widget.onVerMenu("Todas"),
                          child: const Row(
                            children: [
                              Text("Ver todas", style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, color: AppColors.primary, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CatItem(icon: Icons.local_pizza, label: "Pizzas", activo: true, onTap: () => widget.onVerMenu("Pizzas")),
                        _CatItem(icon: Icons.restaurant, label: "Entradas", onTap: () => widget.onVerMenu("Entradas")),
                        _CatItem(icon: Icons.local_drink, label: "Bebidas", onTap: () => widget.onVerMenu("Bebidas")),
                        _CatItem(icon: Icons.cake, label: "Postres", onTap: () => widget.onVerMenu("Postres")),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recomendados
                    const Text("Recomendados para ti", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.dark)),
                    const SizedBox(height: 12),
                    if (recomendados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text("Pronto tendremos recomendaciones para ti", style: TextStyle(color: AppColors.gray))),
                      )
                    else
                      ...recomendados.map(
                        (p) => TarjetaProducto(
                          producto: p,
                          onTap: () => mostrarDetalleProducto(context, p, _agregados),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _CatItem({required this.icon, required this.label, required this.onTap, this.activo = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: activo ? AppColors.primary : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: activo ? Colors.white : AppColors.primary, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              color: activo ? AppColors.primary : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
