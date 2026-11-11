import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/producto.dart';
import '../models/agregado.dart';
import '../services/productos_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/presionable.dart';
import '../widgets/tony_widgets.dart';
import '../widgets/ui_comunes.dart';
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
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso && mounted) {
      setState(() {
        _cargando = true;
        _error = false;
      });
    }
    try {
      final p = await ProductosService.obtenerMenu();
      List<Agregado> a = [];
      try {
        a = await ProductosService.obtenerAgregados();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _productos = p;
        _agregados = a;
        _cargando = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = _productos.isEmpty;
      });
    }
  }

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return "Buenos días,";
    if (h < 19) return "Buenas tardes,";
    return "Buenas noches,";
  }

  Widget _recomendados(List<Producto> recomendados) {
    if (_cargando) {
      return const Column(
        key: ValueKey("rec-carga"),
        children: [
          EsqueletoTarjeta(alto: 104),
          EsqueletoTarjeta(alto: 104),
          EsqueletoTarjeta(alto: 104),
        ],
      );
    }
    if (_error) {
      return EstadoError(
        key: const ValueKey("rec-error"),
        mensaje: "No pudimos cargar el menú.",
        onReintentar: _cargar,
      );
    }
    if (recomendados.isEmpty) {
      return const EstadoVacio(
        key: ValueKey("rec-vacio"),
        emoji: "🍕",
        titulo: "Pronto habrá recomendados",
        mensaje: "Estamos preparando algo rico para ti.",
      );
    }
    return Column(
      key: const ValueKey("rec-lista"),
      children: [
        for (var i = 0; i < recomendados.length; i++)
          Aparecer(
            indice: i,
            child: TarjetaProducto(
              producto: recomendados[i],
              onTap: () => mostrarDetalleProducto(context, recomendados[i], _agregados),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final nombre = usuario?.nombre.split(' ').first ?? '';
    final recomendados = _productos
        .where((p) => p.variantes.any((v) => v.disponible))
        .take(3)
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _cargar(silencioso: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              _Cabecera(
                saludo: _saludo(),
                nombre: nombre,
                onBuscar: () => widget.onVerMenu("Todas"),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Aparecer(indice: 1, child: _Banner(onVerMenu: () => widget.onVerMenu("Todas"))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Aparecer(
                  indice: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text("Categorías", style: AppFonts.titulo(size: 24))),
                          TextButton(
                            onPressed: () => widget.onVerMenu("Todas"),
                            child: const Text("Ver todas"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _CatItem(
                              icon: Icons.local_pizza,
                              label: "Pizzas",
                              onTap: () => widget.onVerMenu("Pizzas"),
                            ),
                          ),
                          Expanded(
                            child: _CatItem(
                              icon: Icons.restaurant,
                              label: "Entradas",
                              onTap: () => widget.onVerMenu("Entradas"),
                            ),
                          ),
                          Expanded(
                            child: _CatItem(
                              icon: Icons.local_drink,
                              label: "Bebidas",
                              onTap: () => widget.onVerMenu("Bebidas"),
                            ),
                          ),
                          Expanded(
                            child: _CatItem(
                              icon: Icons.cake,
                              label: "Postres",
                              onTap: () => widget.onVerMenu("Postres"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text("Recomendados para ti", style: AppFonts.titulo(size: 24)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: AppMotion.normal,
                  child: _recomendados(recomendados),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  final String saludo;
  final String nombre;
  final VoidCallback onBuscar;
  const _Cabecera({required this.saludo, required this.nombre, required this.onBuscar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppGradients.cacao,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.grande)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text("Mamma Pizza", style: AppFonts.marca(size: 22, color: AppColors.kraft)),
            Text(
              "El sabor de la felicidad",
              style: AppFonts.cuerpo(size: 12, color: AppColors.kraftLight),
            ),
            const SizedBox(height: 22),
            Text(saludo, style: AppFonts.cuerpo(size: 14, color: AppColors.kraftLight)),
            const SizedBox(height: 2),
            Text(
              nombre.isEmpty ? "¡Hola! 👋" : "$nombre 👋",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.marca(size: 32, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              "¿Qué antojo tienes hoy?",
              style: AppFonts.cuerpo(size: 14, color: AppColors.kraftLight),
            ),
            const SizedBox(height: 18),
            Presionable(
              onTap: onBuscar,
              etiquetaSemantica: "Buscar en el menú",
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.suave,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.cacao, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Buscar pizzas, bebidas, etc...",
                        style: AppFonts.cuerpo(size: 14, color: AppColors.gray),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final VoidCallback onVerMenu;
  const _Banner({required this.onVerMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 168),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.kraft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kraftDark.withValues(alpha: 0.5)),
        boxShadow: AppShadows.suave,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.cacao,
                ),
                child: const ExcludeSemantics(
                  child: Icon(Icons.local_pizza, size: 80, color: AppColors.kraft),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 130, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tomate,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Hecha al momento",
                    style: AppFonts.cuerpo(size: 12, peso: FontWeight.w600, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "El sabor de la felicidad",
                  style: AppFonts.marca(size: 22, color: AppColors.cacaoDark),
                ),
                const SizedBox(height: 12),
                Presionable(
                  onTap: onVerMenu,
                  haptico: Haptico.ligero,
                  etiquetaSemantica: "Ver menú",
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.tomate,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.brillo(AppColors.tomate),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Ver menú",
                          style: AppFonts.cuerpo(size: 14, peso: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CatItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Presionable(
      onTap: onTap,
      etiquetaSemantica: "Categoría $label",
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.kraftLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.kraft),
              ),
              child: Icon(icon, color: AppColors.cacao, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppFonts.cuerpo(size: 12, peso: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}