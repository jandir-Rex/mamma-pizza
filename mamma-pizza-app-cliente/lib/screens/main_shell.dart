import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/barra_carrito.dart';
import '../widgets/presionable.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'pedidos_historial_screen.dart';
import 'perfil_screen.dart';

class _ItemNav {
  final IconData icono;
  final IconData iconoActivo;
  final String texto;
  const _ItemNav(this.icono, this.iconoActivo, this.texto);
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0;

  final ValueNotifier<String> _categoria = ValueNotifier<String>("Todas");

  void _irAMenu([String categoria = "Todas"]) {
    _categoria.value = categoria;
    setState(() => _indice = 1);
  }

  void _irAInicio() {
    setState(() => _indice = 0);
  }

  late final List<Widget> _pantallas = [
    HomeScreen(onVerMenu: _irAMenu),
    MenuScreen(categoria: _categoria, onVolver: _irAInicio),
    const PedidosHistorialScreen(),
    const PerfilScreen(),
  ];

  static const _items = [
    _ItemNav(Icons.home_outlined, Icons.home_rounded, "Inicio"),
    _ItemNav(Icons.local_pizza_outlined, Icons.local_pizza, "Menú"),
    _ItemNav(Icons.receipt_long_outlined, Icons.receipt_long, "Pedidos"),
    _ItemNav(Icons.person_outline, Icons.person, "Perfil"),
  ];

  @override
  void dispose() {
    _categoria.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Atrás en otra pestaña regresa a Inicio en vez de cerrar la app.
    return PopScope(
      canPop: _indice == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _irAInicio();
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(index: _indice, children: _pantallas),

            // Único carrito de la aplicación: aparece cuando hay productos.
            const Positioned(
              right: 16,
              bottom: 16,
              child: BarraCarritoFlotante(),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: AppShadows.barraInferior,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final activo = i == _indice;
                  final item = _items[i];
                  final color = activo ? AppColors.primary : AppColors.gray;

                  return Expanded(
                    child: Presionable(
                      onTap: () => setState(() => _indice = i),
                      etiquetaSemantica: item.texto,
                      child: SizedBox(
                        height: 56,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: AppMotion.normal,
                              curve: AppMotion.curva,
                              width: activo ? 60 : 36,
                              height: 32,
                              decoration: BoxDecoration(
                                color: activo ? AppColors.kraft : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: AnimatedSwitcher(
                                duration: AppMotion.rapida,
                                child: Icon(
                                  activo ? item.iconoActivo : item.icono,
                                  key: ValueKey(activo),
                                  color: color,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.texto,
                              style: AppFonts.cuerpo(
                                size: 12,
                                peso: activo ? FontWeight.w700 : FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}