import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../repositories/servicios_repository.dart';
import '../utils/validators.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive.dart';

class RegistroServicioScreen extends StatefulWidget {
  final Map<String, dynamic>? servicioEditar;

  const RegistroServicioScreen({super.key, this.servicioEditar});

  @override
  State<RegistroServicioScreen> createState() => _RegistroServicioScreenState();
}

class _RegistroServicioScreenState extends State<RegistroServicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final valorController = TextEditingController();
  final quienController = TextEditingController();
  final empresaController = TextEditingController();
  final tipoController = TextEditingController();
  final _serviciosRepository = ServiciosRepository();
  DateTime fechaSeleccionada = DateTime.now();
  bool cargando = false;
  String? mensaje;

  @override
  void initState() {
    super.initState();
    if (widget.servicioEditar != null) {
      final s = widget.servicioEditar!;
      fechaSeleccionada = DateTime.parse(s['fecha']);
      // Formatear valor con puntos de miles
      valorController.text = NumberFormat('#,###', 'es_CL').format(s['valor']);
      quienController.text = s['quien'];
      empresaController.text = s['empresa'] ?? '';
      tipoController.text = s['tipo'];
    }
  }

  Future<void> registrarServicio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      cargando = true;
      mensaje = null;
    });

    try {
      // Parsear valor removiendo puntos
      final valorLimpio = valorController.text.replaceAll('.', '');
      final valorInt = int.parse(valorLimpio);
      
      if (widget.servicioEditar != null) {
        await _serviciosRepository.actualizarServicio(
          id: widget.servicioEditar!['id'],
          fecha: fechaSeleccionada.toIso8601String().split('T')[0],
          valor: valorInt,
          quien: quienController.text.trim(),
          empresa: empresaController.text.trim(),
          tipo: tipoController.text.trim(),
        );
        setState(() => mensaje = '✅ Servicio actualizado correctamente');
      } else {
        await _serviciosRepository.crearServicio(
          fecha: fechaSeleccionada.toIso8601String().split('T')[0],
          valor: valorInt,
          quien: quienController.text.trim(),
          empresa: empresaController.text.trim(),
          tipo: tipoController.text.trim(),
        );
        setState(() => mensaje = '✅ Servicio registrado correctamente');
        
        // Limpiar formulario solo si es registro nuevo
        valorController.clear();
        quienController.clear();
        empresaController.clear();
        tipoController.clear();
      }
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => mensaje = null);
        Navigator.pop(context, true); // SIEMPRE volver al home al guardar
      }
    } on TokenExpiredException {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on ApiException catch (e) {
      setState(() => mensaje = '❌ Error: ${e.toString()}');
    } catch (e) {
      setState(() => mensaje = '❌ Error de conexión. Verifica tu internet.');
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  Future<void> seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'CL'),
    );
    if (picked != null) {
      setState(() => fechaSeleccionada = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat("d 'de' MMMM 'de' y", 'es_CL');
    final esEdicion = widget.servicioEditar != null;

    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Servicio' : 'Registrar Servicio')),
      body: SingleChildScrollView(
        child: ResponsivePage(
        maxWidth: 640,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Fecha: ${formatter.format(fechaSeleccionada)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => seleccionarFecha(context),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Cambiar fecha'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: valorController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CLPInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor del servicio',
                  prefixText: '\$',
                  hintText: '50.000',
                ),
                validator: Validators.validateAmount,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quienController,
                decoration: const InputDecoration(
                  labelText: '¿Quién realizó el servicio?',
                  hintText: 'Nombre del chofer',
                ),
                validator: (value) => Validators.validateRequired(value, 'Nombre'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: empresaController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la empresa',
                  prefixIcon: Icon(Icons.business),
                  hintText: 'Ej: Transporte XYZ',
                ),
                validator: (value) => Validators.validateRequired(value, 'Empresa'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tipoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de servicio',
                  hintText: 'Flete, Reparto, Pasaje, etc.',
                ),
                validator: (value) => Validators.validateRequired(value, 'Tipo de servicio'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: cargando ? null : registrarServicio,
                  style: ElevatedButton.styleFrom(
                    elevation: cargando ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: cargando
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Text(esEdicion ? 'Actualizar Servicio' : 'Guardar Servicio', 
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
              if (mensaje != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: AnimatedOpacity(
                    opacity: mensaje != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mensaje!.startsWith('✅')
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: mensaje!.startsWith('✅') ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            mensaje!.startsWith('✅') ? Icons.check_circle : Icons.error,
                            color: mensaje!.startsWith('✅') ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mensaje!,
                              style: TextStyle(
                                color: mensaje!.startsWith('✅') ? Colors.green : Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
        ),
      ),
    );
  }
}
