import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/material_item.dart';
import '../repositories/materiales_repository.dart';
import '../utils/responsive.dart';

class MaterialFormScreen extends StatefulWidget {
  final MaterialItem? material;

  const MaterialFormScreen({super.key, this.material});

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = MaterialesRepository();

  late TextEditingController _nombreController;
  late TextEditingController _categoriaController;
  late TextEditingController _stockController;
  String _unidadMedida = 'unidad';
  bool _activo = true;
  bool _isSaving = false;

  bool get _isEditing => widget.material != null;

  static const _unidades = ['unidad', 'litro', 'kg', 'metro', 'caja', 'par'];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.material?.nombre ?? '');
    _categoriaController = TextEditingController(text: widget.material?.categoria ?? '');
    _stockController = TextEditingController(
      text: widget.material?.stockInicial.toString() ?? '0',
    );
    _unidadMedida = widget.material?.unidadMedida ?? 'unidad';
    _activo = widget.material?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final material = MaterialItem(
        id: widget.material?.id,
        nombre: _nombreController.text.trim(),
        categoria: _categoriaController.text.trim().isEmpty
            ? null
            : _categoriaController.text.trim(),
        unidadMedida: _unidadMedida,
        stockInicial: int.parse(_stockController.text.trim()),
        activo: _activo,
      );

      if (_isEditing) {
        await _repository.actualizarMaterial(material);
      } else {
        await _repository.crearMaterial(material);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Material actualizado correctamente'
                : 'Material registrado correctamente'),
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
        title: Text(_isEditing ? 'Editar Material' : 'Nuevo Material'),
      ),
      body: SingleChildScrollView(
        child: ResponsivePage(
        maxWidth: 640,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Neumático 195/65 R15',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Categoría
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  hintText: 'Ej: Repuestos, Lubricantes, Neumáticos',
                  prefixIcon: Icon(Icons.category),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Unidad de medida
              DropdownButtonFormField<String>(
                initialValue: _unidadMedida,
                decoration: const InputDecoration(
                  labelText: 'Unidad de medida',
                  prefixIcon: Icon(Icons.straighten),
                ),
                items: _unidades
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (value) => setState(() => _unidadMedida = value!),
              ),
              const SizedBox(height: 16),

              // Stock inicial
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock inicial *',
                  hintText: '0',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El stock inicial es obligatorio';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número válido';
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
                activeThumbColor: Colors.green,
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
      ),
    );
  }
}
