import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trabajador.dart';
import '../models/turno.dart';
import '../models/remuneracion.dart';
import '../repositories/personal_repository.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive.dart';

class TrabajadorDetalleScreen extends StatefulWidget {
  final Trabajador trabajador;

  const TrabajadorDetalleScreen({super.key, required this.trabajador});

  @override
  State<TrabajadorDetalleScreen> createState() => _TrabajadorDetalleScreenState();
}

class _TrabajadorDetalleScreenState extends State<TrabajadorDetalleScreen>
    with SingleTickerProviderStateMixin {
  final _repository = PersonalRepository();
  late TabController _tabController;

  List<Turno> _turnos = [];
  List<Remuneracion> _remuneraciones = [];
  Map<String, dynamic>? _estadisticas;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final turnos = await _repository.getTurnosPorTrabajador(widget.trabajador.id!);
      final remuneraciones = await _repository.getRemuneracionesPorTrabajador(widget.trabajador.id!);
      final estadisticas = await _repository.getEstadisticasTrabajador(widget.trabajador.id!);

      setState(() {
        _turnos = turnos;
        _remuneraciones = remuneraciones;
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

  Future<void> _registrarTurno() async {
    final formKey = GlobalKey<FormState>();
    DateTime? fecha = DateTime.now();
    double horas = 8.0;
    String tipoTurno = 'normal';
    String? observaciones;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Turno'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final f = await showDatePicker(
                    context: context,
                    initialDate: fecha!,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (f != null) fecha = f;
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(fecha!)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: horas.toString(),
                decoration: const InputDecoration(
                  labelText: 'Horas trabajadas',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => horas = double.tryParse(value) ?? 8.0,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tipoTurno,
                decoration: const InputDecoration(
                  labelText: 'Tipo de turno',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'extra', child: Text('Extra')),
                  DropdownMenuItem(value: 'nocturno', child: Text('Nocturno')),
                ],
                onChanged: (value) => tipoTurno = value!,
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final turno = Turno(
          trabajadorId: widget.trabajador.id!,
          fecha: fecha!,
          horasTrabajadas: horas,
          tipoTurno: tipoTurno,
          observaciones: observaciones,
        );
        await _repository.registrarTurno(turno);
        _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Turno registrado')),
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

  Future<void> _registrarRemuneracion() async {
    final formKey = GlobalKey<FormState>();
    DateTime? fechaPago = DateTime.now();
    int monto = 0;
    String periodo = 'mensual';
    String? concepto;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Remuneración'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final f = await showDatePicker(
                    context: context,
                    initialDate: fechaPago!,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (f != null) fechaPago = f;
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de pago',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(fechaPago!)),
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
                onChanged: (value) => periodo = value!,
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
    );

    if (result == true) {
      try {
        final remuneracion = Remuneracion(
          trabajadorId: widget.trabajador.id!,
          fechaPago: fechaPago!,
          monto: monto,
          periodo: periodo,
          concepto: concepto,
        );
        await _repository.registrarRemuneracion(remuneracion);
        _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Remuneración registrada')),
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
          // Información Personal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Personal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('RUT:', widget.trabajador.rutFormateado),
                  _buildInfoRow('Nombre:', widget.trabajador.nombreCompleto),
                  _buildInfoRow('Cargo:', widget.trabajador.cargo ?? 'No especificado'),
                  _buildInfoRow(
                    'Fecha Ingreso:',
                    DateFormat('dd/MM/yyyy').format(widget.trabajador.fechaIngreso),
                  ),
                  _buildInfoRow(
                    'Días Trabajados:',
                    '${widget.trabajador.diasTrabajados} días',
                  ),
                  if (widget.trabajador.telefono != null)
                    _buildInfoRow('Teléfono:', widget.trabajador.telefono!),
                  if (widget.trabajador.email != null)
                    _buildInfoRow('Email:', widget.trabajador.email!),
                  _buildInfoRow(
                    'Salario Base:',
                    CurrencyFormatter.formatCLP(widget.trabajador.salarioBase),
                  ),
                  _buildInfoRow(
                    'Estado:',
                    widget.trabajador.activo ? 'Activo' : 'Inactivo',
                    color: widget.trabajador.activo ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Estadísticas
          if (_estadisticas != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estadísticas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Turnos',
                          _estadisticas!['total_turnos'].toString(),
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Horas',
                          _estadisticas!['total_horas'].toStringAsFixed(1),
                          Icons.access_time,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Total Pagado',
                          CurrencyFormatter.formatCLP(_estadisticas!['total_pagado']),
                          Icons.attach_money,
                          Colors.green,
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
            fontSize: 20,
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

  Widget _buildTurnosTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_turnos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No hay turnos registrados'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _registrarTurno,
              icon: const Icon(Icons.add),
              label: const Text('Registrar Turno'),
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
            onPressed: _registrarTurno,
            icon: const Icon(Icons.add),
            label: const Text('Registrar Turno'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _turnos.length,
            itemBuilder: (context, index) {
              final turno = _turnos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: turno.tipoTurno == 'extra'
                        ? Colors.orange
                        : turno.tipoTurno == 'nocturno'
                            ? Colors.indigo
                            : Colors.blue,
                    child: Text(
                      turno.horasTrabajadas.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text(DateFormat('dd/MM/yyyy').format(turno.fecha)),
                  subtitle: Text(
                    '${turno.horasTrabajadas}h - ${turno.tipoTurno.toUpperCase()}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar turno'),
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
                        await _repository.eliminarTurno(turno.id!);
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

  Widget _buildRemuneracionesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_remuneraciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No hay remuneraciones registradas'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _registrarRemuneracion,
              icon: const Icon(Icons.add),
              label: const Text('Registrar Pago'),
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
            onPressed: _registrarRemuneracion,
            icon: const Icon(Icons.add),
            label: const Text('Registrar Pago'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _remuneraciones.length,
            itemBuilder: (context, index) {
              final rem = _remuneraciones[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.attach_money, color: Colors.white),
                  ),
                  title: Text(CurrencyFormatter.formatCLP(rem.monto)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(rem.fechaPago)),
                      Text('Periodo: ${rem.periodo}'),
                      if (rem.concepto != null) Text(rem.concepto!),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar remuneración'),
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
                        await _repository.eliminarRemuneracion(rem.id!);
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
        title: Text(widget.trabajador.nombreCompleto),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Info'),
            Tab(icon: Icon(Icons.event), text: 'Turnos'),
            Tab(icon: Icon(Icons.attach_money), text: 'Pagos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildTurnosTab(),
          _buildRemuneracionesTab(),
        ],
      ),
    );
  }
}
