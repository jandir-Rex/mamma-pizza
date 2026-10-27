import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/entrega.dart';
import '../services/pedidos_service.dart';
import '../widgets/pizza_loading.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  static const _diasSemana = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"];

  late final List<DateTime> _dias = List.generate(7, (i) {
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month, hoy.day).subtract(Duration(days: i));
  });
  late DateTime _dia = _dias.first;

  List<Entrega> _lista = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await PedidosService.historial(_dia);
      if (!mounted) return;
      setState(() => _lista = datos);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _etiquetaDia(int i) {
    if (i == 0) return "Hoy";
    if (i == 1) return "Ayer";
    final d = _dias[i];
    return "${_diasSemana[d.weekday - 1]} ${d.day}";
  }

  @override
  Widget build(BuildContext context) {
    final entregadas = _lista.where((e) => e.estado == "ENTREGADO").toList();
    final efectivo = entregadas.where((e) => e.esEfectivo).fold<double>(0, (s, e) => s + e.total);
    final total = entregadas.fold<double>(0, (s, e) => s + e.total);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text("Historial", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text("Tus entregas de los últimos 7 días", style: TextStyle(color: AppColors.gray, fontSize: 13)),
          ),
          const SizedBox(height: 14),

          // Selector de día
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _dias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final activo = _dias[i] == _dia;
                return GestureDetector(
                  onTap: () {
                    if (activo) return;
                    setState(() => _dia = _dias[i]);
                    _cargar();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: activo ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: activo ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      _etiquetaDia(i),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: activo ? Colors.white : AppColors.dark),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Resumen del día
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  _Cifra(valor: "${entregadas.length}", etiqueta: "Entregas"),
                  _separador(),
                  _Cifra(valor: soles(efectivo), etiqueta: "En efectivo"),
                  _separador(),
                  _Cifra(valor: soles(total), etiqueta: "Total"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Expanded(child: _contenido()),
        ],
      ),
    );
  }

  Widget _separador() => Container(width: 1, height: 34, color: Colors.white24);

  Widget _contenido() {
    if (_cargando) return const Center(child: PizzaLoading(mensaje: "Cargando historial..."));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
            TextButton(onPressed: _cargar, child: const Text("Reintentar")),
          ],
        ),
      );
    }
    if (_lista.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("🍕", style: TextStyle(fontSize: 44)),
            SizedBox(height: 8),
            Text("Sin entregas este día", style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: _lista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _FilaHistorial(entrega: _lista[i]),
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  final String valor;
  final String etiqueta;
  const _Cifra({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valor, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(etiqueta, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _FilaHistorial extends StatelessWidget {
  final Entrega entrega;
  const _FilaHistorial({required this.entrega});

  @override
  Widget build(BuildContext context) {
    final e = entrega;
    final color = EstadoPedidoUI.color(e.estado);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(
              e.estado == "ENTREGADO" ? Icons.check_circle_rounded : (e.estado == "CANCELADO" ? Icons.cancel_rounded : Icons.timelapse_rounded),
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.codigo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  "${hora(e.creadoEn)} · ${e.clienteNombre ?? 'Cliente'}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.gray, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(soles(e.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  EstadoPedidoUI.etiqueta(e.estado),
                  style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}