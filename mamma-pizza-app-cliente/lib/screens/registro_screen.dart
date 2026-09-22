import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/page_transitions.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _manejarRegistro() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().registro(
            nombre: _nombreCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            telefono: _telefonoCtrl.text.trim(),
          );
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
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  child: _error != null
                      ? Container(
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
                                child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                TextFormField(
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Nombre completo",
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.gray, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? "Nombre muy corto" : null,
                ),
                const SizedBox(height: 14),
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
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Teléfono (opcional)",
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.gray, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _ocultarPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _manejarRegistro(),
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
                  validator: (v) => (v == null || v.length < 6) ? "Mínimo 6 caracteres" : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _cargando ? null : _manejarRegistro,
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Text("Crear cuenta"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}