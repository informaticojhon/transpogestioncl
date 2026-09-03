import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../utils/validators.dart';

/// Pide el correo y envía el link de recuperación de contraseña de
/// Supabase. Siempre muestra el mismo mensaje de éxito, exista o no esa
/// cuenta, para no revelar qué correos están registrados.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _enviando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    await _authRepository.enviarRecuperacionPassword(_emailController.text.trim());
    if (mounted) {
      setState(() {
        _enviando = false;
        _enviado = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _enviado
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 48, color: colorScheme.primary),
                          const SizedBox(height: 16),
                          const Text(
                            'Si el correo está registrado, te enviamos un link para restablecer tu contraseña. Revisa tu bandeja de entrada (y spam).',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Volver a iniciar sesión'),
                          ),
                        ],
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.lock_reset_rounded, size: 32, color: colorScheme.primary),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '¿Olvidaste tu contraseña?',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ingresa tu correo y te enviaremos un link para restablecerla.',
                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _enviando ? null : _enviar,
                                child: _enviando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Enviar link de recuperación'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _enviando ? null : () => Navigator.pop(context),
                              child: const Text('Volver a iniciar sesión'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
