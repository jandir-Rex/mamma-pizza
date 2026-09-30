import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/mesa.dart';
import '../models/producto.dart';
import '../models/agregado.dart';
import '../models/item_pedido_mozo.dart';
import '../services/productos_service.dart';
import '../services/pedidos_service.dart';
import '../widgets/pizza_loading.dart';

class TomarPedidoScreen extends StatefulWidget {
  final Mesa mesa;
  const TomarPedidoScreen({super.key, required this.mesa});

  @override
  State<TomarPedidoScreen> createState() => _TomarPedidoScreenState();
}

class _TomarPedidoScreenState extends State<TomarPedidoScreen> {
  List<Producto> _productos = [];
  List<Agregado> _agregados = [];
  final List<ItemPedidoMozo> _items = [];
  bool _cargando = true;
  bool _enviando = false;
  String _categoria = "Todas";

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final productos = await ProductosService.obtenerMenu();
      final agregados = await ProductosService.obtenerAgregados();
      if (!mounted) return;
      setState(() {
        _productos = productos;
        _agregados = agregados;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double get _total => _items.fold(0, (s, i) => s + i.subtotal);

  Future<void> _agregarProducto(Producto producto) async {
    final variante = producto.variantes.firstWhere(
      (v) => v.disponible,
      orElse: () => producto.variantes.first,
    );
    final agregadosCompatibles = _agregados
        .where(
          (a) => a.disponible && a.precioParaTamano(variante.tamano) != null,
        )
        .toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SelectorRapido(
        producto: producto,
        agregadosDisponibles: agregadosCompatibles,
        onAgregar: (item) => setState(() => _items.add(item)),
      ),
    );
  }

  Future<void> _enviarPedido() async {
    if (_items.isEmpty) return;
    setState(() => _enviando = true);
    try {
      final items = _items
          .map(
            (item) => {
              "productoVarianteId": item.variante.id,
              "cantidad": item.cantidad,
              if (item.notas.isNotEmpty) "notas": item.notas,
              if (item.agregados.isNotEmpty)
                "agregados": item.agregados
                    .map((a) => {"agregadoId": a.id})
                    .toList(),
            },
          )
          .toList();

      await PedidosService.crear(mesaId: widget.mesa.id, items: items);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pedido enviado a Mesa ${widget.mesa.numero}"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = [
      "Todas",
      ...{for (final p in _productos) p.categoriaNombre},
    ];
    final filtrados = _categoria == "Todas"
        ? _productos
        : _productos.where((p) => p.categoriaNombre == _categoria).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa ${widget.mesa.numero}"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "${_items.fold(0, (s, i) => s + i.cantidad)} items",
                style: const TextStyle(fontSize: 13, color: AppColors.gray),
              ),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: PizzaLoading(mensaje: "Cargando el menú..."))
          : Column(
              children: [
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    children: categorias
                        .map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: cat == _categoria,
                              onSelected: (_) =>
                                  setState(() => _categoria = cat),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final producto = filtrados[index];
                      final agotado = producto.variantes.every(
                        (v) => !v.disponible,
                      );
                      return Opacity(
                        opacity: agotado ? 0.5 : 1,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              producto.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              agotado
                                  ? "Agotado"
                                  : "Desde S/. ${producto.precioDesde.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: agotado
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => _agregarProducto(producto),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviarPedido,
                  child: _enviando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(
                          "Enviar pedido — S/. ${_total.toStringAsFixed(2)}",
                        ),
                ),
              ),
            ),
    );
  }
}

class _SelectorRapido extends StatefulWidget {
  final Producto producto;
  final List<Agregado> agregadosDisponibles;
  final void Function(ItemPedidoMozo) onAgregar;
  const _SelectorRapido({
    required this.producto,
    required this.agregadosDisponibles,
    required this.onAgregar,
  });

  @override
  State<_SelectorRapido> createState() => _SelectorRapidoState();
}

class _SelectorRapidoState extends State<_SelectorRapido> {
  late Variante _variante;
  final Set<int> _agregadosSel = {};
  final _notasCtrl = TextEditingController();
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    _variante = widget.producto.variantes.firstWhere(
      (v) => v.disponible,
      orElse: () => widget.producto.variantes.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.producto.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: widget.producto.variantes
                  .where((v) => v.disponible)
                  .map((v) {
                    final sel = v.id == _variante.id;
                    return ChoiceChip(
                      label: Text(
                        "${v.tamano} · S/.${v.precio.toStringAsFixed(0)}",
                      ),
                      selected: sel,
                      onSelected: (_) => setState(() {
                        _variante = v;
                        _agregadosSel.clear();
                      }),
                    );
                  })
                  .toList(),
            ),
            if (widget.agregadosDisponibles.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                "Agregados",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Wrap(
                spacing: 8,
                children: widget.agregadosDisponibles.map((a) {
                  final sel = _agregadosSel.contains(a.id);
                  return FilterChip(
                    label: Text(a.nombre),
                    selected: sel,
                    onSelected: (v) => setState(
                      () => v
                          ? _agregadosSel.add(a.id)
                          : _agregadosSel.remove(a.id),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _notasCtrl,
              decoration: const InputDecoration(labelText: "Notas (opcional)"),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _cantidad > 1
                          ? () => setState(() => _cantidad--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text("$_cantidad"),
                    IconButton(
                      onPressed: () => setState(() => _cantidad++),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(130, 46),
                  ),
                  onPressed: () {
                    final agregados = widget.agregadosDisponibles
                        .where((a) => _agregadosSel.contains(a.id))
                        .toList();
                    widget.onAgregar(
                      ItemPedidoMozo(
                        producto: widget.producto,
                        variante: _variante,
                        agregados: agregados,
                        cantidad: _cantidad,
                        notas: _notasCtrl.text.trim(),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Agregar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
