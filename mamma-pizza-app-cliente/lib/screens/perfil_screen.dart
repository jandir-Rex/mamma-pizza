import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../core/page_transitions.dart';
import 'login_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    return Scaffold(
      appBar: AppBar(title: const Text("Mi perfil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        Text(usuario?.email ?? "",
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _opcionPerfil(Icons.location_on_outlined, "Mis direcciones"),
            _opcionPerfil(Icons.help_outline, "Ayuda y soporte"),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    desvanecer(const LoginScreen()),
                    (route) => false,
                  );
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
      ),
    );
  }

  Widget _opcionPerfil(IconData icono, String texto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icono, color: AppColors.primary),
        title: Text(texto, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.gray),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}