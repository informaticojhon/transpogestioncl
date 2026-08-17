import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trabajador.dart';
import '../models/turno.dart';
import '../repositories/auth_repository.dart';
import '../repositories/personal_repository.dart';

/// Calendario de turnos de toda la empresa: navega día por día y muestra
/// quién está programado ese día, con opción de agregar o eliminar turnos
/// sin tener que entrar al detalle de cada trabajador.
class TurnosScreen extends StatefulWidget {
  const TurnosScreen({super.key});

  @override
  State<TurnosScreen> createState() => _TurnosScreenState();
}

class _TurnosScreenState extends State<TurnosScreen> {
  final _repository = PersonalRepository();
  final _authRepository = AuthRepository();

  bool _esAdmin = true;
  bool _isLoading = true;
  DateTime _fecha = DateTime.now();
  List<TurnoConTrabajador> _turnos = [];
  List<Trabajador> _trabajadoresActivos = [];

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
    await _cargarTrabajadores();
    await _cargarTurnos();
  }

  Future<void> _cargarTrabajadores() async {
    try {
      final trabajadores = await _repository.getTrabajadores(soloActivos: true);
      setState(() => _trabajadoresActivos = trabajadores);
    } catch (_) {
      // Si falla, el diálogo de agregar turno simplemente mostrará la lista vacía.
    }
  }

  Future<void> _cargarTurnos() async {
    setState(() => _isLoading = true);
    try {
      final turnos = await _repository.getTurnosPorFechaConTrabajador(_fecha);
      setState(() {
        _turnos = turnos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar turnos: $e')),
        );
      }
    }
  }

  void _cambiarDia(int deltaDias) {
    setState(() => _fecha = _fecha.add(Duration(days: deltaDias)));
    _cargarTurnos();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (elegida != null) {
      setState(() => _fecha = elegida);
      _cargarTurnos();
    }
  }

  Future<void> _agregarTurno() async {
    if (_trabajadoresActivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registra trabajadores activos antes de programar turnos')),
      );
      return;
    }

    int trabajadorId = _trabajadoresActivos.first.id!;
    double horas = 8.0;
    String tipoTurno = 'normal';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Nuevo turno · ${DateFormat('dd/MM/yyyy').format(_fecha)}'),
          content: SingleChildScrollView(
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
                  onChanged: (value) => setDialogState(() => tipoTurno = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      await _repository.registrarTurno(Turno(
        trabajadorId: trabajadorId,
        fecha: _fecha,
        horasTrabajadas: horas,
        tipoTurno: tipoTurno,
      ));
      _cargarTurnos();
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

  Future<void> _eliminarTurno(Turno turno) async {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _repository.eliminarTurno(turno.id!);
      _cargarTurnos();
    }
  }

  Color _colorTipoTurno(String tipo) {
    switch (tipo) {
      case 'extra':
        return Colors.orange;
      case 'nocturno':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  bool get _esHoy {
    final hoy = DateTime.now();
    return _fecha.year == hoy.year && _fecha.month == hoy.month && _fecha.day == hoy.day;
  }

  @override
  Widget build(BuildContext context) {
    if (!_esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Turnos')),
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

    final totalHoras = _turnos.fold<double>(0, (sum, t) => sum + t.turno.horasTrabajadas);

    return Scaffold(
      appBar: AppBar(title: const Text('Turnos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _cambiarDia(-1),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _elegirFecha,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('EEEE dd MMMM yyyy', 'es_CL').format(_fecha),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_esHoy)
                                    const Text('Hoy', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _cambiarDia(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_isLoading && _turnos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_turnos.length} turno(s) · ${totalHoras.toStringAsFixed(0)}h en total',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _turnos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No hay turnos programados para este día'),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _agregarTurno,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Programar turno'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _turnos.length,
                            itemBuilder: (context, index) {
                              final item = _turnos[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _colorTipoTurno(item.turno.tipoTurno),
                                    child: Text(
                                      item.turno.horasTrabajadas.toStringAsFixed(0),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  title: Text(item.nombreTrabajador),
                                  subtitle: Text(
                                    '${item.turno.horasTrabajadas}h - ${item.turno.tipoTurno.toUpperCase()}'
                                    '${item.turno.observaciones != null && item.turno.observaciones!.isNotEmpty ? ' · ${item.turno.observaciones}' : ''}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarTurno(item.turno),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarTurno,
        icon: const Icon(Icons.add),
        label: const Text('Programar turno'),
      ),
    );
  }
}
