import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/material_item.dart';
import '../models/movimiento_material.dart';
import '../repositories/materiales_repository.dart';
import '../utils/responsive.dart';

class MaterialDetalleScreen extends StatefulWidget {
  final MaterialItem material;

  const MaterialDetalleScreen({super.key, required this.material});

  @override
  State<MaterialDetalleScreen> createState() => _MaterialDetalleScreenState();
}

class _MaterialDetalleScreenState extends State<MaterialDetalleScreen>
    with SingleTickerProviderStateMixin {
  final _repository = MaterialesRepository();
  late TabController _tabController;

  List<MovimientoMaterial> _movimientos = [];
  Map<String, dynamic>? _estadisticas;
  bool _isLoading = true;

  bool get _estaConStockBajo {
    if (widget.material.stockMinimo <= 0 || _estadisticas == null) return false;
    return (_estadisticas!['stock_actual'] as int) < widget.material.stockMinimo;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final movimientos = await _repository.getMovimientosPorMaterial(widget.material.id!);
      final estadisticas = await _repository.getEstadisticasMaterial(widget.material);

      setState(() {
        _movimientos = movimientos;
        _estadisticas = estadisticas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _registrarMovimiento() async {
    final formKey = GlobalKey<FormState>();
    DateTime fecha = DateTime.now();
    String tipo = 'entrada';
    int cantidad = 0;
    String? observaciones;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar Movimiento'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final f = await showDatePicker(
                      context: context,
                      initialDate: fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      locale: const Locale('es', 'CL'),
                    );
                    if (f != null) setDialogState(() => fecha = f);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(fecha)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimiento',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'entrada', child: Text('Entrada (ingreso de stock)')),
                    DropdownMenuItem(value: 'salida', child: Text('Salida (consumo de stock)')),
                  ],
                  onChanged: (value) => setDialogState(() => tipo = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Cantidad (${widget.material.unidadMedida})',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Ingresa una cantidad válida';
                    return null;
                  },
                  onChanged: (value) => cantidad = int.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => observaciones = value.isEmpty ? null : value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final movimiento = MovimientoMaterial(
          materialId: widget.material.id!,
          fecha: fecha,
          tipo: tipo,
          cantidad: cantidad,
          observaciones: observaciones,
        );
        await _repository.registrarMovimiento(movimiento);
        _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movimiento registrado')),
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
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      child: ResponsivePage(
      maxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_estaConStockBajo)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Stock bajo el mínimo configurado',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Material',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('Nombre:', widget.material.nombre),
                  _buildInfoRow('Categoría:', widget.material.categoria ?? 'Sin categoría'),
                  _buildInfoRow('Unidad de medida:', widget.material.unidadMedida),
                  _buildInfoRow(
                    'Stock mínimo:',
                    widget.material.stockMinimo > 0
                        ? '${widget.material.stockMinimo} ${widget.material.unidadMedida}'
                        : 'Sin alerta configurada',
                  ),
                  _buildInfoRow(
                    'Estado:',
                    widget.material.activo ? 'Activo' : 'Inactivo',
                    color: widget.material.activo ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_estadisticas != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stock',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Stock actual',
                          '${_estadisticas!['stock_actual']} ${widget.material.unidadMedida}',
                          Icons.inventory,
                          (_estadisticas!['stock_actual'] as int) <= 0
                              ? Colors.red
                              : _estaConStockBajo
                                  ? Colors.orange
                                  : Colors.blue,
                        ),
                        _buildStatCard(
                          'Entradas',
                          _estadisticas!['total_entradas'].toString(),
                          Icons.arrow_downward,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Salidas',
                          _estadisticas!['total_salidas'].toString(),
                          Icons.arrow_upward,
                          Colors.orange,
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

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMovimientosTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_movimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_vert, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No hay movimientos registrados'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _registrarMovimiento,
              icon: const Icon(Icons.add),
              label: const Text('Registrar Movimiento'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _registrarMovimiento,
            icon: const Icon(Icons.add),
            label: const Text('Registrar Movimiento'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _movimientos.length,
            itemBuilder: (context, index) {
              final mov = _movimientos[index];
              final esEntrada = mov.tipo == 'entrada';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: esEntrada ? Colors.green : Colors.orange,
                    child: Icon(
                      esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    '${esEntrada ? '+' : '-'}${mov.cantidad} ${widget.material.unidadMedida}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(mov.fecha)),
                      if (mov.observaciones != null) Text(mov.observaciones!),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar movimiento'),
                          content: const Text('¿Está seguro?'),
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
                      if (confirmar == true) {
                        await _repository.eliminarMovimiento(mov.id!);
                        _cargarDatos();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.material.nombre),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Info'),
            Tab(icon: Icon(Icons.swap_vert), text: 'Movimientos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildMovimientosTab(),
        ],
      ),
    );
  }
}
