import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'direcciones_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _editarNombre(BuildContext context) async {
    final usuario = context.read<AuthProvider>().usuario;
    final ctrl = TextEditingController(text: usuario?.nombre ?? "");
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Editar nombre", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(labelText: "Nombre completo", errorText: error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().length < 2) {
                    setModalState(() => error = "Nombre muy corto");
                    return;
                  }
                  try {
                    await context.read<AuthProvider>().actualizarPerfil(nombre: ctrl.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    setModalState(() => error = e.toString().replaceFirst("Exception: ", ""));
                  }
                },
                child: const Text("Guardar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    return Scaffold(
      appBar: AppBar(title: const Text("Mi perfil")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    (usuario?.nombre ?? "?").substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario?.nombre ?? "",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(usuario?.email ?? "", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editarNombre(context),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("Cuenta", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray, fontSize: 12)),
          const SizedBox(height: 8),
          _opcionPerfil(
            context,
            icono: Icons.location_on_outlined,
            texto: "Mis direcciones",
            onTap: () => Navigator.of(context).push(deslizarDesdeDerecha(const DireccionesScreen())),
          ),
          _opcionPerfil(
            context,
            icono: Icons.badge_outlined,
            texto: "Editar nombre",
            onTap: () => _editarNombre(context),
          ),
          const SizedBox(height: 16),
          const Text("Soporte", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gray, fontSize: 12)),
          const SizedBox(height: 8),
          _opcionPerfil(context, icono: Icons.help_outline, texto: "Ayuda y soporte", onTap: () {}),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(desvanecer(const LoginScreen()), (route) => false);
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
            label: const Text("Cerrar sesión", style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcionPerfil(BuildContext context, {required IconData icono, required String texto, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ListTile(
              leading: Icon(icono, color: AppColors.primary),
              title: Text(texto, style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.gray),
            ),
          ),
        ),
      ),
    );
  }
}