import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/servicios_repository.dart';
import '../repositories/auth_repository.dart';
import '../main.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _NavEntry {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _NavEntry(this.icon, this.label, [this.onTap]);
}

class _HomeScreenState extends State<HomeScreen> {
  final _serviciosRepository = ServiciosRepository();
  final _authRepository = AuthRepository();
  final _weatherService = WeatherService();
  List servicios = [];
  int totalServicios = 0;
  int totalValor = 0;
  bool cargando = true;
  String? error;
  String? nombreUsuario;
  bool esAdmin = false;
  WeatherInfo? _clima;

  @override
  void initState() {
    super.initState();
    obtenerServicios();
    _cargarClima();
  }

  Future<void> _cargarClima() async {
    final clima = await _weatherService.getClimaDelDia();
    if (mounted) setState(() => _clima = clima);
  }

  Future<void> obtenerServicios({bool mostrarCargando = true}) async {
    nombreUsuario = await _authRepository.getNombreUsuario();
    esAdmin = (await _authRepository.getRolUsuario()) == 'admin';

    if (mostrarCargando) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    try {
      final resultados = await Future.wait([
        _serviciosRepository.obtenerServiciosRecientes(limite: 20),
        _serviciosRepository.obtenerEstadisticas(),
      ]);
      final listaServicios = resultados[0] as List;
      final estadisticas = resultados[1] as Map<String, int>;
      if (mounted) {
        setState(() {
          servicios = listaServicios;
          totalServicios = estadisticas['total_servicios'] ?? 0;
          totalValor = estadisticas['total_valor'] ?? 0;
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
    setState(() {
      servicios = [];
      totalServicios = 0;
      totalValor = 0;
      nombreUsuario = null;
      cargando = false;
      error = null;
    });

    await _authRepository.logout();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }

  String formatoCLP(dynamic valor) => CurrencyFormatter.formatCLP(valor);

  String formatoFecha(dynamic fecha) {
    try {
      if (fecha == null) return '';
      final parsed = DateTime.parse(fecha);
      return DateFormat("d 'de' MMMM 'de' y", 'es_CL').format(parsed);
    } catch (e) {
      return fecha.toString();
    }
  }

  List<_NavEntry> _navEntries(BuildContext context) => [
        _NavEntry(Icons.dashboard_rounded, 'Panel Principal'),
        _NavEntry(Icons.add_circle_outline, 'Registrar Servicio',
            () => Navigator.pushNamed(context, '/registro_servicio')),
        _NavEntry(Icons.calendar_today, 'Reporte Diario',
            () => Navigator.pushNamed(context, '/reporte_diario')),
        _NavEntry(Icons.bar_chart, 'Reporte Mensual',
            () => Navigator.pushNamed(context, '/reporte_mensual')),
        _NavEntry(Icons.history, 'Historial',
            () => Navigator.pushNamed(context, '/historial')),
        if (esAdmin)
          _NavEntry(Icons.people, 'Gestión de Personal',
              () => Navigator.pushNamed(context, '/trabajadores')),
        if (esAdmin)
          _NavEntry(Icons.inventory_2, 'Gestión de Materiales',
              () => Navigator.pushNamed(context, '/materiales')),
        _NavEntry(Icons.groups_outlined, 'Gestionar mi equipo',
            () => Navigator.pushNamed(context, '/equipo')),
      ];

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !desktop,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_center_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TranspoGestionCL', style: TextStyle(fontSize: 17)),
                Text(
                  'Gestión Empresarial',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
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
          const SizedBox(width: 8),
        ],
      ),
      drawer: desktop ? null : _buildDrawer(context),
      body: Row(
        children: [
          if (desktop) _buildNavigationRail(context),
          if (desktop) const VerticalDivider(width: 1),
          Expanded(child: _buildBody(context)),
        ],
      ),
      floatingActionButton: servicios.isEmpty || desktop
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/registro_servicio'),
              tooltip: 'Registrar nuevo servicio',
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    final entries = _navEntries(context);
    return NavigationRail(
      selectedIndex: 0,
      labelType: NavigationRailLabelType.all,
      minWidth: 84,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  tooltip: 'Cambiar tema',
                  onPressed: () => TransporteApp.of(context)?.toggleTheme(),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: 'Cerrar sesión',
                  onPressed: cerrarSesion,
                ),
              ],
            ),
          ),
        ),
      ),
      destinations: entries
          .map(
            (e) => NavigationRailDestination(
              icon: Icon(e.icon),
              label: Text(e.label, textAlign: TextAlign.center),
            ),
          )
          .toList(),
      onDestinationSelected: (index) => entries[index].onTap?.call(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final entries = _navEntries(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 36, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  nombreUsuario ?? 'Usuario',
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const Text('Administrador', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          for (final entry in entries)
            ListTile(
              leading: Icon(entry.icon),
              title: Text(entry.label),
              onTap: () {
                Navigator.pop(context);
                entry.onTap?.call();
              },
            ),
          const Divider(),
          SwitchListTile(
            secondary: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text('Modo oscuro'),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (value) => TransporteApp.of(context)?.toggleTheme(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión'),
            onTap: cerrarSesion,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => obtenerServicios(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (servicios.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildDashboard(context);
  }

  String get _saludoNombre => nombreUsuario != null ? '¡Bienvenido, $nombreUsuario!' : '¡Bienvenido!';

  Widget _buildWeatherChip(BuildContext context) {
    final clima = _clima;
    if (clima == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(clima.icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '${clima.temperature.round()}°C · ${clima.description}'
            '${clima.ciudad != null ? ' · ${clima.ciudad}' : ''}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: ResponsivePage(
        maxWidth: 760,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.business_center_rounded, size: 64, color: colorScheme.primary),
            ),
            const SizedBox(height: 28),
            Text(
              _saludoNombre,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '¿Qué deseas hacer hoy?',
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildWeatherChip(context),
            const SizedBox(height: 36),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureCard(
                  icon: Icons.add_circle_outline,
                  title: 'Registrar',
                  description: 'Añade nuevos servicios',
                  onTap: () => Navigator.pushNamed(context, '/registro_servicio'),
                ),
                _buildFeatureCard(
                  icon: Icons.assessment_rounded,
                  title: 'Reportes',
                  description: 'Genera informes en PDF',
                  onTap: () => Navigator.pushNamed(context, '/reporte_diario'),
                ),
                _buildFeatureCard(
                  icon: Icons.history_rounded,
                  title: 'Historial',
                  description: 'Consulta registros',
                  onTap: () => Navigator.pushNamed(context, '/historial'),
                ),
              ],
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/registro_servicio'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Comenzar a registrar'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_saludoNombre, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          '¿Qué deseas hacer hoy?',
                          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildWeatherChip(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.assignment_turned_in_rounded,
                      value: '$totalServicios',
                      label: 'Servicios registrados',
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.attach_money_rounded,
                      value: formatoCLP(totalValor),
                      label: 'Total acumulado',
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Servicios recientes',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/historial'),
                    child: const Text('Ver historial completo'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refrescarDatos,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: servicios.length,
                  itemBuilder: (context, index) {
                    final s = servicios[index];
                    final esPasaje = s['tipo'] == 'Pasaje';
                    final tipoColor = esPasaje ? colorScheme.primary : colorScheme.tertiary;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tipoColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            esPasaje ? Icons.confirmation_number_rounded : Icons.local_shipping_rounded,
                            color: tipoColor,
                          ),
                        ),
                        title: Text(
                          formatoCLP(s['valor'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                                child: Icon(Icons.cloud_upload_outlined, color: Theme.of(context).colorScheme.tertiary),
                              )
                            : null,
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 170,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: Icon(icon, size: 30, color: colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
