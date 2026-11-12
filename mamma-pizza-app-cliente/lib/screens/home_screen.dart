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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Aparecer(
                  indice: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: Text("Categorías", style: AppFonts.titulo(size: 22))),
                          TextButton(
                            onPressed: () => widget.onVerMenu("Todas"),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              "Ver todas",
                              style: AppFonts.cuerpo(size: 12.5, peso: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text("Recomendados para ti", style: AppFonts.titulo(size: 22)),
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
            const SizedBox(height: AppSpace.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Mamma Pizza",
                  style: AppFonts.marca(size: 22, color: AppColors.kraft),
                ),
                const SizedBox(width: AppSpace.s),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    "El sabor de la felicidad",
                    style: AppFonts.cuerpo(
                      size: 11,
                      color: AppColors.kraftLight.withValues(alpha: 0.85),
                    ).copyWith(letterSpacing: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.l),
            Text(
              saludo.toUpperCase(),
              style: AppFonts.cuerpo(
                size: 11,
                peso: FontWeight.w600,
                color: AppColors.kraftLight.withValues(alpha: 0.9),
              ).copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 2),
            Text(
              nombre.isEmpty ? "¡Hola! 👋" : "$nombre 👋",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.marca(size: 28, color: Colors.white),
            ),
            const SizedBox(height: AppSpace.m),
            Presionable(
              onTap: onBuscar,
              etiquetaSemantica: "Buscar en el menú",
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.kraft.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.cacao, size: 20),
                    const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: Text(
                        "Buscar pizzas, bebidas, etc...",
                        style: AppFonts.cuerpo(size: 13.5, color: AppColors.gray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
      constraints: const BoxConstraints(minHeight: 128),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.kraft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.kraftDark.withValues(alpha: 0.5)),
        boxShadow: AppShadows.suave,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.cacao,
                ),
                child: const ExcludeSemantics(
                  child: Icon(Icons.local_pizza, size: 60, color: AppColors.kraft),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 108, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.tomate,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "HECHA AL MOMENTO",
                    style: AppFonts.cuerpo(size: 10, peso: FontWeight.w700, color: Colors.white)
                        .copyWith(letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "La verdadera pizza",
                  style: AppFonts.marca(size: 20, color: AppColors.cacaoDark),
                ),
                Text(
                  "es una buena idea",
                  style: AppFonts.marca(size: 20, color: AppColors.cacaoDark),
                ),
                const SizedBox(height: 10),
                Presionable(
                  onTap: onVerMenu,
                  haptico: Haptico.ligero,
                  etiquetaSemantica: "Ver menú",
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cacaoDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Ver menú",
                          style: AppFonts.cuerpo(size: 12.5, peso: FontWeight.w600, color: AppColors.kraft),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.kraft, size: 14),
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
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.kraftLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.kraft.withValues(alpha: 0.8)),
              ),
              child: Icon(icon, color: AppColors.cacao, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppFonts.cuerpo(size: 11.5, peso: FontWeight.w600, color: AppColors.dark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}