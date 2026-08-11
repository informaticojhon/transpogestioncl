import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../repositories/servicios_repository.dart';
import '../repositories/auth_repository.dart';
import '../main.dart';
import '../utils/currency_formatter.dart';
import 'trabajadores_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _serviciosRepository = ServiciosRepository();
  final _authRepository = AuthRepository();
  List servicios = [];
  bool cargando = true;
  String? error;
  String? nombreUsuario;

  @override
  void initState() {
    super.initState();
    obtenerServicios();
  }

  Future<void> obtenerServicios({bool mostrarCargando = true}) async {
    final prefs = await SharedPreferences.getInstance();
    nombreUsuario = prefs.getString('nombre');

    if (mostrarCargando) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    try {
      final listaServicios = await _serviciosRepository.obtenerServicios();
      if (mounted) {
        setState(() {
          servicios = listaServicios;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          cargando = false;
          error = 'Error al cargar servicios: ${e.toString()}';
        });
      }
    }
  }

  Future<void> refrescarDatos() async {
    await obtenerServicios(mostrarCargando: false);
  }

  Future<void> cerrarSesion() async {
    // Limpiar estado local primero
    setState(() {
      servicios = [];
      nombreUsuario = null;
      cargando = false;
      error = null;
    });
    
    // Limpiar sesión y caché
    await _authRepository.logout();
    
    if (mounted) {
      // Eliminar TODAS las pantallas del stack y dejar solo la bienvenida
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }

  String formatoCLP(dynamic valor) {
    return CurrencyFormatter.formatCLP(valor);
  }

  String formatoFecha(dynamic fecha) {
    try {
      if (fecha == null) return '';
      final parsed = DateTime.parse(fecha);
      return DateFormat("d 'de' MMMM 'de' y", 'es_CL').format(parsed);
    } catch (e) {
      return fecha.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.business_center, size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TranspoGestionCL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Gestión Empresarial',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar datos',
            onPressed: () => obtenerServicios(mostrarCargando: true),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue.shade700),
                  ),
                  SizedBox(height: 12),
                  Text(
                    nombreUsuario ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Administrador',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard_rounded, color: Colors.blue),
              title: Text('Panel Principal'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: Colors.green),
              title: Text('Registrar Servicio'),
              onTap: () => Navigator.pushNamed(context, '/registro_servicio'),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.orange),
              title: Text('Reporte Diario'),
              onTap: () => Navigator.pushNamed(context, '/reporte_diario'),
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.purple),
              title: Text('Reporte Mensual'),
              onTap: () => Navigator.pushNamed(context, '/reporte_mensual'),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.teal),
              title: Text('Historial'),
              onTap: () => Navigator.pushNamed(context, '/historial'),
            ),
            ListTile(
              leading: Icon(Icons.people, color: Colors.indigo),
              title: Text('Gestión de Personal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrabajadoresListScreen()),
                );
              },
            ),
            Divider(),
            SwitchListTile(
              secondary: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: Colors.amber,
              ),
              title: Text('Modo oscuro'),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                TransporteAppWeb.of(context)?.toggleTheme();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Cerrar sesión'),
              onTap: cerrarSesion,
            ),
          ],
        ),
      ),
      body: cargando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.5 + (value * 0.5),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: const CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: const Text('Cargando servicios...'),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => obtenerServicios(),
                        icon: Icon(Icons.refresh),
                        label: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : servicios.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icono principal con animación
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.0),
                              duration: const Duration(seconds: 2),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.business_center_rounded,
                                  size: 80,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Título
                            Text(
                              'Sistema de Gestión Empresarial',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            
                            Text(
                              'Administra tus servicios de transporte de manera eficiente',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                            
                            // Tarjetas de funcionalidades
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildFeatureCard(
                                  icon: Icons.add_circle_outline,
                                  title: 'Registrar',
                                  description: 'Añade nuevos servicios',
                                  color: Colors.green,
                                  onTap: () => Navigator.pushNamed(context, '/registro_servicio'),
                                ),
                                _buildFeatureCard(
                                  icon: Icons.assessment_rounded,
                                  title: 'Reportes',
                                  description: 'Genera informes en PDF',
                                  color: Colors.orange,
                                  onTap: () => Navigator.pushNamed(context, '/reporte_diario'),
                                ),
                                _buildFeatureCard(
                                  icon: Icons.history_rounded,
                                  title: 'Historial',
                                  description: 'Consulta registros',
                                  color: Colors.teal,
                                  onTap: () => Navigator.pushNamed(context, '/historial'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Botón principal
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/registro_servicio'),
                              icon: Icon(Icons.add_rounded, size: 24),
                              label: Text(
                                'Comenzar a registrar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Header con información del sistema
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark 
                                ? [Colors.blue.shade900, Colors.blue.shade700]
                                : [Colors.blue.shade700, Colors.blue.shade500],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.business_center_rounded,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sistema de Gestión Empresarial',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Administración de Servicios de Transporte',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Estadísticas
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.assignment_turned_in,
                                      value: '${servicios.length}',
                                      label: 'Servicios',
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      icon: Icons.attach_money,
                                      value: formatoCLP(
                                        servicios.fold<int>(
                                          0,
                                          (sum, s) => sum + (s['valor'] as int? ?? 0),
                                        ),
                                      ).replaceAll('\$', '\$'),
                                      label: 'Total',
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Lista de servicios
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: refrescarDatos,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: servicios.length,
                              itemBuilder: (context, index) {
                                final s = servicios[index];
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 300 + (index * 50)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Card(
                                    margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: (s['tipo'] == 'Pasaje' ? Colors.blue : Colors.green)
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          s['tipo'] == 'Pasaje'
                                              ? Icons.confirmation_number_rounded
                                              : Icons.local_shipping_rounded,
                                          color: s['tipo'] == 'Pasaje' ? Colors.blue : Colors.green,
                                        ),
                                      ),
                                      title: Text(
                                        formatoCLP(s['valor'] ?? 0),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${formatoFecha(s['fecha'])}\n'
                                        'Realizado por: ${s['quien'] ?? 'N/A'}\n'
                                        'Empresa: ${s['empresa'] ?? 'N/A'}\n'
                                        'Tipo: ${s['tipo'] ?? 'N/A'}',
                                      ),
                                      trailing: s['isLocal'] == true
                                          ? Tooltip(
                                              message: 'Pendiente de sincronizar',
                                              child: Icon(
                                                Icons.cloud_upload_outlined,
                                                color: Colors.orange,
                                              ),
                                            )
                                          : null,
                                      isThreeLine: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: servicios.isEmpty ? null : FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/registro_servicio'),
        child: const Icon(Icons.add),
        tooltip: 'Registrar nuevo servicio',
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
