import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../models/producto.dart';
import '../models/agregado.dart';
import '../services/productos_service.dart';
import '../providers/auth_provider.dart';
import '../providers/carrito_provider.dart';
import 'producto_detalle_sheet.dart';
import 'carrito_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Producto> _productos = [];
  List<Agregado> _agregados = [];
  bool _cargando = true;
  String? _error;
  String _categoriaSeleccionada = "Todas";

  @override
  void initState() {
    super.initState();
    _cargarMenu();
  }

  Future<void> _cargarMenu() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final productos = await ProductosService.obtenerMenu();
      final agregados = await ProductosService.obtenerAgregados();
      if (!mounted) return;
      setState(() {
        _productos = productos;
        _agregados = agregados;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "No se pudo cargar el menú");
    } finally {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final carrito = context.watch<CarritoProvider>();

    final categorias = ["Todas", ...{for (final p in _productos) p.categoriaNombre}];
    final productosFiltrados = _categoriaSeleccionada == "Todas"
        ? _productos
        : _productos.where((p) => p.categoriaNombre == _categoriaSeleccionada).toList();

    return Scaffold(
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.danger)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _cargarMenu, child: const Text("Reintentar")),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarMenu,
                    color: AppColors.primary,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("¡Hola, ${usuario?.nombre.split(' ').first ?? ''}! 👋",
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark)),
                                      const Text("¿Qué se te antoja hoy?",
                                          style: TextStyle(color: AppColors.gray, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                _BotonCarrito(carrito: carrito),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 46,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              children: categorias.map((cat) {
                                final activo = cat == _categoriaSeleccionada;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(cat),
                                    selected: activo,
                                    onSelected: (_) => setState(() => _categoriaSeleccionada = cat),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final producto = productosFiltrados[index];
                                final agotado = producto.variantes.every((v) => !v.disponible);
                                return _TarjetaProducto(
                                  producto: producto,
                                  agotado: agotado,
                                  onTap: agotado ? null : () => mostrarDetalleProducto(context, producto, _agregados),
                                );
                              },
                              childCount: productosFiltrados.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _BotonCarrito extends StatelessWidget {
  final CarritoProvider carrito;
  const _BotonCarrito({required this.carrito});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(deslizarDesdeDerecha(const CarritoScreen())),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ]),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
          ),
          if (carrito.cantidadItems > 0)
            Positioned(
              right: -4,
              top: -4,
              child: AnimatedScale(
                scale: 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text("${carrito.cantidadItems}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  final Producto producto;
  final bool agotado;
  final VoidCallback? onTap;
  const _TarjetaProducto({required this.producto, required this.agotado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: agotado ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text("🍕", style: TextStyle(fontSize: 30))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(producto.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.dark)),
                        const SizedBox(height: 3),
                        Text(
                          agotado ? "Agotado por hoy" : (producto.descripcion ?? ""),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: agotado ? AppColors.danger : AppColors.gray,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!agotado)
                          Text("Desde S/. ${producto.precioDesde.toStringAsFixed(2)}",
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (!agotado)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}