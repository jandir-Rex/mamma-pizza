import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_config.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/entregas_provider.dart';
import '../widgets/ruta_widgets.dart';

/// Pestaña "Perfil" del repartidor: datos, estado de trabajo, ubicación y cierre de sesión.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final entregas = context.read<EntregasProvider>();
    final auth = context.read<AuthProvider>();
    final pendientes = entregas.activas.length;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Cerrar sesión?"),
        content: Text(
          pendientes > 0
              ? "Tienes $pendientes entrega${pendientes == 1 ? '' : 's'} activa${pendientes == 1 ? '' : 's'}. "
                  "Si cierras sesión dejarás de recibir actualizaciones de tus pedidos."
              : "Dejarás de recibir pedidos hasta que vuelvas a ingresar.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Cerrar sesión",
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    entregas.detener();

    // OJO: si tu AuthProvider usa otro nombre para cerrar sesión, cámbialo aquí.
    // Se prueban los dos nombres más comunes para que compile en cualquier caso.
    final dynamic dinamico = auth;
    try {
      await dinamico.logout();
    } on NoSuchMethodError {
      await dinamico.cerrarSesion();
    }
    // _Arrancador (main.dart) detecta usuario == null y muestra el login solo.
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final prov = context.watch<EntregasProvider>();
    final nombre = usuario?.nombre ?? "Repartidor";

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          const Text("Perfil", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),

          // ---- Tarjeta de identidad ----
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Text(
                    iniciales(nombre),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              "Repartidor · Mamma Pizza",
                              style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ---- Resumen de hoy ----
          Row(
            children: [
              Expanded(
                child: _Dato(
                  icono: Icons.check_circle_rounded,
                  color: AppColors.success,
                  valor: "${prov.entregadasHoy.length}",
                  etiqueta: "Entregas hoy",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Dato(
                  icono: Icons.route_rounded,
                  color: AppColors.primary,
                  valor: "${prov.activas.length}",
                  etiqueta: "En curso",
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ---- Disponibilidad ----
          TarjetaDisponibilidad(
            prov: prov,
            onError: (m) => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(m))),
          ),
          const SizedBox(height: 14),

          // ---- Ubicación ----
          _TarjetaUbicacion(
            activa: prov.permisoUbicacion,
            onReintentar: prov.reintentarUbicacion,
          ),
          const SizedBox(height: 14),

          // ---- Acciones ----
          _Accion(
            icono: Icons.storefront_rounded,
            color: AppColors.primary,
            titulo: "Llamar al local",
            subtitulo: "Para dudas con un pedido o un código bloqueado",
            onTap: () => abrirLlamada(AppConfig.telefonoLocal),
          ),
          const SizedBox(height: 10),
          _Accion(
            icono: Icons.logout_rounded,
            color: AppColors.danger,
            titulo: "Cerrar sesión",
            subtitulo: "Salir de tu cuenta en este dispositivo",
            onTap: () => _cerrarSesion(context),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Mamma Pizza · El sabor de la felicidad",
              style: TextStyle(color: AppColors.gray, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String valor;
  final String etiqueta;
  const _Dato({required this.icono, required this.color, required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.1)),
                Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.gray, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaUbicacion extends StatelessWidget {
  final bool activa;
  final Future<void> Function() onReintentar;
  const _TarjetaUbicacion({required this.activa, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final color = activa ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)),
            child: Icon(
              activa ? Icons.my_location_rounded : Icons.location_off_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activa ? "Ubicación activa" : "Ubicación apagada",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                Text(
                  activa
                      ? "El local ve qué tan cerca estás para asignarte pedidos"
                      : "Sin ubicación no se te sugieren pedidos ni verás el tiempo de llegada",
                  style: const TextStyle(fontSize: 11.5, color: AppColors.gray),
                ),
              ],
            ),
          ),
          if (!activa) ...[
            const SizedBox(width: 8),
            BotonPildora(
              icono: Icons.refresh_rounded,
              texto: "Activar",
              color: AppColors.warning,
              onTap: () => onReintentar(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  const _Accion({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: color == AppColors.danger ? color : AppColors.dark),
                    ),
                    Text(subtitulo, style: const TextStyle(fontSize: 11.5, color: AppColors.gray)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.gray),
            ],
          ),
        ),
      ),
    );
  }
}