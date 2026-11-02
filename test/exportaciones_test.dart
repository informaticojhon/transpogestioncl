import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:transporte_app/models/remuneracion.dart';
import 'package:transporte_app/utils/docx_exporter.dart';
import 'package:transporte_app/utils/excel_exporter.dart';
import 'package:transporte_app/utils/fecha_reporte.dart';
import 'package:transporte_app/utils/pdf_exporter.dart';

/// Servicios desordenados a propósito (por fecha y por empresa), como
/// pueden llegar al exportar.
final _servicios = [
  {'id': 1, 'fecha': '2026-09-16', 'empresa': 'SERVOMAR', 'quien': 'Jhon', 'tipo': 'Pasaje', 'valor': 15000},
  {'id': 2, 'fecha': '2026-10-28', 'empresa': 'Austral', 'quien': 'Jhon', 'tipo': 'Carga', 'valor': 20000},
  {'id': 3, 'fecha': '2026-10-09', 'empresa': 'SERVOMAR', 'quien': 'Jhon', 'tipo': 'Pasaje', 'valor': 10000},
  {'id': 4, 'fecha': '2026-10-16', 'empresa': 'Austral', 'quien': 'Jhon', 'tipo': 'Carga', 'valor': 5000},
];
const _fechasEsperadas = ['28-10-2026', '16-10-2026', '09-10-2026', '16-09-2026'];

void main() {
  setUpAll(() => initializeDateFormatting('es_CL'));

  group('fechaReporte', () {
    test('formatea texto de la base de datos y DateTime como dd-mm-aaaa', () {
      expect(fechaReporte('2026-10-28'), '28-10-2026');
      expect(fechaReporte(DateTime(2026, 9, 5)), '05-09-2026');
    });

    test('deja tal cual un texto que no es fecha', () {
      expect(fechaReporte('sin fecha'), 'sin fecha');
      expect(fechaReporte(null), '');
    });
  });

  test('Excel: fechas reales, todas con el mismo formato, de la más reciente a la más antigua', () {
    final hoja = Excel.decodeBytes(construirExcelServicios(_servicios)!)['Servicios'];
    final celdas = [for (var fila = 1; fila <= 4; fila++) hoja.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: fila))];

    for (final celda in celdas) {
      expect(celda.value, isA<DateCellValue>());
      expect(celda.cellStyle?.numberFormat.formatCode, 'dd-mm-yyyy');
    }
    expect(
      celdas.map((c) => fechaReporte((c.value as DateCellValue).asDateTimeLocal())),
      _fechasEsperadas,
    );
  });

  test('Word: tabla en orden de fecha descendente con formato dd-mm-aaaa', () {
    final zip = ZipDecoder().decodeBytes(construirDocxServicios(_servicios)!);
    final xml = utf8.decode(zip.findFile('word/document.xml')!.content as List<int>);

    final posiciones = _fechasEsperadas.map(xml.indexOf).toList();
    expect(posiciones.every((p) => p >= 0), isTrue, reason: 'faltan fechas en el documento');
    expect(posiciones, [...posiciones]..sort(), reason: 'las fechas no están de la más reciente a la más antigua');
    expect(xml, isNot(contains('2026-10-28')));
    expect(xml, contains('Resumen por empresa'));
  });

  test('PDF de servicios y remuneraciones se generan sin errores', () async {
    expect(await construirPdfServicios(_servicios), isNotEmpty);
    expect(
      await construirPdfRemuneraciones([
        RemuneracionConTrabajador(
          nombreTrabajador: 'Ana',
          remuneracion: Remuneracion(trabajadorId: 1, fechaPago: DateTime(2026, 10, 30), monto: 500000, periodo: '2026-10'),
        ),
      ]),
      isNotEmpty,
    );
  });
}
