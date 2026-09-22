import 'package:flutter/material.dart';
import '../core/theme.dart';
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

  final _pantallas = const [
    MenuScreen(),
    PedidosHistorialScreen(),
    PerfilScreen(),
  ];

  final _items = const [
    (icono: Icons.local_pizza_outlined, iconoActivo: Icons.local_pizza, texto: "Menú"),
    (icono: Icons.receipt_long_outlined, iconoActivo: Icons.receipt_long, texto: "Pedidos"),
    (icono: Icons.person_outline, iconoActivo: Icons.person, texto: "Perfil"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: _pantallas),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, -3))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final activo = i == _indice;
                final item = _items[i];
                return GestureDetector(
                  onTap: () => setState(() => _indice = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: activo ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          activo ? item.iconoActivo : item.icono,
                          color: activo ? AppColors.primary : AppColors.gray,
                          size: 24,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: activo
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text(
                                    item.texto,
                                    style: const TextStyle(
                                        color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}