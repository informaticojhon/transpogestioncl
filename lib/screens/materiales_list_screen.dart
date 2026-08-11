import 'package:flutter/material.dart';
import '../models/material_item.dart';
import '../repositories/materiales_repository.dart';
import 'material_form_screen.dart';
import 'material_detalle_screen.dart';

class MaterialesListScreen extends StatefulWidget {
  const MaterialesListScreen({super.key});

  @override
  State<MaterialesListScreen> createState() => _MaterialesListScreenState();
}

class _MaterialesListScreenState extends State<MaterialesListScreen> {
  final _repository = MaterialesRepository();
  List<MaterialItem> _materiales = [];
  List<MaterialItem> _materialesFiltrados = [];
  bool _isLoading = true;
  bool _soloActivos = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarMateriales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarMateriales() async {
    setState(() => _isLoading = true);
    try {
      final materiales = await _repository.getMateriales(soloActivos: _soloActivos);
      setState(() {
        _materiales = materiales;
        _materialesFiltrados = materiales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar materiales: $e')),
        );
      }
    }
  }

  void _filtrarMateriales(String query) {
    setState(() {
      if (query.isEmpty) {
        _materialesFiltrados = _materiales;
      } else {
        _materialesFiltrados = _materiales.where((m) {
          final nombre = m.nombre.toLowerCase();
          final categoria = m.categoria?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return nombre.contains(searchLower) || categoria.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _navegarFormulario({MaterialItem? material}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialFormScreen(material: material),
      ),
    );
    if (result == true) {
      _cargarMateriales();
    }
  }

  Future<void> _navegarDetalle(MaterialItem material) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialDetalleScreen(material: material),
      ),
    );
    if (result == true) {
      _cargarMateriales();
    }
  }

  Future<void> _cambiarEstado(MaterialItem material) async {
    try {
      await _repository.cambiarEstadoMaterial(material.id!, !material.activo);
      _cargarMateriales();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(material.activo ? 'Material dado de baja' : 'Material reactivado'),
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

  Future<void> _confirmarEliminar(MaterialItem material) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar "${material.nombre}"?'),
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
        await _repository.eliminarMaterial(material.id!);
        _cargarMateriales();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material eliminado')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Materiales'),
        actions: [
          IconButton(
            icon: Icon(_soloActivos ? Icons.visibility : Icons.visibility_off),
            tooltip: _soloActivos ? 'Mostrar todos' : 'Solo activos',
            onPressed: () {
              setState(() => _soloActivos = !_soloActivos);
              _cargarMateriales();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarMateriales,
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
                labelText: 'Buscar material',
                hintText: 'Nombre o categoría',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarMateriales('');
                        },
                      )
                    : null,
              ),
              onChanged: _filtrarMateriales,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _materialesFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _materiales.isEmpty
                                  ? 'No hay materiales registrados'
                                  : 'No se encontraron resultados',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _materialesFiltrados.length,
                        itemBuilder: (context, index) {
                          final material = _materialesFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: material.activo
                                    ? Colors.blue
                                    : Colors.grey,
                                child: const Icon(Icons.inventory_2, color: Colors.white),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      material.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!material.activo)
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
                                  if (material.categoria != null)
                                    Text('Categoría: ${material.categoria}'),
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
                                          material.activo
                                              ? Icons.toggle_on
                                              : Icons.toggle_off,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(material.activo ? 'Dar de baja' : 'Reactivar'),
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
                                      _navegarDetalle(material);
                                      break;
                                    case 'editar':
                                      _navegarFormulario(material: material);
                                      break;
                                    case 'estado':
                                      _cambiarEstado(material);
                                      break;
                                    case 'eliminar':
                                      _confirmarEliminar(material);
                                      break;
                                  }
                                },
                              ),
                              onTap: () => _navegarDetalle(material),
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
        icon: const Icon(Icons.add_box),
        label: const Text('Nuevo Material'),
      ),
    );
  }
}
