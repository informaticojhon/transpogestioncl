import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/registro_servicio_screen.dart';
import 'screens/reporte_diario_screen.dart';
import 'screens/reporte_mensual_screen.dart';
import 'screens/historial_screen.dart';
import 'utils/app_theme.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase con configuración para web
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // Más seguro para web
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );
  
  Intl.defaultLocale = 'es_CL'; // Fechas en español chileno
  runApp(const TransporteAppWeb());
}

// Getter global para acceder a Supabase fácilmente
final supabase = Supabase.instance.client;

class TransporteAppWeb extends StatefulWidget {
  const TransporteAppWeb({super.key});

  @override
  State<TransporteAppWeb> createState() => _TransporteAppWebState();
  
  static _TransporteAppWebState? of(BuildContext context) =>
      context.findAncestorStateOfType<_TransporteAppWebState>();
}

class _TransporteAppWebState extends State<TransporteAppWeb> {
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
      title: 'TranspoGestionCL Web',
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
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/registro_servicio': (context) => const RegistroServicioScreen(),
        '/reporte_diario': (context) => const ReporteDiarioScreen(),
        '/reporte_mensual': (context) => const ReporteMensualScreen(),
        '/historial': (context) => const HistorialScreen(),
      },
    );
  }
}
