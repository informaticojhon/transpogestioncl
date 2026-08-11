import 'package:flutter/material.dart';
import '../models/trabajador.dart';
import '../repositories/auth_repository.dart';
import '../repositories/personal_repository.dart';
import 'trabajador_form_screen.dart';
import 'trabajador_detalle_screen.dart';

class TrabajadoresListScreen extends StatefulWidget {
  const TrabajadoresListScreen({super.key});

  @override
  State<TrabajadoresListScreen> createState() => _TrabajadoresListScreenState();
}

class _TrabajadoresListScreenState extends State<TrabajadoresListScreen> {
  final _repository = PersonalRepository();
  final _authRepository = AuthRepository();
  List<Trabajador> _trabajadores = [];
  List<Trabajador> _trabajadoresFiltrados = [];
  bool _isLoading = true;
  bool _soloActivos = true;
  bool _esAdmin = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verificarAccesoYCargar();
  }

  Future<void> _verificarAccesoYCargar() async {
    final rol = await _authRepository.getRolUsuario();
    if (rol != 'admin') {
      setState(() {
        _esAdmin = false;
        _isLoading = false;
      });
      return;
    }
    _cargarTrabajadores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarTrabajadores() async {
    setState(() => _isLoading = true);
    try {
      final trabajadores = await _repository.getTrabajadores(soloActivos: _soloActivos);
      setState(() {
        _trabajadores = trabajadores;
        _trabajadoresFiltrados = trabajadores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar trabajadores: $e')),
        );
      }
    }
  }

  void _filtrarTrabajadores(String query) {
    setState(() {
      if (query.isEmpty) {
        _trabajadoresFiltrados = _trabajadores;
      } else {
        _trabajadoresFiltrados = _trabajadores.where((t) {
          final nombreCompleto = t.nombreCompleto.toLowerCase();
          final rut = t.rut.toLowerCase();
          final cargo = t.cargo?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return nombreCompleto.contains(searchLower) ||
              rut.contains(searchLower) ||
              cargo.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _navegarFormulario({Trabajador? trabajador}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrabajadorFormScreen(trabajador: trabajador),
      ),
    );
    if (result == true) {
      _cargarTrabajadores();
    }
  }

  Future<void> _navegarDetalle(Trabajador trabajador) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrabajadorDetalleScreen(trabajador: trabajador),
      ),
    );
    if (result == true) {
      _cargarTrabajadores();
    }
  }

  Future<void> _cambiarEstado(Trabajador trabajador) async {
    try {
      await _repository.cambiarEstadoTrabajador(trabajador.id!, !trabajador.activo);
      _cargarTrabajadores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trabajador.activo ? 'Trabajador dado de baja' : 'Trabajador reactivado'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Trabajador trabajador) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar a ${trabajador.nombreCompleto}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _repository.eliminarTrabajador(trabajador.id!);
        _cargarTrabajadores();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trabajador eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Personal')),
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
      appBar: AppBar(
        title: const Text('Gestión de Personal'),
        actions: [
          IconButton(
            icon: Icon(_soloActivos ? Icons.visibility : Icons.visibility_off),
            tooltip: _soloActivos ? 'Mostrar todos' : 'Solo activos',
            onPressed: () {
              setState(() => _soloActivos = !_soloActivos);
              _cargarTrabajadores();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTrabajadores,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar trabajador',
                hintText: 'Nombre, RUT o cargo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarTrabajadores('');
                        },
                      )
                    : null,
              ),
              onChanged: _filtrarTrabajadores,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trabajadoresFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _trabajadores.isEmpty
                                  ? 'No hay trabajadores registrados'
                                  : 'No se encontraron resultados',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _trabajadoresFiltrados.length,
                        itemBuilder: (context, index) {
                          final trabajador = _trabajadoresFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: trabajador.activo
                                    ? Colors.blue
                                    : Colors.grey,
                                child: Text(
                                  trabajador.nombre[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      trabajador.nombreCompleto,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!trabajador.activo)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Inactivo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('RUT: ${trabajador.rutFormateado}'),
                                  if (trabajador.cargo != null)
                                    Text('Cargo: ${trabajador.cargo}'),
                                  Text(
                                    '${trabajador.diasTrabajados} días trabajados',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'ver',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility, size: 20),
                                        SizedBox(width: 8),
                                        Text('Ver detalle'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'estado',
                                    child: Row(
                                      children: [
                                        Icon(
                                          trabajador.activo
                                              ? Icons.toggle_on
                                              : Icons.toggle_off,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(trabajador.activo ? 'Dar de baja' : 'Reactivar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'eliminar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  switch (value) {
                                    case 'ver':
                                      _navegarDetalle(trabajador);
                                      break;
                                    case 'editar':
                                      _navegarFormulario(trabajador: trabajador);
                                      break;
                                    case 'estado':
                                      _cambiarEstado(trabajador);
                                      break;
                                    case 'eliminar':
                                      _confirmarEliminar(trabajador);
                                      break;
                                  }
                                },
                              ),
                              onTap: () => _navegarDetalle(trabajador),
                            ),
                          );
                        },
                      ),
          ),
        ],
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarFormulario(),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Trabajador'),
      ),
    );
  }
}
