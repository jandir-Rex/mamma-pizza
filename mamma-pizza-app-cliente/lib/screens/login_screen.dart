import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../providers/auth_provider.dart';
import 'registro_screen.dart';
import 'main_shell.dart';

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
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        desvanecer(const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(child: Text("🍕", style: TextStyle(fontSize: 40))),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Mamma Pizza",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.dark),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "El sabor de la felicidad",
                    style: TextStyle(color: AppColors.gray, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 36),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    child: _error != null
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.mail_outline, color: AppColors.gray, size: 20),
                    ),
                    validator: (v) => (v == null || !v.contains("@")) ? "Ingresa un email válido" : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _ocultarPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _manejarLogin(),
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.gray, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.gray,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Ingresa tu contraseña" : null,
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _cargando ? null : _manejarLogin,
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : const Text("Ingresar"),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿No tienes cuenta?", style: TextStyle(color: AppColors.gray, fontSize: 13)),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(deslizarDesdeDerecha(const RegistroScreen()));
                        },
                        child: const Text(
                          "Regístrate",
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}