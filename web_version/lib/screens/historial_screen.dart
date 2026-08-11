import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../repositories/servicios_repository.dart';
import 'registro_servicio_screen.dart';
import '../utils/currency_formatter.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key}); // <- Ahora sí tiene el constructor const

  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _serviciosRepository = ServiciosRepository();
  List<dynamic> _servicios = [];
  List<dynamic> _serviciosFiltrados = [];
  final TextEditingController _buscarController = TextEditingController();
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    
    try {
      final servicios = await _serviciosRepository.obtenerServicios(forceRefresh: true);
      if (mounted) {
        setState(() {
          _servicios = servicios;
          _serviciosFiltrados = servicios;
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

  Future<void> _eliminarServicio(int id) async {
    try {
      await _serviciosRepository.eliminarServicio(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio eliminado correctamente')),
      );
      _cargarServicios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
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
          _cargarServicios();
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

  void _filtrarServicios(String query) {
    final serviciosFiltrados = _servicios.where((servicio) {
      final empresaLower = (servicio['empresa'] ?? '').toLowerCase();
      final quienLower = (servicio['quien'] ?? '').toLowerCase();
      final tipoLower = (servicio['tipo'] ?? '').toLowerCase();
      final queryLower = query.toLowerCase();
      return empresaLower.contains(queryLower) || 
             quienLower.contains(queryLower) ||
             tipoLower.contains(queryLower);
    }).toList();

    setState(() {
      _serviciosFiltrados = serviciosFiltrados;
    });
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
                        onPressed: () {
                          setState(() {
                            _cargando = true;
                            _error = null;
                          });
                          _cargarServicios();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _buscarController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar por Empresa, Persona o Tipo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _filtrarServicios,
                      ),
                    ),
                    Expanded(
                      child: _serviciosFiltrados.isEmpty
                          ? const Center(
                              child: Text('No hay servicios registrados'),
                            )
                          : ListView.builder(
                              itemCount: _serviciosFiltrados.length,
                              itemBuilder: (context, index) {
                                final servicio = _serviciosFiltrados[index];
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
                                              _cargarServicios();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () => _mostrarDetalle(servicio),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
