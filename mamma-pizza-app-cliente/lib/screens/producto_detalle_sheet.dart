import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/producto.dart';
import '../models/agregado.dart';
import '../models/item_carrito.dart';
import '../providers/carrito_provider.dart';
import '../widgets/presionable.dart';
import '../widgets/tony_widgets.dart'; // PizzaPlaceholder + iconoCategoria
import '../widgets/ui_comunes.dart';

Future<void> mostrarDetalleProducto(
  BuildContext context,
  Producto producto,
  List<Agregado> agregadosDisponibles,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DetalleProductoSheet(
      producto: producto,
      agregadosDisponibles: agregadosDisponibles,
    ),
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
  bool _cerrando = false;

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

  void _agregar() {
    final messenger = ScaffoldMessenger.of(context);
    final nombre = widget.producto.nombre;
    final agregadosElegidos =
        widget.agregadosDisponibles.where((a) => _agregadosSeleccionados.contains(a.id)).toList();

    context.read<CarritoProvider>().agregar(ItemCarrito(
          producto: widget.producto,
          variante: _varianteSeleccionada,
          agregados: agregadosElegidos,
          cantidad: _cantidad,
          notas: _notasCtrl.text.trim(),
        ));

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.albahaca, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text("$nombre agregado al pedido")),
            ],
          ),
        ),
      );
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(texto, style: AppFonts.titulo(size: 22)),
      );

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final agregadosCompatibles = widget.agregadosDisponibles
        .where((a) => a.disponible && a.precioParaTamano(_varianteSeleccionada.tamano) != null)
        .toList();
    final anchoImagen = MediaQuery.of(context).size.width - 40;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          // Arrastrar hasta abajo cierra la hoja.
          if (!_cerrando && n.extent <= n.minExtent + 0.01) {
            _cerrando = true;
            Navigator.of(context).maybePop();
          }
          return false;
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.medio),
                          child: PizzaPlaceholder(
                            width: anchoImagen,
                            height: 190,
                            radius: AppRadius.medio,
                            iconSize: 64,
                            icono: iconoCategoria(producto.categoriaNombre),
                            imagenUrl: producto.imagenUrl,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Presionable(
                            onTap: () => Navigator.pop(context),
                            haptico: Haptico.ligero,
                            etiquetaSemantica: "Cerrar",
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: AppShadows.suave,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 20, color: AppColors.dark),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(producto.nombre, style: AppFonts.titulo(size: 32)),
                    if (producto.descripcion != null && producto.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        producto.descripcion!,
                        style: AppFonts.cuerpo(size: 14, color: AppColors.gray, altura: 1.45),
                      ),
                    ],

                    _titulo("Elige el tamaño"),
                    ...producto.variantes.map((v) {
                      final seleccionado = v.id == _varianteSeleccionada.id;
                      return TarjetaSeleccion(
                        activo: seleccionado,
                        habilitado: v.disponible,
                        onTap: () => setState(() {
                          _varianteSeleccionada = v;
                          _agregadosSeleccionados.clear();
                        }),
                        child: Row(
                          children: [
                            IndicadorSeleccion(activo: seleccionado),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    capitalizar(v.tamano),
                                    style: AppFonts.cuerpo(size: 14, peso: FontWeight.w600),
                                  ),
                                  if (!v.disponible)
                                    Row(
                                      children: [
                                        const Icon(Icons.block, size: 13, color: AppColors.danger),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Agotado",
                                          style: AppFonts.cuerpo(
                                            size: 12,
                                            peso: FontWeight.w600,
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            Text("S/. ${v.precio.toStringAsFixed(2)}", style: AppFonts.precio(size: 20)),
                          ],
                        ),
                      );
                    }),

                    if (agregadosCompatibles.isNotEmpty) ...[
                      _titulo("Agregados"),
                      ...agregadosCompatibles.map((ag) {
                        final precio = ag.precioParaTamano(_varianteSeleccionada.tamano)!;
                        final marcado = _agregadosSeleccionados.contains(ag.id);
                        return TarjetaSeleccion(
                          activo: marcado,
                          onTap: () => setState(() {
                            if (marcado) {
                              _agregadosSeleccionados.remove(ag.id);
                            } else {
                              _agregadosSeleccionados.add(ag.id);
                            }
                          }),
                          child: Row(
                            children: [
                              IndicadorSeleccion(activo: marcado, cuadrado: true),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(ag.nombre, style: AppFonts.cuerpo(size: 14, peso: FontWeight.w500)),
                              ),
                              Text(
                                "+ S/. ${precio.toStringAsFixed(2)}",
                                style: AppFonts.cuerpo(size: 13, peso: FontWeight.w600, color: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    _titulo("Instrucciones especiales"),
                    TextField(
                      controller: _notasCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: "Ej. sin cebolla, cortar en 12..."),
                    ),
                  ],
                ),
              ),
              BarraInferior(
                child: Row(
                  children: [
                    SelectorCantidad(
                      cantidad: _cantidad,
                      onMenos: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                      onMas: () => setState(() => _cantidad++),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BotonPrincipal(
                        texto: "Agregar · S/. ${(_precioUnitario * _cantidad).toStringAsFixed(2)}",
                        onPressed: _varianteSeleccionada.disponible ? _agregar : null,
                      ),
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