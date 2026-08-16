import 'package:excel/excel.dart';
import 'file_downloader.dart';

/// Genera un .xlsx con el historial de servicios (encabezado en negrita,
/// columnas con ancho ajustado, monto como número) y dispara su descarga.
void exportarExcelServicios(String nombreArchivo, List<dynamic> servicios) {
  final libro = Excel.createExcel();
  const nombreHoja = 'Servicios';
  final hoja = libro[nombreHoja];

  // Excel.createExcel() trae una hoja "Sheet1" por defecto; se elimina
  // una vez que ya existe otra hoja, porque no se puede borrar la última.
  for (final nombre in List<String>.from(libro.sheets.keys)) {
    if (nombre != nombreHoja) libro.delete(nombre);
  }

  final estiloEncabezado = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('#2454FF'),
    horizontalAlign: HorizontalAlign.Center,
  );

  const encabezados = ['Fecha', 'Empresa', 'Quién', 'Tipo', 'Valor (CLP)'];
  for (var col = 0; col < encabezados.length; col++) {
    final celda = hoja.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
    celda.value = TextCellValue(encabezados[col]);
    celda.cellStyle = estiloEncabezado;
  }

  var totalGeneral = 0;
  for (var fila = 0; fila < servicios.length; fila++) {
    final s = servicios[fila] as Map;
    final valor = (s['valor'] as num?)?.toInt() ?? 0;
    totalGeneral += valor;
    final filaExcel = fila + 1;

    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaExcel)).value =
        TextCellValue(s['fecha']?.toString() ?? '');
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaExcel)).value =
        TextCellValue(s['empresa']?.toString() ?? '');
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: filaExcel)).value =
        TextCellValue(s['quien']?.toString() ?? '');
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: filaExcel)).value =
        TextCellValue(s['tipo']?.toString() ?? '');
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: filaExcel)).value =
        IntCellValue(valor);
  }

  final filaTotal = servicios.length + 1;
  final estiloTotal = CellStyle(bold: true);
  hoja.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: filaTotal))
    ..value = TextCellValue('Total')
    ..cellStyle = estiloTotal;
  hoja.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: filaTotal))
    ..value = IntCellValue(totalGeneral)
    ..cellStyle = estiloTotal;

  hoja.setColumnWidth(0, 14);
  hoja.setColumnWidth(1, 24);
  hoja.setColumnWidth(2, 20);
  hoja.setColumnWidth(3, 20);
  hoja.setColumnWidth(4, 16);

  final bytes = libro.encode();
  if (bytes == null) return;

  descargarArchivo(
    nombreArchivo,
    bytes,
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
}
