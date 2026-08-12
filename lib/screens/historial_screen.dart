import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../repositories/servicios_repository.dart';
import 'registro_servicio_screen.dart';
import '../utils/currency_formatter.dart';
import '../utils/csv_exporter.dart';

const int _kPorPagina = 30;

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _serviciosRepository = ServiciosRepository();
  final _buscarController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<dynamic> _servicios = [];
  bool _cargando = true;
  bool _cargandoMas = false;
  bool _hayMas = true;
  bool _exportando = false;
  String _busqueda = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarServicios(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hayMas || _cargandoMas || _cargando) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _cargarMas();
    }
  }

  Future<void> _cargarServicios({required bool reset}) async {
    if (reset) {
      setState(() {
        _cargando = true;
        _error = null;
        _servicios = [];
        _hayMas = true;
      });
    }

    try {
      final servicios = await _serviciosRepository.buscarServiciosPaginado(
        offset: 0,
        limit: _kPorPagina,
        busqueda: _busqueda,
      );
      if (mounted) {
        setState(() {
          _servicios = servicios;
          _hayMas = servicios.length == _kPorPagina;
          _cargando = false;
        });
      }
    } on TokenExpiredException {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar servicios: ${e.toString()}';
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error de conexión. Verifica tu internet.';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cargarMas() async {
    setState(() => _cargandoMas = true);
    try {
      final servicios = await _serviciosRepository.buscarServiciosPaginado(
        offset: _servicios.length,
        limit: _kPorPagina,
        busqueda: _busqueda,
      );
      if (mounted) {
        setState(() {
          _servicios.addAll(servicios);
          _hayMas = servicios.length == _kPorPagina;
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

  void _onBuscarChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _busqueda = value;
      _cargarServicios(reset: true);
    });
  }

  Future<void> _eliminarServicio(int id) async {
    try {
      await _serviciosRepository.eliminarServicio(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio eliminado correctamente')),
        );
      }
      _cargarServicios(reset: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Future<void> _eliminarTodoElHistorial() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar TODO el historial?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _serviciosRepository.eliminarTodosLosServicios();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Historial eliminado completamente')),
          );
          _cargarServicios(reset: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar historial: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportarCsv() async {
    setState(() => _exportando = true);
    try {
      final servicios = await _serviciosRepository.obtenerTodosParaExportar(
        busqueda: _busqueda.isEmpty ? null : _busqueda,
      );

      if (servicios.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay servicios para exportar')),
          );
        }
        return;
      }

      final filas = <List<dynamic>>[
        ['Fecha', 'Empresa', 'Quién', 'Tipo', 'Valor'],
        for (final s in servicios)
          [s['fecha'], s['empresa'] ?? '', s['quien'] ?? '', s['tipo'] ?? '', s['valor'] ?? 0],
      ];

      final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
      exportarCsv('historial_servicios_$hoy.csv', filas);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${servicios.length} servicios exportados')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _mostrarDetalle(dynamic servicio) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final fecha = DateTime.parse(servicio['fecha']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle del Servicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${servicio['tipo'] ?? 'N/A'}'),
            Text('Empresa: ${servicio['empresa'] ?? 'N/A'}'),
            Text('Realizado por: ${servicio['quien'] ?? 'N/A'}'),
            Text('Monto: ${CurrencyFormatter.formatCLP(servicio['valor'])}'),
            Text('Fecha: ${formatoFecha.format(fecha)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Servicios'),
        actions: [
          if (_servicios.isNotEmpty)
            IconButton(
              icon: _exportando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined),
              tooltip: 'Exportar a CSV',
              onPressed: _exportando ? null : _exportarCsv,
            ),
          if (_servicios.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Eliminar todo el historial',
              onPressed: _eliminarTodoElHistorial,
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _cargarServicios(reset: true),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _buscarController,
                            decoration: const InputDecoration(
                              labelText: 'Buscar por Empresa, Persona o Tipo',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: _onBuscarChanged,
                          ),
                        ),
                        Expanded(
                          child: _servicios.isEmpty
                              ? const Center(
                                  child: Text('No hay servicios registrados'),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _servicios.length + (_hayMas ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _servicios.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 20),
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    }

                                    final servicio = _servicios[index];
                                    final servicioId = servicio['id'];

                                    return Dismissible(
                                      key: Key(servicioId.toString()),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) async {
                                        return await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirmar eliminación'),
                                            content: Text(
                                              '¿Eliminar el servicio de ${servicio['empresa']}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onDismissed: (direction) {
                                        _eliminarServicio(servicioId);
                                      },
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      child: Card(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: ListTile(
                                          title: Text(servicio['empresa'] ?? 'Sin empresa'),
                                          subtitle: Text(
                                            '${servicio['quien'] ?? 'N/A'} - ${servicio['tipo'] ?? 'N/A'}',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                CurrencyFormatter.formatCLP(servicio['valor']),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () async {
                                                  final recargar = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => RegistroServicioScreen(
                                                        servicioEditar: servicio,
                                                      ),
                                                    ),
                                                  );
                                                  if (recargar == true) {
                                                    _cargarServicios(reset: true);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          onTap: () => _mostrarDetalle(servicio),
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
