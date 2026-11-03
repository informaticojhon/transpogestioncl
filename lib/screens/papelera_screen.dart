import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/registro_auditoria.dart';
import '../repositories/auth_repository.dart';
import '../repositories/servicios_repository.dart';
import '../utils/currency_formatter.dart';
import '../utils/fecha_reporte.dart';

const int _kDiasPapelera = 30;

/// Papelera: servicios eliminados en los últimos 30 días, para
/// devolverlos al historial tal como estaban. Se arma con la auditoría
/// (que guarda una copia de cada servicio al borrarlo), por eso solo la
/// ven los administradores.
class PapeleraScreen extends StatefulWidget {
  const PapeleraScreen({super.key});

  @override
  State<PapeleraScreen> createState() => _PapeleraScreenState();
}

class _PapeleraScreenState extends State<PapeleraScreen> {
  final _authRepository = AuthRepository();
  final _serviciosRepository = ServiciosRepository();
  final _formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');

  bool _esAdmin = true;
  bool _cargando = true;
  bool _restaurando = false;
  String? _error;
  List<RegistroAuditoria> _eliminados = [];
  Map<String, String> _nombresPorUserId = {};

  @override
  void initState() {
    super.initState();
    _verificarAccesoYCargar();
  }

  Future<void> _verificarAccesoYCargar() async {
    final rol = await _authRepository.getRolUsuario();
    if (rol != 'admin') {
      if (mounted) {
        setState(() {
          _esAdmin = false;
          _cargando = false;
        });
      }
      return;
    }
    try {
      final miembros = await _authRepository.getMiembrosEquipo();
      _nombresPorUserId = {for (final m in miembros) m.id: m.nombre};
    } catch (_) {
      // Sin nombres se muestra "Usuario eliminado"; no bloquea la pantalla.
    }
    await _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final eliminados = await _serviciosRepository.obtenerServiciosEliminados(dias: _kDiasPapelera);
      if (mounted) {
        setState(() {
          _eliminados = eliminados;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar la papelera: $e';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _restaurar(List<RegistroAuditoria> registros) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _restaurando = true);
    try {
      await _serviciosRepository.restaurarServicios([for (final r in registros) r.datos!]);
      final ids = {for (final r in registros) r.id};
      if (mounted) setState(() => _eliminados.removeWhere((r) => ids.contains(r.id)));
      // Si se restauran varios seguidos, cada aviso reemplaza al anterior.
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text(registros.length == 1
            ? 'Servicio restaurado'
            : '${registros.length} servicios restaurados'),
        duration: const Duration(seconds: 1),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo restaurar: $e')));
      // Puede haber quedado una parte restaurada: recargar muestra lo que falta.
      if (mounted) _cargar();
    } finally {
      if (mounted) setState(() => _restaurando = false);
    }
  }

  Future<void> _restaurarTodo() async {
    final total = _eliminados.fold<int>(0, (suma, r) => suma + ((r.datos?['valor'] as num?)?.toInt() ?? 0));
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar todo'),
        content: Text(
          'Se devolverán al historial ${_eliminados.length} servicios '
          '(${CurrencyFormatter.formatCLP(total)}).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (confirmar == true) await _restaurar(List.of(_eliminados));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Papelera'),
        actions: [
          if (_esAdmin && _eliminados.length > 1)
            TextButton.icon(
              onPressed: _restaurando ? null : _restaurarTodo,
              icon: const Icon(Icons.restore),
              label: const Text('Restaurar todo'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _buildCuerpo(),
        ),
      ),
    );
  }

  Widget _buildCuerpo() {
    if (!_esAdmin) {
      return _mensaje(
        Icons.lock_outline,
        'Solo los administradores de la empresa pueden ver la papelera',
      );
    }
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _mensaje(Icons.error_outline, _error!),
          FilledButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
        ],
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Servicios eliminados en los últimos $_kDiasPapelera días. '
            'Al restaurarlos vuelven al historial tal como estaban.',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
        if (_restaurando) const LinearProgressIndicator(),
        Expanded(
          child: _eliminados.isEmpty
              ? _mensaje(Icons.delete_outline, 'La papelera está vacía')
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _eliminados.length,
                    itemBuilder: (context, index) => _buildItem(_eliminados[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildItem(RegistroAuditoria registro) {
    final datos = registro.datos!;
    final quien = _nombresPorUserId[registro.userId] ?? 'Usuario eliminado';
    final detalle = [
      fechaReporte(datos['fecha']),
      if (datos['quien'] != null) datos['quien'],
      if (datos['tipo'] != null) datos['tipo'],
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${datos['empresa'] ?? 'Sin empresa'} · ${CurrencyFormatter.formatCLP(datos['valor'] ?? 0)}'),
        subtitle: Text('$detalle\nEliminado por $quien el ${_formatoFechaHora.format(registro.createdAt.toLocal())}'),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: _restaurando ? null : () => _restaurar([registro]),
          child: const Text('Restaurar'),
        ),
      ),
    );
  }

  Widget _mensaje(IconData icono, String texto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
