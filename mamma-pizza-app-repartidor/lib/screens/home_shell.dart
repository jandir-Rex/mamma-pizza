import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_config.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/entregas_provider.dart';
import '../widgets/ruta_widgets.dart';
import 'historial_screen.dart';
import 'perfil_screen.dart';
import 'ruta_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;
  late final EntregasProvider _entregas;

  @override
  void initState() {
    super.initState();
    _entregas = context.read<EntregasProvider>();
    // Después del primer frame: iniciar() notifica y no se puede hacer durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) => _entregas.iniciar());
  }

  @override
  void dispose() {
    _entregas.detener();
    super.dispose();
  }

  void _ir(int i) {
    HapticFeedback.selectionClick();
    setState(() => _indice = i);
  }

  @override
  Widget build(BuildContext context) {
    final activas = context.select<EntregasProvider, int>((p) => p.activas.length);

    return Scaffold(
      // El gesto de arrastre lateral lo dejamos libre para el mapa: el menú se abre con la hamburguesa
      drawerEnableOpenDragGesture: false,
      drawer: _MenuLateral(
        onSeleccionar: (i) {
          Navigator.of(context).pop();
          _ir(i);
        },
      ),
      body: IndexedStack(
        index: _indice,
        children: [
          const RutaScreen(), // siempre vivo: no se recrea el mapa
          // Historial y Perfil se crean al entrar (así se recargan con datos frescos)
          _indice == 1 ? const HistorialScreen() : const SizedBox.shrink(),
          _indice == 2 ? const PerfilScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _BarraNavegacion(
        indice: _indice,
        badgeRuta: activas,
        onCambio: _ir,
      ),
    );
  }
}

// ===========================================================================
// Menú lateral (hamburguesa)
// ===========================================================================
class _MenuLateral extends StatelessWidget {
  final ValueChanged<int> onSeleccionar;
  const _MenuLateral({required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final prov = context.watch<EntregasProvider>();

    return Drawer(
      backgroundColor: AppColors.bg,
      width: 310,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(28))),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 22, 20, 22),
            decoration: const BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    iniciales(usuario?.nombre),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  usuario?.nombre ?? "Repartidor",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  "Mamma Pizza Delivery · Trujillo Central",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _OpcionMenu(icono: Icons.navigation_rounded, texto: "Ruta", onTap: () => onSeleccionar(0)),
          _OpcionMenu(icono: Icons.receipt_long_rounded, texto: "Historial", onTap: () => onSeleccionar(1)),
          _OpcionMenu(icono: Icons.person_rounded, texto: "Perfil", onTap: () => onSeleccionar(2)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TarjetaDisponibilidad(
              prov: prov,
              onError: (m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m))),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: SafeArea(
              top: false,
              child: BotonPildora(
                icono: Icons.call_rounded,
                texto: "Llamar al local",
                color: AppColors.primary,
                relleno: false,
                onTap: () => abrirLlamada(AppConfig.telefonoLocal),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  const _OpcionMenu({required this.icono, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
        child: Icon(icono, color: AppColors.primary, size: 21),
      ),
      title: Text(texto, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray),
      onTap: onTap,
    );
  }
}

// ===========================================================================
// Barra de navegación inferior
// ===========================================================================
class _BarraNavegacion extends StatelessWidget {
  final int indice;
  final int badgeRuta;
  final ValueChanged<int> onCambio;
  const _BarraNavegacion({required this.indice, required this.badgeRuta, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: _Item(
                  icono: Icons.navigation_rounded,
                  etiqueta: "Ruta",
                  activo: indice == 0,
                  badge: badgeRuta,
                  onTap: () => onCambio(0),
                ),
              ),
              Expanded(
                child: _Item(
                  icono: Icons.receipt_long_rounded,
                  etiqueta: "Historial",
                  activo: indice == 1,
                  onTap: () => onCambio(1),
                ),
              ),
              Expanded(
                child: _Item(
                  icono: Icons.person_rounded,
                  etiqueta: "Perfil",
                  activo: indice == 2,
                  onTap: () => onCambio(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final int badge;
  final VoidCallback onTap;
  const _Item({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 58,
                height: 36,
                decoration: BoxDecoration(
                  color: activo ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: activo
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Icon(icono, size: 23, color: activo ? Colors.white : AppColors.gray),
              ),
              if (badge > 0)
                Positioned(
                  top: -4,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      "$badge",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
              color: activo ? AppColors.primary : AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}