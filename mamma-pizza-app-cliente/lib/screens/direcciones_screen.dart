import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../models/direccion.dart';
import '../services/direcciones_service.dart';
import '../widgets/presionable.dart';
import '../widgets/ui_comunes.dart';
import 'seleccionar_ubicacion_screen.dart';

class DireccionesScreen extends StatefulWidget {
  const DireccionesScreen({super.key});

  @override
  State<DireccionesScreen> createState() => _DireccionesScreenState();
}

class _DireccionesScreenState extends State<DireccionesScreen> {
  List<Direccion> _direcciones = [];
  bool _cargando = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!mounted) return;
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = false;
      });
    }
    try {
      final direcciones = await DireccionesService.listar();
      if (!mounted) return;
      setState(() {
        _direcciones = direcciones;
        _error = false;
      });
    } catch (_) {
      if (mounted) setState(() => _error = _direcciones.isEmpty);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _agregar() async {
    final nueva = await Navigator.of(context).push<Direccion>(
      MaterialPageRoute<Direccion>(builder: (_) => const SeleccionarUbicacionScreen()),
    );
    if (nueva != null) _cargar(silencioso: true);
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
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    try {
      await DireccionesService.eliminar(d.id);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() => _direcciones = _direcciones.where((x) => x.id != d.id).toList());
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("Dirección eliminada")));
      _cargar(silencioso: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  Widget _cuerpo() {
    if (_cargando) {
      return ListView(
        key: const ValueKey("carga"),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          EsqueletoTarjeta(alto: 84),
          EsqueletoTarjeta(alto: 84),
          EsqueletoTarjeta(alto: 84),
        ],
      );
    }
    if (_error) {
      return EstadoError(
        key: const ValueKey("error"),
        mensaje: "No pudimos cargar tus direcciones.",
        onReintentar: _cargar,
      );
    }
    if (_direcciones.isEmpty) {
      return EstadoVacio(
        key: const ValueKey("vacio"),
        emoji: "📍",
        titulo: "Aún no tienes direcciones",
        mensaje: "Guarda dónde quieres recibir tu pizza y pedirás en segundos.",
        textoAccion: "Agregar dirección",
        onAccion: _agregar,
      );
    }
    return RefreshIndicator(
      key: const ValueKey("lista"),
      color: AppColors.primary,
      onRefresh: () => _cargar(silencioso: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
        itemCount: _direcciones.length,
        itemBuilder: (context, index) {
          final d = _direcciones[index];
          return Aparecer(
            indice: index,
            child: _TarjetaDireccion(direccion: d, onEliminar: () => _eliminar(d)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis direcciones")),
      body: AnimatedSwitcher(duration: AppMotion.normal, child: _cuerpo()),
      floatingActionButton: (!_cargando && !_error && _direcciones.isNotEmpty)
          ? Presionable(
              onTap: _agregar,
              haptico: Haptico.ligero,
              etiquetaSemantica: "Agregar dirección",
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppShadows.brillo(AppColors.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_location_alt_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "Agregar dirección",
                      style: AppFonts.cuerpo(size: 14, peso: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _TarjetaDireccion extends StatelessWidget {
  final Direccion direccion;
  final VoidCallback onEliminar;
  const _TarjetaDireccion({required this.direccion, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final d = direccion;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.bMedio,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.suave,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.kraftLight, shape: BoxShape.circle),
            child: const Icon(Icons.location_on, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.zona, style: AppFonts.cuerpo(size: 14, peso: FontWeight.w600)),
                if (d.referencia != null && d.referencia!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    d.referencia!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.cuerpo(size: 12, color: AppColors.gray),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: "Eliminar dirección",
            onPressed: onEliminar,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
          ),
        ],
      ),
    );
  }
}