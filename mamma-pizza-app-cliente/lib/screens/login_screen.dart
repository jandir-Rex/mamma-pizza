import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../providers/auth_provider.dart';
import '../widgets/ui_comunes.dart';
import 'registro_screen.dart';

/// Se abre encima de la pantalla actual (ver requerirSesion).
/// Devuelve true por Navigator.pop cuando el usuario inicia sesión o se registra.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _manejarLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _irARegistro() async {
    final ok = await Navigator.of(context)
        .push<bool>(deslizarDesdeDerecha(const RegistroScreen()));
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              Stack(
                children: [
                  const _CabeceraMarca(),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SafeArea(
                      child: IconButton(
                        tooltip: "Cerrar",
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Aparecer(
                  indice: 2,
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text("Bienvenido de vuelta", style: AppFonts.titulo(size: 30)),
                          const SizedBox(height: 4),
                          Text(
                            "Inicia sesión para confirmar tu pedido",
                            style: AppFonts.cuerpo(size: 14, color: AppColors.gray),
                          ),
                          const SizedBox(height: 24),
                          CajaError(mensaje: _error),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.mail_outline, size: 20),
                            ),
                            validator: (v) {
                              final t = v?.trim() ?? "";
                              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                                  ? null
                                  : "Ingresa un email válido";
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _ocultarPassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onFieldSubmitted: (_) => _manejarLogin(),
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                tooltip: _ocultarPassword ? "Mostrar contraseña" : "Ocultar contraseña",
                                icon: Icon(
                                  _ocultarPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? "Ingresa tu contraseña" : null,
                          ),
                          const SizedBox(height: 28),
                          BotonPrincipal(
                            texto: "Ingresar",
                            cargando: _cargando,
                            onPressed: _cargando ? null : _manejarLogin,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "¿No tienes cuenta?",
                                style: AppFonts.cuerpo(size: 13, color: AppColors.gray),
                              ),
                              TextButton(
                                onPressed: _cargando ? null : _irARegistro,
                                child: const Text("Regístrate"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CabeceraMarca extends StatelessWidget {
  const _CabeceraMarca();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.cacao,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
          child: Aparecer(
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.kraft,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.media,
                  ),
                  alignment: Alignment.center,
                  child: const ExcludeSemantics(child: Text("🍕", style: TextStyle(fontSize: 46))),
                ),
                const SizedBox(height: 18),
                Text("Mamma Pizza", style: AppFonts.marca(size: 36, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  "El sabor de la felicidad",
                  style: AppFonts.cuerpo(size: 14, color: AppColors.kraftLight)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}