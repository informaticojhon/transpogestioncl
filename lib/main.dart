import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:transporte_app/screens/login_screen.dart';
import 'package:transporte_app/screens/register_screen.dart';
import 'package:transporte_app/screens/welcome_screen.dart';
import 'package:transporte_app/screens/home_screen.dart';
import 'package:transporte_app/screens/registro_servicio_screen.dart';
import 'package:transporte_app/screens/reporte_diario_screen.dart';
import 'package:transporte_app/screens/reporte_mensual_screen.dart';
import 'package:transporte_app/screens/historial_screen.dart';
import 'package:transporte_app/screens/trabajadores_list_screen.dart';
import 'package:transporte_app/screens/materiales_list_screen.dart';
import 'package:transporte_app/screens/equipo_screen.dart';
import 'package:transporte_app/utils/app_theme.dart';
import 'package:transporte_app/utils/auth_guard.dart';
import 'package:transporte_app/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  Intl.defaultLocale = 'es_CL'; // Fechas en español chileno
  runApp(const TransporteApp());
}

// Getter global para acceder a Supabase fácilmente
final supabase = Supabase.instance.client;

class TransporteApp extends StatefulWidget {
  const TransporteApp({super.key});

  @override
  State<TransporteApp> createState() => _TransporteAppState();
  
  static _TransporteAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_TransporteAppState>();
}

class _TransporteAppState extends State<TransporteApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = _themeMode == ThemeMode.dark;
    await prefs.setBool('isDarkMode', !isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TranspoGestionCL', // Título actualizado
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CL'),
      ],
      locale: const Locale('es', 'CL'),
      initialRoute: '/welcome', // Comienza en la pantalla de bienvenida
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const AuthGuard(child: HomeScreen()),
        '/registro_servicio': (context) => const AuthGuard(child: RegistroServicioScreen()),
        '/reporte_diario': (context) => const AuthGuard(child: ReporteDiarioScreen()),
        '/reporte_mensual': (context) => const AuthGuard(child: ReporteMensualScreen()),
        '/historial': (context) => const AuthGuard(child: HistorialScreen()),
        '/trabajadores': (context) => const AuthGuard(child: TrabajadoresListScreen()),
        '/materiales': (context) => const AuthGuard(child: MaterialesListScreen()),
        '/equipo': (context) => const AuthGuard(child: EquipoScreen()),
      },
    );
  }
}

