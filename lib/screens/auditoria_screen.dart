import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/registro_auditoria.dart';
import '../repositories/auth_repository.dart';
import '../utils/currency_formatter.dart';

const int _kPorPagina = 40;

const Map<String, String> _nombresTabla = {
  'servicios': 'Servicio',
  'trabajadores': 'Trabajador',
  'turnos': 'Turno',
  'remuneraciones': 'Remuneración',
  'materiales': 'Material',
  'movimientos_material': 'Movimiento de material',
};

/// Historial de auditoría: quién creó, editó o eliminó qué en la empresa,
/// y cuándo. Se alimenta de la tabla "auditoria", que se llena sola vía
/// triggers en la base de datos cada vez que cambia algo en las tablas
/// sensibles (no depende de que la app recuerde registrar el evento).
class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final _authRepository = AuthRepository();
  final _scrollController = ScrollController();
  final _formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');

  bool _esAdmin = true;
  bool _cargando = true;
  bool _cargandoMas = false;
  bool _hayMas = true;
  String? _tablaFiltro;
  List<RegistroAuditoria> _registros = [];
  Map<String, String> _nombresPorUserId = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _verificarAccesoYCargar();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _verificarAccesoYCargar() async {
    final rol = await _authRepository.getRolUsuario();
    if (rol != 'admin') {
      setState(() {
        _esAdmin = false;
        _cargando = false;
      });
      return;
    }
    await _cargarMiembros();
    await _cargarRegistros(reset: true);
  }

  Future<void> _cargarMiembros() async {
    try {
      final miembros = await _authRepository.getMiembrosEquipo();
      setState(() => _nombresPorUserId = {for (final m in miembros) m.id: m.nombre});
    } catch (_) {
      // Si falla, se muestra el id crudo en vez del nombre; no bloquea la pantalla.
    }
  }

  void _onScroll() {
    if (!_hayMas || _cargandoMas || _cargando) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _cargarMas();
    }
  }

  Future<void> _cargarRegistros({required bool reset}) async {
    if (reset) {
      setState(() {
        _cargando = true;
        _registros = [];
        _hayMas = true;
      });
    }
    try {
      final registros = await _authRepository.getAuditoria(
        offset: 0,
        limit: _kPorPagina,
        tabla: _tablaFiltro,
      );
      if (mounted) {
        setState(() {
          _registros = registros;
          _hayMas = registros.length == _kPorPagina;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar auditoría: $e')),
        );
      }
    }
  }

  Future<void> _cargarMas() async {
    setState(() => _cargandoMas = true);
    try {
      final registros = await _authRepository.getAuditoria(
        offset: _registros.length,
        limit: _kPorPagina,
        tabla: _tablaFiltro,
      );
      if (mounted) {
        setState(() {
          _registros.addAll(registros);
          _hayMas = registros.length == _kPorPagina;
          _cargandoMas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoMas = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar más: $e')),
        );
      }
    }
  }

  void _cambiarFiltro(String? tabla) {
    setState(() => _tablaFiltro = tabla);
    _cargarRegistros(reset: true);
  }

  ({IconData icon, Color color, String label}) _estiloAccion(String accion) {
    switch (accion) {
      case 'insert':
        return (icon: Icons.add_circle_outline, color: Colors.green, label: 'Creó');
      case 'update':
        return (icon: Icons.edit_outlined, color: Colors.blue, label: 'Editó');
      case 'delete':
        return (icon: Icons.delete_outline, color: Colors.red, label: 'Eliminó');
      default:
        return (icon: Icons.help_outline, color: Colors.grey, label: accion);
    }
  }

  String _resumenDatos(String tabla, Map<String, dynamic>? datos) {
    if (datos == null) return '';
    switch (tabla) {
      case 'servicios':
        final valor = datos['valor'];
        return [
          if (datos['quien'] != null) datos['quien'],
          if (datos['empresa'] != null) datos['empresa'],
          if (valor != null) CurrencyFormatter.formatCLP(valor),
        ].join(' · ');
      case 'trabajadores':
        return [datos['nombre'], datos['apellido']].where((v) => v != null).join(' ');
      case 'turnos':
        return [
          if (datos['fecha'] != null) datos['fecha'],
          if (datos['tipo_turno'] != null) (datos['tipo_turno'] as String).toUpperCase(),
        ].join(' · ');
      case 'remuneraciones':
        final monto = datos['monto'];
        return [
          if (monto != null) CurrencyFormatter.formatCLP(monto),
          if (datos['periodo'] != null) datos['periodo'],
        ].join(' · ');
      case 'materiales':
        return datos['nombre']?.toString() ?? '';
      case 'movimientos_material':
        return [
          if (datos['tipo'] != null) (datos['tipo'] as String).toUpperCase(),
          if (datos['cantidad'] != null) datos['cantidad'].toString(),
        ].join(' · ');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auditoría')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Solo los administradores de la empresa pueden acceder a esta sección',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Auditoría')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _tablaFiltro == null,
                        onSelected: (_) => _cambiarFiltro(null),
                      ),
                      for (final entry in _nombresTabla.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _tablaFiltro == entry.key,
                          onSelected: (_) => _cambiarFiltro(entry.key),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _registros.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No hay actividad registrada todavía'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _registros.length + (_hayMas ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _registros.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final registro = _registros[index];
                              final estilo = _estiloAccion(registro.accion);
                              final nombreActor = _nombresPorUserId[registro.userId] ?? 'Usuario eliminado';
                              final nombreTabla = _nombresTabla[registro.tabla] ?? registro.tabla;
                              final resumen = _resumenDatos(registro.tabla, registro.datos);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: estilo.color.withValues(alpha: 0.15),
                                    child: Icon(estilo.icon, color: estilo.color),
                                  ),
                                  title: Text('$nombreActor ${estilo.label.toLowerCase()} $nombreTabla'),
                                  subtitle: Text(
                                    resumen.isEmpty
                                        ? _formatoFechaHora.format(registro.createdAt)
                                        : '$resumen · ${_formatoFechaHora.format(registro.createdAt)}',
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
