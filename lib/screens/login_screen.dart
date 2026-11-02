import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../repositories/auth_repository.dart';
import '../utils/login_lockout.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool cargando = false;
  String? error;
  Duration? _bloqueoRestante;
  Timer? _timerBloqueo;

  @override
  void dispose() {
    _timerBloqueo?.cancel();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final restante = await LoginLockout.tiempoRestante(email);
    if (restante != null) {
      _activarBloqueo(restante);
      return;
    }

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      await _authRepository.login(email, passwordController.text);
      await LoginLockout.reset(email);
      // Le avisa al navegador / iPhone que el inicio de sesión funcionó,
      // para que ofrezca guardar el correo y la contraseña en su gestor
      // de contraseñas (llavero de iCloud, Google, etc.).
      TextInput.finishAutofillContext();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      final bloqueo = await LoginLockout.registrarIntentoFallido(email);
      if (!mounted) return;
      if (bloqueo != null) {
        _activarBloqueo(bloqueo);
      } else {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  void _activarBloqueo(Duration duracion) {
    _timerBloqueo?.cancel();
    setState(() => _bloqueoRestante = duracion);
    _timerBloqueo = Timer.periodic(const Duration(seconds: 1), (timer) {
      final restante = _bloqueoRestante;
      if (restante == null) {
        timer.cancel();
        return;
      }
      final nuevoRestante = restante - const Duration(seconds: 1);
      if (nuevoRestante.inSeconds <= 0) {
        timer.cancel();
        setState(() => _bloqueoRestante = null);
      } else {
        setState(() => _bloqueoRestante = nuevoRestante);
      }
    });
  }

  String _formatearDuracion(Duration d) {
    final segundos = d.inSeconds;
    if (segundos >= 60) return '${(segundos / 60).ceil()} min';
    return '$segundos s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  // Agrupa correo y contraseña para que el gestor de
                  // contraseñas del dispositivo pueda rellenarlos. Al salir
                  // de la pantalla sin iniciar sesión (ir a registro, etc.)
                  // no se ofrece guardar nada: solo tras un login exitoso.
                  child: AutofillGroup(
                    onDisposeAction: AutofillContextAction.cancel,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
                            child: Icon(Icons.business_center_rounded, size: 32, color: colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Bienvenido de vuelta',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inicia sesión para continuar',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email, AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!cargando && _bloqueoRestante == null) login();
                          },
                          validator: Validators.validatePassword,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: cargando ? null : () => Navigator.pushNamed(context, '/forgot-password'),
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (cargando || _bloqueoRestante != null) ? null : login,
                            child:
                                cargando
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                    : Text(
                                      _bloqueoRestante != null
                                          ? 'Bloqueado (${_formatearDuracion(_bloqueoRestante!)})'
                                          : 'Entrar',
                                    ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: cargando ? null : () => Navigator.pushNamed(context, '/register'),
                          child: const Text('¿No tienes cuenta? Regístrate'),
                        ),
                        if (_bloqueoRestante != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Demasiados intentos fallidos. Intenta nuevamente en '
                                '${_formatearDuracion(_bloqueoRestante!)}.',
                                style: TextStyle(color: colorScheme.onErrorContainer),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                error!,
                                style: TextStyle(color: colorScheme.onErrorContainer),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
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
