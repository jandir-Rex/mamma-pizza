import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/producto.dart';
import '../models/agregado.dart';
import '../services/productos_service.dart';
import '../widgets/pizza_loading.dart';
import '../widgets/tony_widgets.dart';
import 'producto_detalle_sheet.dart';

class MenuScreen extends StatefulWidget {
  final ValueNotifier<String>? categoria;
  final VoidCallback? onVolver;
  const MenuScreen({super.key, this.categoria, this.onVolver});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Producto> _productos = [];
  List<Agregado> _agregados = [];
  bool _cargando = true;
  String? _error;
  String _sel = "Todas";
  bool _buscando = false;
  String _consulta = "";

  @override
  void initState() {
    super.initState();
    _sel = widget.categoria?.value ?? "Todas";
    widget.categoria?.addListener(_alCambiarCategoria);
    _cargarMenu();
  }

  @override
  void dispose() {
    widget.categoria?.removeListener(_alCambiarCategoria);
    super.dispose();
  }

  void _alCambiarCategoria() {
    final v = widget.categoria?.value;
    if (v != null && mounted && v != _sel) setState(() => _sel = v);
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
      if (mounted) setState(() => _cargando = false);
    }
  }

  bool _coincide(String a, String b) {
    final x = a.toLowerCase().trim();
    final y = b.toLowerCase().trim();
    if (x.isEmpty || y.isEmpty) return false;
    return x == y || x.startsWith(y) || y.startsWith(x);
  }

  Widget _tarjeta(Producto p) {
    final agotado = p.variantes.every((v) => !v.disponible);
    return TarjetaProducto(
      producto: p,
      agotado: agotado,
      onTap:
          agotado ? null : () => mostrarDetalleProducto(context, p, _agregados),
    );
  }

  Widget _cabecera() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.dark),
            onPressed: widget.onVolver,
          ),
          const Text("Menú",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              _buscando = !_buscando;
              if (!_buscando) _consulta = "";
            }),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(_buscando ? Icons.close : Icons.search,
                  color: AppColors.primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(List<String> categorias, String seleccion) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categorias[i];
          final activo = cat == seleccion;
          return GestureDetector(
            onTap: () {
              setState(() => _sel = cat);
              widget.categoria?.value = cat;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: activo
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                  color: activo ? Colors.white : AppColors.dark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categorias = [
      "Todas",
      ...{for (final p in _productos) p.categoriaNombre}
    ];

    String seleccion = _sel;
    if (_sel != "Todas") {
      for (final c in categorias) {
        if (_coincide(c, _sel)) {
          seleccion = c;
          break;
        }
      }
    }

    final filtrados = _productos.where((p) {
      final okCat =
          seleccion == "Todas" || _coincide(p.categoriaNombre, seleccion);
      final okBusqueda = _consulta.isEmpty ||
          p.nombre.toLowerCase().contains(_consulta.toLowerCase());
      return okCat && okBusqueda;
    }).toList();

    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Expanded(
          child: Center(child: PizzaLoading(mensaje: "Cargando menú...")));
    } else if (_error != null) {
      cuerpo = Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(_error!,
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _cargarMenu, child: const Text("Reintentar")),
            ],
          ),
        ),
      );
    } else {
      final lista = <Widget>[];
      if (filtrados.isEmpty) {
        lista.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
              child: Text("Aún no hay productos aquí",
                  style: TextStyle(color: AppColors.gray))),
        ));
      } else {
        final grupos = <String, List<Producto>>{};
        for (final p in filtrados) {
          grupos.putIfAbsent(p.categoriaNombre, () => []).add(p);
        }
        grupos.forEach((cat, items) {
          lista.add(_Seccion(nombre: cat));
          for (final p in items) {
            lista.add(_tarjeta(p));
          }
        });
      }

      cuerpo = Expanded(
        child: Column(
          children: [
            _chips(categorias, seleccion),
            if (_buscando)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _consulta = v.trim()),
                  decoration: const InputDecoration(
                    hintText: "Buscar pizzas, bebidas, etc...",
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _cargarMenu,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                  children: lista,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(children: [_cabecera(), cuerpo]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String nombre;
  const _Seccion({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      child: Row(
        children: [
          Icon(iconoCategoria(nombre), color: AppColors.primary, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombre,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark)),
              const Text("Las más pedidas",
                  style: TextStyle(fontSize: 12, color: AppColors.gray)),
            ],
          ),
        ],
      ),
    );
  }
}
