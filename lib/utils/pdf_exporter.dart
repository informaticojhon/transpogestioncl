import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/remuneracion.dart';
import 'currency_formatter.dart';
import 'fecha_reporte.dart';
import 'remuneracion_grouping.dart';
import 'servicio_grouping.dart';

/// Genera un PDF con el historial de servicios con el mismo orden que el
/// Excel: una tabla con todos los servicios del más reciente al más
/// antiguo, total general, y debajo un resumen con la cantidad y el
/// subtotal de cada empresa cliente. Dispara su descarga/impresión
/// (mismo mecanismo que Reporte Diario/Mensual).
Future<void> exportarPdfServicios(String nombreArchivo, List<dynamic> servicios) async {
  final bytes = await construirPdfServicios(servicios);
  await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
}

/// Arma el PDF del historial de servicios (sin descargarlo).
Future<Uint8List> construirPdfServicios(List<dynamic> servicios) async {
  final ordenados = ordenarServiciosPorFechaDesc(servicios);
  int valorDe(dynamic s) => (s['valor'] as num?)?.toInt() ?? 0;
  final totalGeneral = ordenados.fold<int>(0, (sum, s) => sum + valorDe(s));

  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        ..._titulo('Historial de Servicios'),
        _tabla(
          encabezados: ['Fecha', 'Empresa', 'Quién', 'Tipo', 'Valor'],
          anchos: [1.1, 1.6, 1.5, 1.1, 1.1],
          filas: [
            for (final s in ordenados)
              [
                fechaReporte(s['fecha']),
                s['empresa']?.toString() ?? '',
                s['quien']?.toString() ?? '',
                s['tipo']?.toString() ?? '',
                CurrencyFormatter.formatCLP(s['valor']),
              ],
          ],
        ),
        _totalGeneral(totalGeneral),
        pw.SizedBox(height: 20),
        _subtitulo('Resumen por empresa'),
        _tabla(
          encabezados: ['Empresa', 'Servicios', 'Subtotal'],
          anchos: [2.4, 1, 1.4],
          filas: [
            for (final grupo in agruparServiciosPorEmpresa(ordenados).entries)
              [
                grupo.key,
                '${grupo.value.length}',
                CurrencyFormatter.formatCLP(grupo.value.fold<int>(0, (sum, s) => sum + valorDe(s))),
              ],
          ],
        ),
      ],
    ),
  );
  return pdf.save();
}

/// Genera un PDF con el reporte de remuneraciones: todos los pagos del
/// más reciente al más antiguo, total general y un resumen por
/// trabajador al final (mismo formato que el de servicios).
Future<void> exportarPdfRemuneraciones(String nombreArchivo, List<RemuneracionConTrabajador> remuneraciones) async {
  final bytes = await construirPdfRemuneraciones(remuneraciones);
  await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
}

/// Arma el PDF del reporte de remuneraciones (sin descargarlo).
Future<Uint8List> construirPdfRemuneraciones(List<RemuneracionConTrabajador> remuneraciones) async {
  final ordenadas = ordenarRemuneracionesPorFechaDesc(remuneraciones);
  final totalGeneral = ordenadas.fold<int>(0, (sum, r) => sum + r.remuneracion.monto);

  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        ..._titulo('Reporte de Remuneraciones'),
        _tabla(
          encabezados: ['Fecha de pago', 'Trabajador', 'Periodo', 'Concepto', 'Monto'],
          anchos: [1.2, 1.6, 1, 1.6, 1.1],
          filas: [
            for (final item in ordenadas)
              [
                fechaReporte(item.remuneracion.fechaPago),
                item.nombreTrabajador,
                item.remuneracion.periodo,
                item.remuneracion.concepto ?? '',
                CurrencyFormatter.formatCLP(item.remuneracion.monto),
              ],
          ],
        ),
        _totalGeneral(totalGeneral),
        pw.SizedBox(height: 20),
        _subtitulo('Resumen por trabajador'),
        _tabla(
          encabezados: ['Trabajador', 'Pagos', 'Subtotal'],
          anchos: [2.4, 1, 1.4],
          filas: [
            for (final grupo in agruparRemuneracionesPorTrabajador(ordenadas).entries)
              [
                grupo.key,
                '${grupo.value.length}',
                CurrencyFormatter.formatCLP(grupo.value.fold<int>(0, (sum, r) => sum + r.remuneracion.monto)),
              ],
          ],
        ),
      ],
    ),
  );
  return pdf.save();
}

List<pw.Widget> _titulo(String titulo) => [
      pw.Text(titulo, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
      pw.Text(
        'Generado el ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 16),
    ];

pw.Widget _subtitulo(String texto) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: PdfColors.blue100,
      child: pw.Text(
        texto,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
    );

/// Tabla con encabezado gris; la última columna (montos) va alineada a
/// la derecha.
pw.Widget _tabla({
  required List<String> encabezados,
  required List<double> anchos,
  required List<List<String>> filas,
}) {
  final ultima = encabezados.length - 1;
  pw.Widget celda(String texto, int col, {bool negrita = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          texto,
          textAlign: col == ultima ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(fontSize: 10, fontWeight: negrita ? pw.FontWeight.bold : null),
        ),
      );

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400),
    columnWidths: {for (var i = 0; i < anchos.length; i++) i: pw.FlexColumnWidth(anchos[i])},
    children: [
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [for (var i = 0; i < encabezados.length; i++) celda(encabezados[i], i, negrita: true)],
      ),
      for (final fila in filas) pw.TableRow(children: [for (var i = 0; i < fila.length; i++) celda(fila[i], i)]),
    ],
  );
}

pw.Widget _totalGeneral(int total) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Total general: ${CurrencyFormatter.formatCLP(total)}',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
        ),
      ),
    );
