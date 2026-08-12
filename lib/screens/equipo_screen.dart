import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/empresa.dart';
import '../repositories/auth_repository.dart';
import '../utils/responsive.dart';
import 'miembro_detalle_screen.dart';

class EquipoScreen extends StatefulWidget {
  const EquipoScreen({super.key});

  @override
  State<EquipoScreen> createState() => _EquipoScreenState();
}

class _EquipoScreenState extends State<EquipoScreen> {
  final _authRepository = AuthRepository();
  Empresa? _empresa;
  List<MiembroEquipo> _miembros = [];
  bool _isLoading = true;
  String? _miRol;
  String? _miUserId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final empresa = await _authRepository.getMiEmpresa();
      final miembros = await _authRepository.getMiembrosEquipo();
      final rol = await _authRepository.getRolUsuario();
      setState(() {
        _empresa = empresa;
        _miembros = miembros;
        _miRol = rol;
        _miUserId = _authRepository.getCurrentUserId();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el equipo: $e')),
        );
      }
    }
  }

  void _copiarCodigo() {
    final codigo = _empresa?.codigoInvitacion;
    if (codigo == null) return;
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_isLoading && _miRol != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestionar mi equipo')),
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
        title: const Text('Gestionar mi equipo'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: ResponsivePage(
                maxWidth: 640,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _empresa?.nombre ?? 'Mi empresa',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_miembros.length} ${_miembros.length == 1 ? 'miembro' : 'miembros'}',
                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Código de invitación',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Compártelo con tus empleados para que se unan a la empresa',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _empresa?.codigoInvitacion ?? '—',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Copiar código',
                                  onPressed: _copiarCodigo,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Miembros', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._miembros.map(
                      (m) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              m.nombre.isNotEmpty ? m.nombre[0].toUpperCase() : '?',
                              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(m.nombre),
                          subtitle: Text(m.email),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: m.rol == 'admin'
                                  ? colorScheme.primary.withValues(alpha: 0.12)
                                  : colorScheme.onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              m.rol == 'admin' ? 'Admin' : 'Empleado',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: m.rol == 'admin' ? colorScheme.primary : colorScheme.onSurface,
                              ),
                            ),
                          ),
                          onTap: () async {
                            final actualizado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MiembroDetalleScreen(
                                  miembro: m,
                                  esAdminActual: _miRol == 'admin',
                                  miUserId: _miUserId ?? '',
                                ),
                              ),
                            );
                            if (actualizado == true) {
                              _cargar();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
