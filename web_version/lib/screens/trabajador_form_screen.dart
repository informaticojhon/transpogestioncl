import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/trabajador.dart';
import '../repositories/personal_repository.dart';

class TrabajadorFormScreen extends StatefulWidget {
  final Trabajador? trabajador;

  const TrabajadorFormScreen({super.key, this.trabajador});

  @override
  State<TrabajadorFormScreen> createState() => _TrabajadorFormScreenState();
}

class _TrabajadorFormScreenState extends State<TrabajadorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = PersonalRepository();

  late TextEditingController _rutController;
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _cargoController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _salarioController;
  DateTime? _fechaIngreso;
  bool _activo = true;
  bool _isSaving = false;

  bool get _isEditing => widget.trabajador != null;

  @override
  void initState() {
    super.initState();
    _rutController = TextEditingController(text: widget.trabajador?.rut ?? '');
    _nombreController = TextEditingController(text: widget.trabajador?.nombre ?? '');
    _apellidoController = TextEditingController(text: widget.trabajador?.apellido ?? '');
    _cargoController = TextEditingController(text: widget.trabajador?.cargo ?? '');
    _telefonoController = TextEditingController(text: widget.trabajador?.telefono ?? '');
    _emailController = TextEditingController(text: widget.trabajador?.email ?? '');
    _salarioController = TextEditingController(
      text: widget.trabajador?.salarioBase.toString() ?? '',
    );
    _fechaIngreso = widget.trabajador?.fechaIngreso;
    _activo = widget.trabajador?.activo ?? true;
  }

  @override
  void dispose() {
    _rutController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _cargoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _salarioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) {
      setState(() => _fechaIngreso = fecha);
    }
  }

  String? _validarRUT(String? value) {
    if (value == null || value.isEmpty) {
      return 'El RUT es obligatorio';
    }
    final rutLimpio = value.replaceAll(RegExp(r'[.-]'), '');
    if (rutLimpio.length < 8 || rutLimpio.length > 9) {
      return 'RUT inválido';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Email inválido';
      }
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaIngreso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar la fecha de ingreso')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final trabajador = Trabajador(
        id: widget.trabajador?.id,
        rut: _rutController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        cargo: _cargoController.text.trim().isEmpty ? null : _cargoController.text.trim(),
        fechaIngreso: _fechaIngreso!,
        telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        salarioBase: int.parse(_salarioController.text.trim()),
        activo: _activo,
      );

      if (_isEditing) {
        await _repository.actualizarTrabajador(trabajador);
      } else {
        await _repository.crearTrabajador(trabajador);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Trabajador actualizado correctamente'
                : 'Trabajador registrado correctamente'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Trabajador' : 'Nuevo Trabajador'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // RUT
              TextFormField(
                controller: _rutController,
                decoration: const InputDecoration(
                  labelText: 'RUT *',
                  hintText: '12345678-9',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: _validarRUT,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9kK.-]')),
                  LengthLimitingTextInputFormatter(12),
                ],
              ),
              const SizedBox(height: 16),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Apellido
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'El apellido es obligatorio' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Cargo
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(
                  labelText: 'Cargo',
                  hintText: 'Ej: Chofer, Auxiliar, Mecánico',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Fecha Ingreso
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Ingreso *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _fechaIngreso == null
                        ? 'Seleccionar fecha'
                        : DateFormat('dd/MM/yyyy').format(_fechaIngreso!),
                    style: TextStyle(
                      color: _fechaIngreso == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: '+56 9 1234 5678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'ejemplo@correo.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
              const SizedBox(height: 16),

              // Salario Base
              TextFormField(
                controller: _salarioController,
                decoration: const InputDecoration(
                  labelText: 'Salario Base *',
                  hintText: '500000',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El salario es obligatorio';
                  }
                  final salario = int.tryParse(value);
                  if (salario == null || salario <= 0) {
                    return 'Debe ser un valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Estado Activo/Inactivo
              SwitchListTile(
                title: const Text('Estado'),
                subtitle: Text(_activo ? 'Activo' : 'Inactivo'),
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
                activeColor: Colors.green,
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton(
                onPressed: _isSaving ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Actualizar' : 'Registrar',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
