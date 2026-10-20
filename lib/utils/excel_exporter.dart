import 'package:excel/excel.dart';
import '../models/remuneracion.dart';
import 'file_downloader.dart';
import 'remuneracion_grouping.dart';
import 'servicio_grouping.dart';

/// Genera un .xlsx con el historial de servicios: una tabla con todos los
/// registros ordenados por fecha, del más reciente al más antiguo (la
/// fecha queda como fecha real de Excel, así se puede filtrar y reordenar
/// desde el propio Excel), total general, y debajo un resumen con la
/// cantidad de servicios y el subtotal de cada empresa cliente.
void exportarExcelServicios(String nombreArchivo, List<dynamic> servicios) {
  final hoja = _HojaReporte('Servicios');
  final ordenados = ordenarServiciosPorFechaDesc(servicios);

  hoja.encabezado(['Fecha', 'Empresa', 'Quién', 'Tipo', 'Valor (CLP)']);

  var totalGeneral = 0;
  for (final s in ordenados) {
    final m = s as Map;
    final valor = (m['valor'] as num?)?.toInt() ?? 0;
    totalGeneral += valor;
    hoja.fila([
      _fecha(m['fecha']),
      TextCellValue(m['empresa']?.toString() ?? ''),
      TextCellValue(m['quien']?.toString() ?? ''),
      TextCellValue(m['tipo']?.toString() ?? ''),
      IntCellValue(valor),
    ]);
  }
  hoja.filaTotal('Total general', totalGeneral, columnas: 5);

  hoja.saltarFila();
  hoja.encabezado(['Empresa', 'Servicios', 'Subtotal (CLP)']);
  for (final grupo in agruparServiciosPorEmpresa(ordenados).entries) {
    final subtotal = grupo.value.fold<int>(0, (suma, s) => suma + ((s['valor'] as num?)?.toInt() ?? 0));
    hoja.fila([
      TextCellValue(grupo.key),
      IntCellValue(grupo.value.length),
      IntCellValue(subtotal),
    ]);
  }
  hoja.filaTotal('Total general', totalGeneral, columnas: 3);

  hoja.anchos([14, 24, 20, 22, 16]);
  hoja.descargar(nombreArchivo);
}

/// Genera un .xlsx con el reporte de remuneraciones: todos los pagos
/// ordenados por fecha de pago, del más reciente al más antiguo, total
/// general, y debajo un resumen con el subtotal de cada trabajador
/// (mismo formato que el de servicios).
void exportarExcelRemuneraciones(String nombreArchivo, List<RemuneracionConTrabajador> remuneraciones) {
  final hoja = _HojaReporte('Remuneraciones');
  final ordenadas = ordenarRemuneracionesPorFechaDesc(remuneraciones);

  hoja.encabezado(['Fecha de pago', 'Trabajador', 'Periodo', 'Concepto', 'Monto (CLP)']);

  var totalGeneral = 0;
  for (final item in ordenadas) {
    final r = item.remuneracion;
    totalGeneral += r.monto;
    hoja.fila([
      DateCellValue.fromDateTime(r.fechaPago),
      TextCellValue(item.nombreTrabajador),
      TextCellValue(r.periodo),
      TextCellValue(r.concepto ?? ''),
      IntCellValue(r.monto),
    ]);
  }
  hoja.filaTotal('Total general', totalGeneral, columnas: 5);

  hoja.saltarFila();
  hoja.encabezado(['Trabajador', 'Pagos', 'Subtotal (CLP)']);
  for (final grupo in agruparRemuneracionesPorTrabajador(ordenadas).entries) {
    final subtotal = grupo.value.fold<int>(0, (suma, item) => suma + item.remuneracion.monto);
    hoja.fila([
      TextCellValue(grupo.key),
      IntCellValue(grupo.value.length),
      IntCellValue(subtotal),
    ]);
  }
  hoja.filaTotal('Total general', totalGeneral, columnas: 3);

  hoja.anchos([14, 24, 14, 24, 16]);
  hoja.descargar(nombreArchivo);
}

