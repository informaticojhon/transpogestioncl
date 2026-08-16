import 'package:flutter/material.dart';
import '../main.dart';

/// Envuelve una pantalla protegida: si no hay sesión activa (por ejemplo,
/// alguien navega directo a la URL de la pantalla sin haber iniciado
/// sesión), redirige a /welcome en vez de mostrar la pantalla.
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentSession == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child;
  }
}
