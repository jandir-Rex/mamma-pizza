import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/direccion.dart';
import '../services/direcciones_service.dart';
import '../widgets/pizza_loading.dart';

class DireccionesScreen extends StatefulWidget {
  const DireccionesScreen({super.key});

  @override
  State<DireccionesScreen> createState() => _DireccionesScreenState();
}

class _DireccionesScreenState extends State<DireccionesScreen> {
  List<Direccion> _direcciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final direcciones = await DireccionesService.listar();
      if (!mounted) return;
      setState(() => _direcciones = direcciones);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _agregar() async {
    final zonaCtrl = TextEditingController();
    final refCtrl = TextEditingController();

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Nueva dirección", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: zonaCtrl, decoration: const InputDecoration(labelText: "Zona / Dirección")),
            const SizedBox(height: 12),
            TextField(controller: refCtrl, decoration: const InputDecoration(labelText: "Referencia (opcional)")),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Guardar dirección")),
          ],
        ),
      ),
    );

    if (guardar == true && zonaCtrl.text.trim().isNotEmpty) {
      try {
        await DireccionesService.crear(zona: zonaCtrl.text.trim(), referencia: refCtrl.text.trim(), lat: -8.1116, lng: -79.0287);
        _cargar();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))));
      }
    }
  }

  Future<void> _eliminar(Direccion d) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar dirección?"),
        content: Text(d.zona),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Eliminar", style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await DireccionesService.eliminar(d.id);
        _cargar();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis direcciones")),
      body: _cargando
          ? const Center(child: PizzaLoading(mensaje: "Cargando..."))
          : _direcciones.isEmpty
              ? const Center(child: Text("No tienes direcciones guardadas", style: TextStyle(color: AppColors.gray)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _direcciones.length,
                  itemBuilder: (context, index) {
                    final d = _direcciones[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.zona, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                if (d.referencia != null && d.referencia!.isNotEmpty)
                                  Text(d.referencia!, style: const TextStyle(color: AppColors.gray, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _eliminar(d),
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text("Agregar"),
      ),
    );
  }
}