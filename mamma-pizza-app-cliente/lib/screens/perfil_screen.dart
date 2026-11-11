import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../providers/auth_provider.dart';
import '../widgets/presionable.dart';
import '../widgets/ui_comunes.dart';
import 'login_screen.dart';
import 'direcciones_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _editarNombre(BuildContext context) async {
    final usuario = context.read<AuthProvider>().usuario;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditarNombreSheet(nombreInicial: usuario?.nombre ?? ""),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Cerrar sesión?"),
        content: const Text("Tendrás que ingresar de nuevo para hacer pedidos."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    HapticFeedback.mediumImpact();
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(desvanecer(const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final nombre = usuario?.nombre ?? "";
    final inicial = nombre.trim().isEmpty ? "?" : nombre.trim().substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text("Mi perfil")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Aparecer(
            indice: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
              decoration: BoxDecoration(
                gradient: AppGradients.cacao,
                borderRadius: AppRadius.bMedio,
                boxShadow: AppShadows.brillo(AppColors.cacao),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: AppColors.kraft, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(inicial, style: AppFonts.marca(size: 28, color: AppColors.cacaoDark)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.cuerpo(size: 17, peso: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          usuario?.email ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.cuerpo(size: 13, color: AppColors.kraftLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: "Editar nombre",
                    onPressed: () => _editarNombre(context),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Aparecer(indice: 1, child: const _Etiqueta("CUENTA")),
          const SizedBox(height: 8),
          Aparecer(
            indice: 2,
            child: _OpcionPerfil(
              icono: Icons.location_on_outlined,
              texto: "Mis direcciones",
              subtitulo: "Dónde recibes tus pedidos",
              onTap: () => Navigator.of(context).push(deslizarDesdeDerecha(const DireccionesScreen())),
            ),
          ),
          const SizedBox(height: 16),
          Aparecer(indice: 3, child: const _Etiqueta("SOPORTE")),
          const SizedBox(height: 8),
          const Aparecer(
            indice: 4,
            child: _OpcionPerfil(
              icono: Icons.help_outline_rounded,
              texto: "Ayuda y soporte",
              subtitulo: "Próximamente",
              onTap: null,
            ),
          ),
          const SizedBox(height: 28),
          Aparecer(
            indice: 5,
            child: OutlinedButton.icon(
              onPressed: () => _cerrarSesion(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text("Cerrar sesión"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(color: AppColors.danger, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              "El sabor de la felicidad",
              style: AppFonts.marca(size: 16, color: AppColors.kraftDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: AppFonts.cuerpo(size: 12, peso: FontWeight.w600, color: AppColors.gray)
          .copyWith(letterSpacing: 1.2),
    );
  }
}

class _OpcionPerfil extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String? subtitulo;
  final VoidCallback? onTap;
  const _OpcionPerfil({
    required this.icono,
    required this.texto,
    this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activo = onTap != null;
    return Opacity(
      opacity: activo ? 1 : 0.6,
      child: Presionable(
        onTap: onTap,
        etiquetaSemantica: texto,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.bChico,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.kraftLight, shape: BoxShape.circle),
                child: Icon(icono, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(texto, style: AppFonts.cuerpo(size: 14, peso: FontWeight.w600)),
                    if (subtitulo != null)
                      Text(subtitulo!, style: AppFonts.cuerpo(size: 12, color: AppColors.gray)),
                  ],
                ),
              ),
              if (activo) const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.gray),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditarNombreSheet extends StatefulWidget {
  final String nombreInicial;
  const _EditarNombreSheet({required this.nombreInicial});

  @override
  State<_EditarNombreSheet> createState() => _EditarNombreSheetState();
}

class _EditarNombreSheetState extends State<_EditarNombreSheet> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.nombreInicial);
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _ctrl.text.trim();
    if (nombre.length < 2) {
      HapticFeedback.lightImpact();
      setState(() => _error = "Nombre muy corto");
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().actualizarPerfil(nombre: nombre);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text("Nombre actualizado")));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text("Editar nombre", style: AppFonts.titulo(size: 26)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _guardando ? null : _guardar(),
              decoration: InputDecoration(labelText: "Nombre completo", errorText: _error),
            ),
            const SizedBox(height: 16),
            BotonPrincipal(
              texto: "Guardar",
              cargando: _guardando,
              onPressed: _guardando ? null : _guardar,
            ),
          ],
        ),
      ),
    );
  }
}