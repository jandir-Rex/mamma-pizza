import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/producto.dart';
import '../models/agregado.dart';
import '../services/productos_service.dart';
import '../widgets/presionable.dart';
import '../widgets/tony_widgets.dart';
import '../widgets/ui_comunes.dart';
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
  final _buscadorCtrl = TextEditingController();

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
    _buscadorCtrl.dispose();
    super.dispose();
  }

  void _alCambiarCategoria() {
    final v = widget.categoria?.value;
    if (v != null && mounted && v != _sel) setState(() => _sel = v);
  }

  Future<void> _cargarMenu({bool silencioso = false}) async {
    if (!mounted) return;
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final productos = await ProductosService.obtenerMenu();
      final agregados = await ProductosService.obtenerAgregados();
      if (!mounted) return;
      setState(() {
        _productos = productos;
        _agregados = agregados;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_productos.isEmpty) {
        setState(() => _error = "No se pudo cargar el menú");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo actualizar el menú")),
        );
      }
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

  void _alternarBusqueda() {
    setState(() {
      _buscando = !_buscando;
      if (!_buscando) {
        _consulta = "";
        _buscadorCtrl.clear();
      }
    });
  }

  Widget _cabecera() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: "Volver al inicio",
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.dark),
            onPressed: widget.onVolver,
          ),
          Expanded(child: Text("Menú", style: AppFonts.titulo(size: 30))),
          Presionable(
            onTap: _alternarBusqueda,
            etiquetaSemantica: _buscando ? "Cerrar búsqueda" : "Buscar",
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: AppMotion.rapida,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _buscando ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.suave,
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.rapida,
                    child: Icon(
                      _buscando ? Icons.close_rounded : Icons.search_rounded,
                      key: ValueKey(_buscando),
                      color: _buscando ? Colors.white : AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buscador() {
    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.curva,
      alignment: Alignment.topCenter,
      child: _buscando
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                controller: _buscadorCtrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _consulta = v.trim()),
                decoration: InputDecoration(
                  hintText: "Buscar pizzas, bebidas, etc...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _consulta.isEmpty
                      ? null
                      : IconButton(
                          tooltip: "Borrar búsqueda",
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _buscadorCtrl.clear();
                            setState(() => _consulta = "");
                          },
                        ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }

  Widget _chips(List<String> categorias, String seleccion) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categorias[i];
          final activo = cat == seleccion;
          return Presionable(
            onTap: () {
              setState(() => _sel = cat);
              widget.categoria?.value = cat;
            },
            etiquetaSemantica: "Categoría $cat",
            child: AnimatedContainer(
              duration: AppMotion.rapida,
              curve: AppMotion.curva,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activo ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: activo ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                cat,
                style: AppFonts.cuerpo(
                  size: 13,
                  peso: activo ? FontWeight.w700 : FontWeight.w500,
                  color: activo ? Colors.white : AppColors.dark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjeta(Producto p) {
    final agotado = p.variantes.every((v) => !v.disponible);
    return TarjetaProducto(
      producto: p,
      agotado: agotado,
      onTap: agotado ? null : () => mostrarDetalleProducto(context, p, _agregados),
    );
  }

  Widget _cuerpo(List<Producto> filtrados, String seleccion) {
    if (_cargando) {
      return ListView(
        key: const ValueKey("carga"),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        children: const [
          EsqueletoTarjeta(alto: 104),
          EsqueletoTarjeta(alto: 104),
          EsqueletoTarjeta(alto: 104),
          EsqueletoTarjeta(alto: 104),
        ],
      );
    }

    if (_error != null) {
      return EstadoError(
        key: const ValueKey("error"),
        mensaje: _error!,
        onReintentar: _cargarMenu,
      );
    }

    if (filtrados.isEmpty) {
      if (_consulta.isNotEmpty) {
        return EstadoVacio(
          key: const ValueKey("sin-resultados"),
          emoji: "🔍",
          titulo: "Sin resultados",
          mensaje: "No encontramos “$_consulta”. Prueba con otra palabra.",
          textoAccion: "Borrar búsqueda",
          onAccion: () {
            _buscadorCtrl.clear();
            setState(() => _consulta = "");
          },
        );
      }
      return EstadoVacio(
        key: const ValueKey("vacio"),
        emoji: "🍕",
        titulo: "Aún no hay productos aquí",
        mensaje: "Vuelve más tarde o prueba con otra categoría.",
        textoAccion: seleccion == "Todas" ? null : "Ver todo el menú",
        onAccion: seleccion == "Todas"
            ? null
            : () {
                setState(() => _sel = "Todas");
                widget.categoria?.value = "Todas";
              },
      );
    }

    final grupos = <String, List<Producto>>{};
    for (final p in filtrados) {
      grupos.putIfAbsent(p.categoriaNombre, () => []).add(p);
    }
    final lista = <Widget>[];
    var n = 0;
    grupos.forEach((cat, items) {
      lista.add(Aparecer(indice: n++, child: _Seccion(nombre: cat, cantidad: items.length)));
      for (final p in items) {
        lista.add(Aparecer(indice: n++, child: _tarjeta(p)));
      }
    });

    return RefreshIndicator(
      key: ValueKey("lista-$seleccion-$_consulta"),
      onRefresh: () => _cargarMenu(silencioso: true),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
        children: lista,
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
      final okCat = seleccion == "Todas" || _coincide(p.categoriaNombre, seleccion);
      final okBusqueda =
          _consulta.isEmpty || p.nombre.toLowerCase().contains(_consulta.toLowerCase());
      return okCat && okBusqueda;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _cabecera(),
            _buscador(),
            _chips(categorias, seleccion),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.normal,
                child: _cuerpo(filtrados, seleccion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String nombre;
  final int cantidad;
  const _Seccion({required this.nombre, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.kraftLight, shape: BoxShape.circle),
            child: Icon(iconoCategoria(nombre), color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombre, style: AppFonts.titulo(size: 24)),
              Text(
                "$cantidad ${cantidad == 1 ? 'opción' : 'opciones'}",
                style: AppFonts.cuerpo(size: 12, color: AppColors.gray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}