import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/servicios_repository.dart';
import 'registro_servicio_screen.dart';
import '../utils/currency_formatter.dart';
import '../utils/csv_exporter.dart';
import '../utils/excel_exporter.dart';
import '../utils/pdf_exporter.dart';
import '../utils/docx_exporter.dart';
import '../utils/empresa_colors.dart';
import '../utils/fecha_reporte.dart';
import '../utils/servicio_grouping.dart';

const int _kPorPagina = 30;

enum _FormatoExport { csv, excel, pdf, docx }

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _serviciosRepository = ServiciosRepository();
  final _buscarController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<dynamic> _servicios = [];
  List<String> _empresasClientes = [];
  bool _cargando = true;
  bool _cargandoMas = false;
  bool _hayMas = true;
  bool _exportando = false;
  bool _esAdmin = false;
  String _busqueda = '';
  String? _empresaFiltro;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarServicios(reset: true);
    _cargarEmpresasClientes();
    _cargarRol();
    _scrollController.addListener(_onScroll);
  }

  /// La papelera sale de la auditoría, que solo pueden leer los admin.
  Future<void> _cargarRol() async {
    try {
      final rol = await AuthRepository().getRolUsuario();
      if (mounted) setState(() => _esAdmin = rol == 'admin');
    } catch (_) {
      // Sin rol simplemente no aparece el botón de la papelera.
    }
  }

  Future<void> _abrirPapelera() async {
    await Navigator.pushNamed(context, '/papelera');
    // Lo restaurado en la papelera vuelve a aparecer en la lista.
    if (mounted) _cargarServicios(reset: true);
  }

  Future<void> _cargarEmpresasClientes() async {
    try {
      final empresas = await _serviciosRepository.obtenerEmpresasClientesUnicas();
      if (mounted) setState(() => _empresasClientes = empresas);
    } catch (_) {
      // Los chips de filtro simplemente no aparecen si esto falla; no es
      // crítico para el resto de la pantalla.
    }
  }

  void _seleccionarEmpresaFiltro(String? empresa) {
    setState(() => _empresaFiltro = empresa);
    _cargarServicios(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hayMas || _cargandoMas || _cargando) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _cargarMas();
    }
  }

  Future<void> _cargarServicios({required bool reset}) async {
    if (reset) {
      setState(() {
        _cargando = true;
        _error = null;
        _servicios = [];
        _hayMas = true;
      });
    }

    try {
      final servicios = await _serviciosRepository.buscarServiciosPaginado(
        offset: 0,
        limit: _kPorPagina,
        busqueda: _busqueda,
        empresaCliente: _empresaFiltro,
      );
      if (mounted) {
        setState(() {
          _servicios = servicios;
          _hayMas = servicios.length == _kPorPagina;
          _cargando = false;
        });
      }
    } on TokenExpiredException {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar servicios: ${e.toString()}';
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error de conexión. Verifica tu internet.';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cargarMas() async {
    setState(() => _cargandoMas = true);
    try {
      final servicios = await _serviciosRepository.buscarServiciosPaginado(
        offset: _servicios.length,
        limit: _kPorPagina,
        busqueda: _busqueda,
        empresaCliente: _empresaFiltro,
      );
      if (mounted) {
        setState(() {
          _servicios.addAll(servicios);
          _hayMas = servicios.length == _kPorPagina;
          _cargandoMas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoMas = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar más: $e')),
        );
      }
    }
  }

  void _onBuscarChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _busqueda = value;
      _cargarServicios(reset: true);
    });
  }

  Future<bool> _confirmarEliminacion(Map servicio) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar el servicio de ${servicio['empresa']}?'),
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
    return confirmado == true;
  }

  /// Elimina un servicio y ofrece "Deshacer" por unos segundos, que lo
  /// vuelve a insertar tal cual estaba.
  Future<void> _eliminarServicio(Map<String, dynamic> servicio) async {
    // Se quita de la lista al tiro (si fue deslizando, el Dismissible ya
    // lo sacó de la pantalla) para que no vuelva a dibujarse al recargar.
    setState(() => _servicios.removeWhere((s) => s['id'] == servicio['id']));
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _serviciosRepository.eliminarServicio(servicio['id'] as int);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      if (mounted) _cargarServicios(reset: true);
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Servicio de ${servicio['empresa']} eliminado'),
        duration: const Duration(seconds: 1),
        // Con un botón (DESHACER) Flutter lo deja fijo hasta tocarlo; que se cierre solo.
        persist: false,
        action: SnackBarAction(
          label: 'DESHACER',
          onPressed: () => _deshacerEliminacion(servicio, messenger),
        ),
      ),
    );
  }

  Future<void> _deshacerEliminacion(Map<String, dynamic> servicio, ScaffoldMessengerState messenger) async {
    try {
      await _serviciosRepository.restaurarServicio(servicio);
      messenger.showSnackBar(const SnackBar(content: Text('Servicio restaurado'), duration: Duration(seconds: 1)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo restaurar: $e')));
    }
    if (mounted) _cargarServicios(reset: true);
  }

  Future<void> _exportar(_FormatoExport formato) async {
    setState(() => _exportando = true);
    try {
      final serviciosSinOrdenar = await _serviciosRepository.obtenerTodosParaExportar(
        busqueda: _busqueda.isEmpty ? null : _busqueda,
        empresaCliente: _empresaFiltro,
      );
      // Del más reciente al más antiguo, igual en los cuatro formatos.
      final servicios = ordenarServiciosPorFechaDesc(serviciosSinOrdenar);

      if (servicios.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay servicios para exportar')),
          );
        }
        return;
      }

      final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

      switch (formato) {
        case _FormatoExport.csv:
          final filas = <List<dynamic>>[
            ['Fecha', 'Empresa', 'Quién', 'Tipo', 'Valor'],
            for (final s in servicios)
              [fechaReporte(s['fecha']), s['empresa'] ?? '', s['quien'] ?? '', s['tipo'] ?? '', s['valor'] ?? 0],
          ];
          exportarCsv('historial_servicios_$hoy.csv', filas);
        case _FormatoExport.excel:
          exportarExcelServicios('historial_servicios_$hoy.xlsx', servicios);
        case _FormatoExport.pdf:
          await exportarPdfServicios('historial_servicios_$hoy.pdf', servicios);
        case _FormatoExport.docx:
          exportarDocxServicios('historial_servicios_$hoy.docx', servicios);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${servicios.length} servicios exportados')),
        );
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

  void _mostrarDetalle(dynamic servicio) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final fecha = DateTime.parse(servicio['fecha']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle del Servicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${servicio['tipo'] ?? 'N/A'}'),
            Text('Empresa: ${servicio['empresa'] ?? 'N/A'}'),
            Text('Realizado por: ${servicio['quien'] ?? 'N/A'}'),
            Text('Monto: ${CurrencyFormatter.formatCLP(servicio['valor'])}'),
            Text('Fecha: ${formatoFecha.format(fecha)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Servicios'),
        actions: [
          if (_esAdmin)
            IconButton(
              icon: const Icon(Icons.restore_from_trash_outlined),
              tooltip: 'Papelera',
              onPressed: _abrirPapelera,
            ),
          if (_servicios.isNotEmpty)
            _exportando
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      height: 18,
                      width: 18,
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
                        child: Row(
                          children: [
                            Icon(Icons.grid_on, size: 20),
                            SizedBox(width: 8),
                            Text('Excel (.xlsx)'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _FormatoExport.pdf,
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('PDF'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _FormatoExport.docx,
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Word (.docx)'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _FormatoExport.csv,
                        child: Row(
                          children: [
                            Icon(Icons.table_rows_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('CSV'),
                          ],
                        ),
                      ),
                    ],
                  ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _cargarServicios(reset: true),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: TextField(
                            controller: _buscarController,
                            decoration: const InputDecoration(
                              labelText: 'Buscar por Empresa, Persona o Tipo',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: _onBuscarChanged,
                          ),
                        ),
                        if (_empresasClientes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: SizedBox(
                              height: 34,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: const Text('Todas'),
                                      selected: _empresaFiltro == null,
                                      onSelected: (_) => _seleccionarEmpresaFiltro(null),
                                    ),
                                  ),
                                  for (final empresaCliente in _empresasClientes)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        avatar: CircleAvatar(
                                          backgroundColor: colorParaEmpresaCliente(empresaCliente),
                                          radius: 6,
                                        ),
                                        label: Text(empresaCliente),
                                        selected: _empresaFiltro == empresaCliente,
                                        onSelected: (_) => _seleccionarEmpresaFiltro(
                                          _empresaFiltro == empresaCliente ? null : empresaCliente,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: _servicios.isEmpty
                              ? const Center(
                                  child: Text('No hay servicios registrados'),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _servicios.length + (_hayMas ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _servicios.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 20),
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    }

                                    final servicio = _servicios[index];
                                    final servicioId = servicio['id'];

                                    return Dismissible(
                                      key: Key(servicioId.toString()),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) => _confirmarEliminacion(servicio),
                                      onDismissed: (direction) {
                                        _eliminarServicio(Map<String, dynamic>.from(servicio as Map));
                                      },
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      child: Card(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            radius: 6,
                                            backgroundColor: colorParaEmpresaCliente(servicio['empresa']),
                                          ),
                                          title: Text(servicio['empresa'] ?? 'Sin empresa'),
                                          subtitle: Text(
                                            '${servicio['quien'] ?? 'N/A'} - ${servicio['tipo'] ?? 'N/A'}',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                CurrencyFormatter.formatCLP(servicio['valor']),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                tooltip: 'Editar',
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () async {
                                                  final recargar = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => RegistroServicioScreen(
                                                        servicioEditar: servicio,
                                                      ),
                                                    ),
                                                  );
                                                  if (recargar == true) {
                                                    _cargarServicios(reset: true);
                                                  }
                                                },
                                              ),
                                              // En el computador deslizar no se descubre:
                                              // el botón hace lo mismo (confirmar y luego Deshacer).
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                tooltip: 'Eliminar',
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () async {
                                                  if (await _confirmarEliminacion(servicio)) {
                                                    _eliminarServicio(Map<String, dynamic>.from(servicio as Map));
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          onTap: () => _mostrarDetalle(servicio),
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
    );
  }
}
