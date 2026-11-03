import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../utils/app_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    // Asegurar que no haya sesión activa al iniciar la app
    _authRepository.logout();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.75)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sobre el fondo índigo, una sombra separa el logo del degradado.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const AppLogo(size: 120),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'TranspoGestión CL',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestión de transporte, personal e inventario en un solo lugar',
                    style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ingresar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
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
