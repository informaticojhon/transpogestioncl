import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../utils/validators.dart';

/// Recuperación de contraseña en dos pasos: primero se pide el correo y
/// se envía un código de 6 dígitos (nunca se informa si el correo existe
/// o no), y luego se pide ese código para verificarlo antes de dejar
/// cambiar la contraseña en la pantalla siguiente.
///
/// Se usa un código que el usuario escribe a mano en vez de un link que
/// se abre solo, porque los escáneres de seguridad de correo (Gmail y
/// otros) suelen "pre-visitar" los links automáticamente para revisarlos,
/// lo que gasta el token antes de que la persona alcance a hacer clic.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyCodigo = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _enviando = false;
  bool _codigoEnviado = false;
  bool _verificando = false;
  String? _errorCodigo;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!_formKeyEmail.currentState!.validate()) return;

    setState(() => _enviando = true);
    await _authRepository.enviarRecuperacionPassword(_emailController.text.trim());
    if (mounted) {
      setState(() {
        _enviando = false;
        _codigoEnviado = true;
      });
    }
  }

  Future<void> _verificarCodigo() async {
    if (!_formKeyCodigo.currentState!.validate()) return;

    setState(() {
      _verificando = true;
      _errorCodigo = null;
    });

    try {
      await _authRepository.verificarCodigoRecuperacion(
        _emailController.text.trim(),
        _codigoController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/reset-password');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorCodigo = 'Código inválido o vencido. Verifica que lo hayas copiado bien, o pide uno nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _verificando = false);
      }
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
                child: _codigoEnviado ? _buildPasoCodigo(colorScheme) : _buildPasoEmail(colorScheme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasoEmail(ColorScheme colorScheme) {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
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
            'Ingresa tu correo y te enviaremos un código para restablecerla.',
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
              onPressed: _enviando ? null : _enviarCodigo,
              child: _enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar código'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _enviando ? null : () => Navigator.pop(context),
            child: const Text('Volver a iniciar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoCodigo(ColorScheme colorScheme) {
    return Form(
      key: _formKeyCodigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.mark_email_read_outlined, size: 32, color: colorScheme.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Revisa tu correo',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Si ${_emailController.text.trim()} está registrado, te llegó un código de 6 dígitos. Escríbelo abajo.',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _codigoController,
            decoration: const InputDecoration(
              labelText: 'Código de 6 dígitos',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 8),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el código' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _verificando ? null : _verificarCodigo,
              child: _verificando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Verificar código'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _verificando ? null : () => setState(() => _codigoEnviado = false),
            child: const Text('Usar otro correo o pedir un código nuevo'),
          ),
          if (_errorCodigo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorCodigo!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
