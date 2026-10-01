import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/barra_carrito.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'pedidos_historial_screen.dart';
import 'perfil_screen.dart';

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
    MenuScreen(
      categoria: _categoria,
      onVolver: _irAInicio,
    ),
    const PedidosHistorialScreen(),
    const PerfilScreen(),
  ];

  final _items = const [
    (
      icono: Icons.home_outlined,
      iconoActivo: Icons.home,
      texto: "Inicio",
    ),
    (
      icono: Icons.local_pizza_outlined,
      iconoActivo: Icons.local_pizza,
      texto: "Menú",
    ),
    (
      icono: Icons.receipt_long_outlined,
      iconoActivo: Icons.receipt_long,
      texto: "Pedidos",
    ),
    (
      icono: Icons.person_outline,
      iconoActivo: Icons.person,
      texto: "Perfil",
    ),
  ];

  @override
  void dispose() {
    _categoria.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _indice,
            children: _pantallas,
          ),

          // Único carrito de la aplicación.
          // Aparece desde abajo cuando hay productos.
          const Positioned(
            right: 16,
            bottom: 84,
            child: BarraCarritoFlotante(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 5,
            ),
            child: Row(
              children: List.generate(
                _items.length,
                (i) {
                  final activo = i == _indice;
                  final item = _items[i];
                  final color = activo ? AppColors.primary : AppColors.gray;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(
                        () => _indice = i,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              activo ? item.iconoActivo : item.icono,
                              color: color,
                              size: 23,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.texto,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    activo ? FontWeight.w700 : FontWeight.w400,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
