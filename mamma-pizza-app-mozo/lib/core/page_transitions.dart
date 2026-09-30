import 'package:flutter/material.dart';

Route<T> deslizarDesdeDerecha<T>(Widget pantalla) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => pantalla,
    transitionsBuilder: (_, animation, __, child) {
      final curva = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curva),
        child: FadeTransition(opacity: curva, child: child),
      );
    },
  );
}

Route<T> desvanecer<T>(Widget pantalla) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => pantalla,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}