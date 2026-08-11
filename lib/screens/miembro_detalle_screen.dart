import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/empresa.dart';
import '../repositories/auth_repository.dart';
import '../utils/responsive.dart';

class MiembroDetalleScreen extends StatefulWidget {
  final MiembroEquipo miembro;
  final bool esAdminActual;
  final String miUserId;

  const MiembroDetalleScreen({
    super.key,
    required this.miembro,
    required this.esAdminActual,
    required this.miUserId,
  });

  @override
  State<MiembroDetalleScreen> createState() => _MiembroDetalleScreenState();
}

class _MiembroDetalleScreenState extends State<MiembroDetalleScreen> {
  final _authRepository = AuthRepository();
  bool _eliminando = false;

  bool get _puedeEliminar => widget.esAdminActual && widget.miembro.id != widget.miUserId;

  Future<void> _confirmarEliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          '¿Estás seguro de eliminar por completo la cuenta de ${widget.miembro.nombre}?\n\n'
          'Esta acción no se puede deshacer: perderá el acceso a la app. '
          'Los servicios, trabajadores y materiales que haya registrado se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _eliminando = true);
    try {
      await _authRepository.eliminarMiembroEquipo(widget.miembro.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _eliminando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final m = widget.miembro;

    return Scaffold(
      appBar: AppBar(title: Text(m.nombre)),
      body: SingleChildScrollView(
        child: ResponsivePage(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    m.nombre.isNotEmpty ? m.nombre[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 28, color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Información', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _buildInfoRow('Nombre:', m.nombre),
                      _buildInfoRow('Email:', m.email),
                      _buildInfoRow('Rol:', m.rol == 'admin' ? 'Administrador' : 'Empleado'),
                      _buildInfoRow(
                        'Miembro desde:',
                        m.createdAt != null ? DateFormat('dd/MM/yyyy').format(m.createdAt!) : 'No disponible',
                      ),
                    ],
                  ),
                ),
              ),
              if (_puedeEliminar) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _eliminando ? null : _confirmarEliminar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: _eliminando
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.delete_forever),
                    label: Text(_eliminando ? 'Eliminando...' : 'Eliminar cuenta'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
