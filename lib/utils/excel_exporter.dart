import 'package:excel/excel.dart';
import 'file_downloader.dart';

/// Genera un .xlsx con el historial de servicios: encabezado en negrita
/// con fondo de color, columnas con ancho ajustado a su contenido, bordes
/// en toda la tabla, montos con separador de miles, y fila de total.
void exportarExcelServicios(String nombreArchivo, List<dynamic> servicios) {
  final libro = Excel.createExcel();
  const nombreHoja = 'Servicios';
  final hoja = libro[nombreHoja];

  // Excel.createExcel() trae una hoja "Sheet1" por defecto; se elimina
  // una vez que ya existe otra hoja, porque no se puede borrar la última.
  for (final nombre in List<String>.from(libro.sheets.keys)) {
    if (nombre != nombreHoja) libro.delete(nombre);
  }

  final bordeFino = Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#B0B0B0'));
  CellStyle conBorde({bool bold = false, ExcelColor? fondo, ExcelColor? letra, NumFormat? formato}) {
    return CellStyle(
      bold: bold,
      backgroundColorHex: fondo ?? ExcelColor.none,
      fontColorHex: letra ?? ExcelColor.black,
      leftBorder: bordeFino,
      rightBorder: bordeFino,
      topBorder: bordeFino,
      bottomBorder: bordeFino,
      numberFormat: formato ?? NumFormat.standard_0,
    );
  }

  final estiloEncabezado = conBorde(
    bold: true,
    fondo: ExcelColor.fromHexString('#2454FF'),
    letra: ExcelColor.white,
  );
  final estiloCelda = conBorde();
  final estiloCeldaNumero = conBorde(formato: NumFormat.standard_3); // "#,##0"
  final estiloTotal = conBorde(bold: true, fondo: ExcelColor.fromHexString('#EAEFFF'));
  final estiloTotalNumero = conBorde(bold: true, fondo: ExcelColor.fromHexString('#EAEFFF'), formato: NumFormat.standard_3);

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

    final textos = [
      s['fecha']?.toString() ?? '',
      s['empresa']?.toString() ?? '',
      s['quien']?.toString() ?? '',
      s['tipo']?.toString() ?? '',
    ];
    for (var col = 0; col < textos.length; col++) {
      hoja.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: filaExcel))
        ..value = TextCellValue(textos[col])
        ..cellStyle = estiloCelda;
    }
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: filaExcel))
      ..value = IntCellValue(valor)
      ..cellStyle = estiloCeldaNumero;
  }

  final filaTotal = servicios.length + 1;
  for (var col = 0; col < 3; col++) {
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: filaTotal))
      ..value = TextCellValue('')
      ..cellStyle = estiloTotal;
  }
  hoja.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: filaTotal))
    ..value = TextCellValue('Total')
    ..cellStyle = estiloTotal;
  hoja.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: filaTotal))
    ..value = IntCellValue(totalGeneral)
    ..cellStyle = estiloTotalNumero;

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
