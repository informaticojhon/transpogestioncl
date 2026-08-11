import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../utils/validators.dart';

enum _ModoRegistro { crearEmpresa, unirseEmpresa }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nombreEmpresaController = TextEditingController();
  final codigoController = TextEditingController();
  final _authRepository = AuthRepository();
  bool cargando = false;
  String? error;
  String? codigoGenerado;
  _ModoRegistro modo = _ModoRegistro.crearEmpresa;

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      cargando = true;
      error = null;
      codigoGenerado = null;
    });

    try {
      final codigo = await _authRepository.register(
        nombre: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        nombreEmpresa: modo == _ModoRegistro.crearEmpresa
            ? nombreEmpresaController.text.trim()
            : null,
        codigoInvitacion: modo == _ModoRegistro.unirseEmpresa
            ? codigoController.text.trim()
            : null,
      );

      if (codigo != null) {
        setState(() => codigoGenerado = codigo);
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (codigoGenerado != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crear cuenta')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 56, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        '¡Empresa creada!',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Comparte este código con tu equipo para que se unan a tu empresa:',
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          codigoGenerado!,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'También puedes verlo después en "Gestionar mi equipo"',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Continuar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crea tu cuenta',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crea la empresa de tu negocio o únete a una existente',
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SegmentedButton<_ModoRegistro>(
                        segments: const [
                          ButtonSegment(
                            value: _ModoRegistro.crearEmpresa,
                            label: Text('Crear empresa'),
                            icon: Icon(Icons.add_business_outlined),
                          ),
                          ButtonSegment(
                            value: _ModoRegistro.unirseEmpresa,
                            label: Text('Unirme'),
                            icon: Icon(Icons.group_add_outlined),
                          ),
                        ],
                        selected: {modo},
                        onSelectionChanged: (nuevo) => setState(() => modo = nuevo.first),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
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
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 16),
                      if (modo == _ModoRegistro.crearEmpresa)
                        TextFormField(
                          controller: nombreEmpresaController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de tu empresa',
                            hintText: 'Ej: Transportes Pérez',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (value) => Validators.validateRequired(value, 'El nombre de la empresa'),
                        )
                      else
                        TextFormField(
                          controller: codigoController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Código de invitación',
                            hintText: 'Pídeselo al administrador de tu empresa',
                            prefixIcon: Icon(Icons.key_outlined),
                          ),
                          validator: (value) => Validators.validateRequired(value, 'El código de invitación'),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: cargando ? null : registrar,
                          child: cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Registrarse'),
                        ),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
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
    );
  }
}
