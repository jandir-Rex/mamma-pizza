import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/producto.dart';
import '../models/agregado.dart';
import '../models/item_carrito.dart';
import '../providers/carrito_provider.dart';

Future<void> mostrarDetalleProducto(
  BuildContext context,
  Producto producto,
  List<Agregado> agregadosDisponibles,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _DetalleProductoSheet(producto: producto, agregadosDisponibles: agregadosDisponibles),
  );
}

class _DetalleProductoSheet extends StatefulWidget {
  final Producto producto;
  final List<Agregado> agregadosDisponibles;
  const _DetalleProductoSheet({required this.producto, required this.agregadosDisponibles});

  @override
  State<_DetalleProductoSheet> createState() => _DetalleProductoSheetState();
}

class _DetalleProductoSheetState extends State<_DetalleProductoSheet> {
  late Variante _varianteSeleccionada;
  final Set<int> _agregadosSeleccionados = {};
  final _notasCtrl = TextEditingController();
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    _varianteSeleccionada = widget.producto.variantes.firstWhere(
      (v) => v.disponible,
      orElse: () => widget.producto.variantes.first,
    );
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  double get _precioUnitario {
    double precio = _varianteSeleccionada.precio;
    for (final ag in widget.agregadosDisponibles.where((a) => _agregadosSeleccionados.contains(a.id))) {
      precio += ag.precioParaTamano(_varianteSeleccionada.tamano) ?? 0;
    }
    return precio;
  }

  @override
  Widget build(BuildContext context) {
    final agregadosCompatibles = widget.agregadosDisponibles
        .where((a) => a.disponible && a.precioParaTamano(_varianteSeleccionada.tamano) != null)
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E2DA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(widget.producto.nombre,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              if (widget.producto.descripcion != null)
                Text(widget.producto.descripcion!, style: const TextStyle(color: AppColors.gray)),
              const SizedBox(height: 20),

              const Text("Elige el tamaño", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...widget.producto.variantes.map((v) {
                final seleccionado = v.id == _varianteSeleccionada.id;
                return Opacity(
                  opacity: v.disponible ? 1 : 0.4,
                  child: GestureDetector(
                    onTap: v.disponible
                        ? () => setState(() {
                              _varianteSeleccionada = v;
                              _agregadosSeleccionados.clear();
                            })
                        : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: seleccionado ? AppColors.primary.withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: seleccionado ? AppColors.primary : const Color(0xFFE8E2DA),
                          width: seleccionado ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: seleccionado ? AppColors.primary : AppColors.gray,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              v.disponible ? _capitalizar(v.tamano) : "${_capitalizar(v.tamano)} — Agotado",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text("S/. ${v.precio.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              if (agregadosCompatibles.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text("Agregados", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...agregadosCompatibles.map((ag) {
                  final precio = ag.precioParaTamano(_varianteSeleccionada.tamano)!;
                  final marcado = _agregadosSeleccionados.contains(ag.id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (marcado) {
                        _agregadosSeleccionados.remove(ag.id);
                      } else {
                        _agregadosSeleccionados.add(ag.id);
                      }
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: marcado ? AppColors.primary.withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: marcado ? AppColors.primary : const Color(0xFFE8E2DA),
                          width: marcado ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            marcado ? Icons.check_box : Icons.check_box_outline_blank,
                            color: marcado ? AppColors.primary : AppColors.gray,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(ag.nombre, style: const TextStyle(fontSize: 14))),
                          Text("+ S/. ${precio.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),
              const Text("Instrucciones especiales", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _notasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(hintText: "Ej. sin cebolla, cortar en 12..."),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Cantidad", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text("$_cantidad", style: const TextStyle(fontSize: 16)),
                      IconButton(
                        onPressed: () => setState(() => _cantidad++),
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  final agregadosElegidos = widget.agregadosDisponibles
                      .where((a) => _agregadosSeleccionados.contains(a.id))
                      .toList();

                  context.read<CarritoProvider>().agregar(ItemCarrito(
                        producto: widget.producto,
                        variante: _varianteSeleccionada,
                        agregados: agregadosElegidos,
                        cantidad: _cantidad,
                        notas: _notasCtrl.text.trim(),
                      ));
                  Navigator.pop(context);
                },
                child: Text("Agregar al pedido — S/. ${(_precioUnitario * _cantidad).toStringAsFixed(2)}"),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

String _capitalizar(String texto) {
  final limpio = texto.replaceAll("_", " ");
  return limpio[0].toUpperCase() + limpio.substring(1);
}