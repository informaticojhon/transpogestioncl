import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/remuneracion.dart';
import '../models/trabajador.dart';
import '../repositories/auth_repository.dart';
import '../repositories/personal_repository.dart';
import '../utils/csv_exporter.dart';
import '../utils/currency_formatter.dart';
import '../utils/docx_exporter.dart';
import '../utils/excel_exporter.dart';
import '../utils/pdf_exporter.dart';
import '../utils/remuneracion_grouping.dart';

enum _FormatoExport { csv, excel, pdf, docx }

/// Reporte consolidado de remuneraciones de toda la empresa: filtra por
/// rango de fechas, agrupa los pagos por trabajador con subtotales, y
/// permite registrar/eliminar pagos y exportar el reporte.
class RemuneracionesScreen extends StatefulWidget {
  const RemuneracionesScreen({super.key});

  @override
  State<RemuneracionesScreen> createState() => _RemuneracionesScreenState();
}

class _RemuneracionesScreenState extends State<RemuneracionesScreen> {
  final _repository = PersonalRepository();
  final _authRepository = AuthRepository();
  final _formatoFecha = DateFormat('dd/MM/yyyy');

  bool _esAdmin = true;
  bool _isLoading = true;
  bool _exportando = false;
  late DateTimeRange _rango;
  List<RemuneracionConTrabajador> _remuneraciones = [];
  List<Trabajador> _trabajadoresActivos = [];

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _rango = DateTimeRange(start: DateTime(hoy.year, hoy.month, 1), end: hoy);
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
    await _cargarTrabajadores();
    await _cargarRemuneraciones();
  }

  Future<void> _cargarTrabajadores() async {
    try {
      final trabajadores = await _repository.getTrabajadores(soloActivos: true);
      setState(() => _trabajadoresActivos = trabajadores);
    } catch (_) {
      // Si falla, el diálogo de registrar pago simplemente mostrará la lista vacía.
    }
  }

  Future<void> _cargarRemuneraciones() async {
    setState(() => _isLoading = true);
    try {
      final remuneraciones = await _repository.getRemuneracionesEmpresa(
        desde: _rango.start,
        hasta: _rango.end,
      );
      setState(() {
        _remuneraciones = remuneraciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar remuneraciones: $e')),
        );
      }
    }
  }

  void _elegirPreset(int mesesAtras) {
    final hoy = DateTime.now();
    final mes = DateTime(hoy.year, hoy.month - mesesAtras, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0);
    setState(() => _rango = DateTimeRange(
          start: mes,
          end: mesesAtras == 0 ? hoy : finMes,
        ));
    _cargarRemuneraciones();
  }

  Future<void> _elegirRangoPersonalizado() async {
    final elegido = await showDateRangePicker(
      context: context,
      initialDateRange: _rango,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (elegido != null) {
      setState(() => _rango = elegido);
      _cargarRemuneraciones();
    }
  }

  Future<void> _registrarPago() async {
    if (_trabajadoresActivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registra trabajadores activos antes de registrar pagos')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    int trabajadorId = _trabajadoresActivos.first.id!;
    DateTime fechaPago = DateTime.now();
    int monto = 0;
    String periodo = 'mensual';
    String? concepto;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar Pago'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: trabajadorId,
                    decoration: const InputDecoration(
                      labelText: 'Trabajador',
                      border: OutlineInputBorder(),
                    ),
                    items: _trabajadoresActivos
                        .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombreCompleto)))
                        .toList(),
                    onChanged: (value) => setDialogState(() => trabajadorId = value!),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final f = await showDatePicker(
                        context: context,
                        initialDate: fechaPago,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (f != null) setDialogState(() => fechaPago = f);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de pago',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatoFecha.format(fechaPago)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    onChanged: (value) => monto = int.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: periodo,
                    decoration: const InputDecoration(
                      labelText: 'Periodo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                      DropdownMenuItem(value: 'quincenal', child: Text('Quincenal')),
                      DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                    ],
                    onChanged: (value) => setDialogState(() => periodo = value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Concepto (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => concepto = value.isEmpty ? null : value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
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

    if (result != true) return;

    try {
      await _repository.registrarRemuneracion(Remuneracion(
        trabajadorId: trabajadorId,
        fechaPago: fechaPago,
        monto: monto,
        periodo: periodo,
        concepto: concepto,
      ));
      _cargarRemuneraciones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado')),
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

  Future<void> _eliminarPago(Remuneracion remuneracion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar pago'),
        content: const Text('¿Está seguro?'),
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
      await _repository.eliminarRemuneracion(remuneracion.id!);
      _cargarRemuneraciones();
    }
  }

  Future<void> _exportar(_FormatoExport formato) async {
    setState(() => _exportando = true);
    try {
      final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
      switch (formato) {
        case _FormatoExport.csv:
          final filas = <List<dynamic>>[
            ['Fecha de pago', 'Trabajador', 'Periodo', 'Concepto', 'Monto'],
            for (final item in _remuneraciones)
              [
                item.remuneracion.fechaPago.toIso8601String().split('T')[0],
                item.nombreTrabajador,
                item.remuneracion.periodo,
                item.remuneracion.concepto ?? '',
                item.remuneracion.monto,
              ],
          ];
          exportarCsv('remuneraciones_$hoy.csv', filas);
        case _FormatoExport.excel:
          exportarExcelRemuneraciones('remuneraciones_$hoy.xlsx', _remuneraciones);
        case _FormatoExport.pdf:
          await exportarPdfRemuneraciones('remuneraciones_$hoy.pdf', _remuneraciones);
        case _FormatoExport.docx:
          exportarDocxRemuneraciones('remuneraciones_$hoy.docx', _remuneraciones);
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

  @override
  Widget build(BuildContext context) {
    if (!_esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Remuneraciones')),
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

    final totalGeneral = _remuneraciones.fold<int>(0, (sum, r) => sum + r.remuneracion.monto);
    final grupos = agruparRemuneracionesPorTrabajador(_remuneraciones);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remuneraciones'),
        actions: [
          if (_remuneraciones.isNotEmpty)
            _exportando
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : PopupMenuButton<_FormatoExport>(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Exportar',
                    onSelected: _exportar,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _FormatoExport.excel,
                        child: Row(children: [
                          Icon(Icons.grid_on, size: 20),
                          SizedBox(width: 8),
                          Text('Excel (.xlsx)'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: _FormatoExport.pdf,
                        child: Row(children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('PDF'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: _FormatoExport.docx,
                        child: Row(children: [
                          Icon(Icons.description_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Word (.docx)'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: _FormatoExport.csv,
                        child: Row(children: [
                          Icon(Icons.table_chart_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('CSV'),
                        ]),
                      ),
                    ],
                  ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.today, size: 18),
                      label: const Text('Este mes'),
                      onPressed: () => _elegirPreset(0),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.history, size: 18),
                      label: const Text('Mes pasado'),
                      onPressed: () => _elegirPreset(1),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        '${_formatoFecha.format(_rango.start)} - ${_formatoFecha.format(_rango.end)}',
                      ),
                      onPressed: _elegirRangoPersonalizado,
                    ),
                  ],
                ),
              ),
              if (!_isLoading && _remuneraciones.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_remuneraciones.length} pago(s) · Total: ${CurrencyFormatter.formatCLP(totalGeneral)}',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _remuneraciones.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No hay pagos registrados en este rango'),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _registrarPago,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Registrar pago'),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              for (final grupo in grupos.entries) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                                  child: Text(
                                    '${grupo.key} · ${CurrencyFormatter.formatCLP(grupo.value.fold<int>(0, (sum, r) => sum + r.remuneracion.monto))}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                for (final item in grupo.value)
                                  Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(Icons.attach_money, color: Colors.white),
                                      ),
                                      title: Text(CurrencyFormatter.formatCLP(item.remuneracion.monto)),
                                      subtitle: Text(
                                        '${_formatoFecha.format(item.remuneracion.fechaPago)} · '
                                        '${item.remuneracion.periodo.toUpperCase()}'
                                        '${item.remuneracion.concepto != null && item.remuneracion.concepto!.isNotEmpty ? ' · ${item.remuneracion.concepto}' : ''}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _eliminarPago(item.remuneracion),
                                      ),
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 72),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registrarPago,
        icon: const Icon(Icons.add),
        label: const Text('Registrar pago'),
      ),
    );
  }
}
