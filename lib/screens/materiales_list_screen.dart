import 'package:flutter/material.dart';
import '../models/material_item.dart';
import '../repositories/auth_repository.dart';
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
  final _authRepository = AuthRepository();
  List<MaterialItem> _materiales = [];
  List<MaterialItem> _materialesFiltrados = [];
  Map<int, int> _stock = {};
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
      final resultados = await Future.wait([
        _repository.getMateriales(soloActivos: _soloActivos),
        _repository.getStockDeTodos(),
      ]);
      final materiales = resultados[0] as List<MaterialItem>;
      final stock = resultados[1] as Map<int, int>;
      setState(() {
        _materiales = materiales;
        _materialesFiltrados = materiales;
        _stock = stock;
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

  bool _esStockBajo(MaterialItem m) {
    if (m.stockMinimo <= 0 || m.id == null) return false;
    final actual = _stock[m.id!] ?? m.stockInicial;
    return actual < m.stockMinimo;
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
    if (!_esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Materiales')),
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
          if (!_isLoading && _materiales.any(_esStockBajo))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_materiales.where(_esStockBajo).length} material(es) con stock bajo',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
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
                                  if (_esStockBajo(material))
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
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
                                  Text(
                                    'Stock actual: ${_stock[material.id] ?? material.stockInicial} ${material.unidadMedida}',
                                    style: TextStyle(
                                      color: _esStockBajo(material) ? Colors.orange[800] : null,
                                      fontWeight: _esStockBajo(material) ? FontWeight.w600 : null,
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
