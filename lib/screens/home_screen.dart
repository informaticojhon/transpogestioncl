import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../repositories/servicios_repository.dart';
import '../repositories/auth_repository.dart';
import '../main.dart';
import '../utils/app_logo.dart';
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
  String? nombreEmpresa;
  bool esAdmin = false;
  WeatherInfo? _clima;
  List<({DateTime mes, int total})> _ingresosPorMes = [];

  @override
  void initState() {
    super.initState();
    obtenerServicios();
    _cargarClima();
    _cargarIngresosPorMes();
  }

  Future<void> _cargarClima() async {
    final clima = await _weatherService.getClimaDelDia();
    if (mounted) setState(() => _clima = clima);
  }

  Future<void> _cargarIngresosPorMes() async {
    try {
      final ingresos = await _serviciosRepository.obtenerIngresosPorMes(meses: 6);
      if (mounted) setState(() => _ingresosPorMes = ingresos);
    } catch (_) {
      // El gráfico simplemente no se muestra si esto falla; no es crítico
      // para el resto del panel principal.
    }
  }

  static const _timeoutRed = Duration(seconds: 15);

  Future<void> obtenerServicios({bool mostrarCargando = true}) async {
    if (mostrarCargando) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    try {
      nombreUsuario = await _authRepository.getNombreUsuario().timeout(_timeoutRed);
      esAdmin = (await _authRepository.getRolUsuario().timeout(_timeoutRed)) == 'admin';
      final empresa = await _authRepository.getMiEmpresa().timeout(_timeoutRed);
      nombreEmpresa = empresa?.nombre;

      final resultados = await Future.wait([
        _serviciosRepository.obtenerServiciosRecientes(limite: 20),
        _serviciosRepository.obtenerEstadisticas(),
      ]).timeout(_timeoutRed);
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
    await Future.wait([obtenerServicios(mostrarCargando: false), _cargarIngresosPorMes()]);
  }

  /// Abre otra sección y, al volver, recarga el panel sin mostrar el
  /// indicador de carga: lo que se registró, editó o eliminó allá tiene
  /// que verse acá sin recargar la página.
  Future<void> _abrir(String ruta) async {
    await Navigator.pushNamed(context, ruta);
    if (mounted) refrescarDatos();
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
            () => _abrir('/registro_servicio')),
        _NavEntry(Icons.calendar_today, 'Reporte Diario',
            () => _abrir('/reporte_diario')),
        _NavEntry(Icons.bar_chart, 'Reporte Mensual',
            () => _abrir('/reporte_mensual')),
        _NavEntry(Icons.history, 'Historial',
            () => _abrir('/historial')),
        if (esAdmin)
          _NavEntry(Icons.people, 'Gestión de Personal',
              () => _abrir('/trabajadores')),
        if (esAdmin)
          _NavEntry(Icons.event_note, 'Turnos',
              () => _abrir('/turnos')),
        if (esAdmin)
          _NavEntry(Icons.payments_outlined, 'Remuneraciones',
              () => _abrir('/remuneraciones')),
        if (esAdmin)
          _NavEntry(Icons.fact_check_outlined, 'Auditoría',
              () => _abrir('/auditoria')),
        if (esAdmin)
          _NavEntry(Icons.inventory_2, 'Gestión de Materiales',
              () => _abrir('/materiales')),
        if (esAdmin)
          _NavEntry(Icons.groups_outlined, 'Gestionar mi equipo',
              () => _abrir('/equipo')),
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
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'TranspoGestión '),
                    TextSpan(text: 'CL', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700)),
                  ]),
                  style: const TextStyle(fontSize: 17),
                ),
                const Text(
                  'Gestión de transporte',
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
              onPressed: () => _abrir('/registro_servicio'),
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
          Flexible(
            child: Text(
              '${clima.temperature.round()}°C · ${clima.description}'
              '${clima.ciudad != null ? ' · ${clima.ciudad}' : ''}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary),
            ),
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
            const AppLogo(size: 112),
            const SizedBox(height: 28),
            Text(
              _saludoNombre,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (nombreEmpresa != null) ...[
              const SizedBox(height: 4),
              Text(
                nombreEmpresa!,
                style: TextStyle(fontSize: 13, color: colorScheme.primary, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '¿Qué deseas hacer hoy?',
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildWeatherChip(context),
            const SizedBox(height: 36),
            LayoutBuilder(
              builder: (context, constraints) {
                // En celular no caben dos tarjetas de 170 por fila y
                // quedaban una bajo otra con mucho espacio vacío a los
                // lados; ahí se muestran como filas a todo el ancho.
                final compacto = constraints.maxWidth < 560;
                final tarjetas = [
                  _buildFeatureCard(
                    icon: Icons.add_circle_outline,
                    title: 'Registrar',
                    description: 'Añade nuevos servicios',
                    compacto: compacto,
                    onTap: () => _abrir('/registro_servicio'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.assessment_rounded,
                    title: 'Reportes',
                    description: 'Genera informes en PDF',
                    compacto: compacto,
                    onTap: () => _abrir('/reporte_diario'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.history_rounded,
                    title: 'Historial',
                    description: 'Consulta registros',
                    compacto: compacto,
                    onTap: () => _abrir('/historial'),
                  ),
                ];

                if (compacto) {
                  return Column(
                    children: [
                      for (final tarjeta in tarjetas)
                        Padding(padding: const EdgeInsets.only(bottom: 12), child: tarjeta),
                    ],
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: tarjetas,
                );
              },
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: () => _abrir('/registro_servicio'),
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
    // En celular el saludo y el clima no caben lado a lado (el saludo
    // quedaba en una columna angosta, una sílaba por línea): ahí el
    // clima va debajo del saludo.
    final compacto = MediaQuery.sizeOf(context).width < 600;

    final saludo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_saludoNombre, style: Theme.of(context).textTheme.headlineSmall),
        if (nombreEmpresa != null) ...[
          const SizedBox(height: 2),
          Text(
            nombreEmpresa!,
            style: TextStyle(fontSize: 13, color: colorScheme.primary, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '¿Qué deseas hacer hoy?',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );

    // Todo el panel (encabezado, totales, gráfico y lista) va en un solo
    // scroll. Antes solo la lista se desplazaba y lo de arriba quedaba
    // fijo, así que en una pantalla de celular el gráfico se cortaba y la
    // lista casi no tenía espacio.
    final encabezado = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compacto) ...[
          saludo,
          if (_clima != null) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: _buildWeatherChip(context)),
          ],
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: saludo),
              const SizedBox(width: 12),
              _buildWeatherChip(context),
            ],
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.assignment_turned_in_rounded,
                value: '$totalServicios',
                label: 'Servicios registrados',
                color: colorScheme.primary,
                compacto: compacto,
              ),
            ),
            SizedBox(width: compacto ? 12 : 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money_rounded,
                value: formatoCLP(totalValor),
                label: 'Total acumulado',
                color: colorScheme.tertiary,
                compacto: compacto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_ingresosPorMes.isNotEmpty) ...[
          _buildIngresosChart(context),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Text(
              'Servicios recientes',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _abrir('/historial'),
              child: const Text('Ver historial completo'),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: refrescarDatos,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  itemCount: servicios.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return encabezado;
                    final s = servicios[index - 1];
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

  Widget _buildIngresosChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxTotal = _ingresosPorMes.map((e) => e.total).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxTotal == 0 ? 1000.0 : maxTotal * 1.2;

    int? cambioPorcentual;
    if (_ingresosPorMes.length >= 2) {
      final actual = _ingresosPorMes.last.total;
      final anterior = _ingresosPorMes[_ingresosPorMes.length - 2].total;
      if (anterior > 0) {
        cambioPorcentual = (((actual - anterior) / anterior) * 100).round();
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Ingresos por mes', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (cambioPorcentual != null) _buildComparativaChip(cambioPorcentual),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _ingresosPorMes.length) {
                            return const SizedBox.shrink();
                          }
                          final mes = _ingresosPorMes[index].mes;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('MMM', 'es_CL').format(mes),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colorScheme.primary,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final mes = _ingresosPorMes[group.x.toInt()].mes;
                        final label = DateFormat("MMMM 'de' y", 'es_CL').format(mes);
                        return BarTooltipItem(
                          '$label\n${formatoCLP(rod.toY.round())}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < _ingresosPorMes.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: _ingresosPorMes[i].total.toDouble(),
                            color: colorScheme.primary,
                            width: 22,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                  ],
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
    bool compacto = false,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compacto ? 12 : 18),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(compacto ? 8 : 12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: compacto ? 18 : 22),
            ),
            SizedBox(width: compacto ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Los montos grandes ("$1.250.000") se achican para caber
                  // completos en vez de cortarse con "…".
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
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

  Widget _buildComparativaChip(int cambioPorcentual) {
    final subiendo = cambioPorcentual >= 0;
    final color = subiendo ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(subiendo ? Icons.trending_up : Icons.trending_down, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            '${subiendo ? '+' : ''}$cambioPorcentual% vs mes anterior',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool compacto = false,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final icono = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.14), shape: BoxShape.circle),
          child: Icon(icon, size: compacto ? 26 : 30, color: colorScheme.primary),
        );
        final titulo = Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.primary));
        final descripcion = Text(
          description,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          textAlign: compacto ? TextAlign.start : TextAlign.center,
        );

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: compacto ? double.infinity : 170,
            padding: compacto ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14) : const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
            ),
            child: compacto
                ? Row(
                    children: [
                      icono,
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [titulo, const SizedBox(height: 2), descripcion],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colorScheme.primary.withValues(alpha: 0.6)),
                    ],
                  )
                : Column(
                    children: [icono, const SizedBox(height: 12), titulo, const SizedBox(height: 4), descripcion],
                  ),
          ),
        );
      },
    );
  }
}
