import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../models/entrega.dart';
import '../services/pedidos_service.dart';
import '../services/repartidor_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/pizza_loading.dart';
import 'entrega_activa_screen.dart';
import 'login_screen.dart';

class MisEntregasScreen extends StatefulWidget {
  const MisEntregasScreen({super.key});

  @override
  State<MisEntregasScreen> createState() => _MisEntregasScreenState();
}

class _MisEntregasScreenState extends State<MisEntregasScreen> {
  List<Entrega> _entregas = [];
  bool _cargando = true;
  bool _disponible = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final entregas = await PedidosService.misEntregas();
      if (!mounted) return;
      setState(() => _entregas = entregas);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarDisponibilidad(bool valor) async {
    setState(() => _disponible = valor);
    try {
      await RepartidorService.actualizarDisponibilidad(valor);
    } catch (_) {
      setState(() => _disponible = !valor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activas = _entregas.where((e) => e.esActiva).toList();
    final completadas = _entregas.where((e) => !e.esActiva).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis entregas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              }
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: PizzaLoading(mensaje: "Cargando tus entregas..."))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: SwitchListTile(
                      value: _disponible,
                      onChanged: _cambiarDisponibilidad,
                      activeThumbColor: AppColors.success,
                      title: Text(_disponible ? "Disponible" : "No disponible", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text("Controla si te pueden asignar nuevos pedidos", style: TextStyle(fontSize: 11.5)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (activas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: const [
                          Text("🛵", style: TextStyle(fontSize: 48)),
                          SizedBox(height: 10),
                          Text("Esperando asignación...", style: TextStyle(color: AppColors.gray)),
                        ],
                      ),
                    )
                  else ...[
                    const Text("Entrega activa", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...activas.map((e) => _TarjetaEntrega(
                          entrega: e,
                          destacada: true,
                          onTap: () async {
                            await Navigator.of(context).push(deslizarDesdeDerecha(EntregaActivaScreen(entrega: e)));
                            _cargar();
                          },
                        )),
                  ],
                  if (completadas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text("Completadas hoy", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...completadas.map((e) => _TarjetaEntrega(entrega: e, destacada: false, onTap: () {})),
                  ],
                ],
              ),
            ),
    );
  }
}

class _TarjetaEntrega extends StatelessWidget {
  final Entrega entrega;
  final bool destacada;
  final VoidCallback onTap;
  const _TarjetaEntrega({required this.entrega, required this.destacada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = EstadoPedidoUI.color(entrega.estado);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: destacada ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.4) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: destacada ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entrega.codigo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(EstadoPedidoUI.etiqueta(entrega.estado), style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(entrega.direccion?.zona ?? "Sin dirección", style: const TextStyle(color: AppColors.gray, fontSize: 12.5)),
                const SizedBox(height: 6),
                Text(
                  entrega.metodoPago == "EFECTIVO" ? "Cobrar S/. ${entrega.total.toStringAsFixed(2)}" : "S/. ${entrega.total.toStringAsFixed(2)} — ${entrega.metodoPago}",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: entrega.metodoPago == "EFECTIVO" ? AppColors.warning : AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}