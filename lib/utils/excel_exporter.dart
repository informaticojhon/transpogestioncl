import 'package:excel/excel.dart';
import 'file_downloader.dart';
import 'servicio_grouping.dart';

/// Genera un .xlsx con el historial de servicios, agrupado por empresa
/// cliente: encabezado en negrita con fondo de color, columnas con ancho
/// ajustado, bordes en toda la tabla, montos con separador de miles,
/// subtotal por empresa y total general al final.
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
  final estiloSubtotal = conBorde(bold: true, fondo: ExcelColor.fromHexString('#F2F4FA'));
  final estiloSubtotalNumero =
      conBorde(bold: true, fondo: ExcelColor.fromHexString('#F2F4FA'), formato: NumFormat.standard_3);
  final estiloTotal = conBorde(bold: true, fondo: ExcelColor.fromHexString('#EAEFFF'));
  final estiloTotalNumero = conBorde(bold: true, fondo: ExcelColor.fromHexString('#EAEFFF'), formato: NumFormat.standard_3);

  const encabezados = ['Fecha', 'Empresa', 'Quién', 'Tipo', 'Valor (CLP)'];
  for (var col = 0; col < encabezados.length; col++) {
    final celda = hoja.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
    celda.value = TextCellValue(encabezados[col]);
    celda.cellStyle = estiloEncabezado;
  }

  var filaExcel = 1;
  var totalGeneral = 0;
  final grupos = agruparServiciosPorEmpresa(servicios);

  for (final grupo in grupos.entries) {
    var totalEmpresa = 0;

    for (final s in grupo.value) {
      final m = s as Map;
      final valor = (m['valor'] as num?)?.toInt() ?? 0;
      totalEmpresa += valor;
      totalGeneral += valor;

      final textos = [
        m['fecha']?.toString() ?? '',
        m['empresa']?.toString() ?? '',
        m['quien']?.toString() ?? '',
        m['tipo']?.toString() ?? '',
      ];
      for (var col = 0; col < textos.length; col++) {
        hoja.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: filaExcel))
          ..value = TextCellValue(textos[col])
          ..cellStyle = estiloCelda;
      }
      hoja.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: filaExcel))
        ..value = IntCellValue(valor)
        ..cellStyle = estiloCeldaNumero;
      filaExcel++;
    }

    for (var col = 0; col < 3; col++) {
      hoja.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: filaExcel))
        ..value = TextCellValue('')
        ..cellStyle = estiloSubtotal;
    }
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: filaExcel))
      ..value = TextCellValue('Subtotal ${grupo.key}')
      ..cellStyle = estiloSubtotal;
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: filaExcel))
      ..value = IntCellValue(totalEmpresa)
      ..cellStyle = estiloSubtotalNumero;
    filaExcel++;
  }

  for (var col = 0; col < 3; col++) {
    hoja.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: filaExcel))
      ..value = TextCellValue('')
      ..cellStyle = estiloTotal;
  }
  hoja.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: filaExcel))
    ..value = TextCellValue('Total general')
    ..cellStyle = estiloTotal;
  hoja.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: filaExcel))
    ..value = IntCellValue(totalGeneral)
    ..cellStyle = estiloTotalNumero;

  hoja.setColumnWidth(0, 14);
  hoja.setColumnWidth(1, 24);
  hoja.setColumnWidth(2, 20);
  hoja.setColumnWidth(3, 22);
  hoja.setColumnWidth(4, 16);

  final bytes = libro.encode();
  if (bytes == null) return;

  descargarArchivo(
    nombreArchivo,
    bytes,
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
}