/// "YYYY-MM-DD" → celda de fecha de Excel; si no se puede interpretar,
/// se deja el texto tal cual para no perder el dato.
CellValue _fecha(Object? valor) {
  final texto = valor?.toString() ?? '';
  final fecha = DateTime.tryParse(texto);
  return fecha != null ? DateCellValue.fromDateTime(fecha) : TextCellValue(texto);
}

/// Libro de una sola hoja que se va llenando fila por fila con el estilo
/// común de los reportes: encabezado en negrita con fondo de color,
/// bordes en todas las celdas, montos con separador de miles, fechas
/// dd-mm-aaaa y filas de total destacadas.
class _HojaReporte {
  final Excel _libro = Excel.createExcel();
  late final Sheet _hoja;
  int _filaActual = 0;

  _HojaReporte(String nombreHoja) {
    _hoja = _libro[nombreHoja];
    // Excel.createExcel() trae una hoja "Sheet1" por defecto; se elimina
    // una vez que ya existe otra hoja, porque no se puede borrar la última.
    for (final nombre in List<String>.from(_libro.sheets.keys)) {
      if (nombre != nombreHoja) _libro.delete(nombre);
    }
  }

  static final _bordeFino = Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#B0B0B0'));
  static const _formatoMiles = NumFormat.standard_3; // "#,##0"
  static const _formatoFecha = CustomDateTimeNumFormat(formatCode: 'dd-mm-yyyy');

  static CellStyle _estilo({bool bold = false, String? fondo, ExcelColor? letra, NumFormat? formato}) {
    return CellStyle(
      bold: bold,
      backgroundColorHex: fondo != null ? ExcelColor.fromHexString(fondo) : ExcelColor.none,
      fontColorHex: letra ?? ExcelColor.black,
      leftBorder: _bordeFino,
      rightBorder: _bordeFino,
      topBorder: _bordeFino,
      bottomBorder: _bordeFino,
      numberFormat: formato ?? NumFormat.standard_0,
    );
  }

  static final _estiloEncabezado = _estilo(bold: true, fondo: '#2454FF', letra: ExcelColor.white);
  static final _estiloTexto = _estilo();
  static final _estiloNumero = _estilo(formato: _formatoMiles);
  static final _estiloFecha = _estilo(formato: _formatoFecha);
  static final _estiloTotal = _estilo(bold: true, fondo: '#EAEFFF');
  static final _estiloTotalNumero = _estilo(bold: true, fondo: '#EAEFFF', formato: _formatoMiles);

  void _celda(int columna, CellValue valor, CellStyle estilo) {
    _hoja.cell(CellIndex.indexByColumnRow(columnIndex: columna, rowIndex: _filaActual))
      ..value = valor
      ..cellStyle = estilo;
  }

  void encabezado(List<String> titulos) {
    for (var col = 0; col < titulos.length; col++) {
      _celda(col, TextCellValue(titulos[col]), _estiloEncabezado);
    }
    _filaActual++;
  }

  void fila(List<CellValue> valores) {
    for (var col = 0; col < valores.length; col++) {
      final valor = valores[col];
      final estilo = switch (valor) {
        DateCellValue() => _estiloFecha,
        IntCellValue() => _estiloNumero,
        _ => _estiloTexto,
      };
      _celda(col, valor, estilo);
    }
    _filaActual++;
  }

  /// Fila de total: la etiqueta va en la penúltima columna y el monto en
  /// la última, con las celdas anteriores vacías pero con el mismo fondo.
  void filaTotal(String etiqueta, int monto, {required int columnas}) {
    for (var col = 0; col < columnas - 2; col++) {
      _celda(col, TextCellValue(''), _estiloTotal);
    }
    _celda(columnas - 2, TextCellValue(etiqueta), _estiloTotal);
    _celda(columnas - 1, IntCellValue(monto), _estiloTotalNumero);
    _filaActual++;
  }

  void saltarFila() => _filaActual++;

  void anchos(List<double> anchos) {
    for (var col = 0; col < anchos.length; col++) {
      _hoja.setColumnWidth(col, anchos[col]);
    }
  }

  void descargar(String nombreArchivo) {
    final bytes = _libro.encode();
    if (bytes == null) return;

    descargarArchivo(
      nombreArchivo,
      bytes,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }
}
