import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/remuneracion.dart';
import 'currency_formatter.dart';
import 'remuneracion_grouping.dart';
import 'servicio_grouping.dart';

/// Genera un PDF con el historial de servicios agrupado por empresa
/// cliente (encabezado de sección + tabla + subtotal por cada una, y
/// total general al final), y dispara su descarga/impartición (mismo
/// mecanismo que Reporte Diario/Mensual).
Future<void> exportarPdfServicios(String nombreArchivo, List<dynamic> servicios) async {
  final pdf = pw.Document();
  final formatoFecha = DateFormat('dd/MM/yyyy');
  final totalGeneral = servicios.fold<int>(0, (sum, s) => sum + ((s['valor'] as num?)?.toInt() ?? 0));
  final grupos = agruparServiciosPorEmpresa(servicios);

  pw.Widget tablaEmpresa(String empresa, List<dynamic> filas) {
    final totalEmpresa = filas.fold<int>(0, (sum, s) => sum + ((s['valor'] as num?)?.toInt() ?? 0));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: PdfColors.blue100,
          child: pw.Text(
            '$empresa  ·  ${filas.length} servicio(s)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(1.6),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                for (final titulo in ['Fecha', 'Quién', 'Tipo', 'Valor'])
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
              ],
            ),
            for (final s in filas)
              pw.TableRow(
                children: [
                  for (final valor in [
                    s['fecha']?.toString() ?? '',
                    s['quien']?.toString() ?? '',
                    s['tipo']?.toString() ?? '',
                    CurrencyFormatter.formatCLP(s['valor']),
                  ])
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(valor, style: const pw.TextStyle(fontSize: 10)),
                    ),
                ],
              ),
          ],
        ),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              'Subtotal $empresa: ${CurrencyFormatter.formatCLP(totalEmpresa)}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        pw.SizedBox(height: 14),
      ],
    );
  }

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text(
          'Historial de Servicios',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Generado el ${formatoFecha.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 16),
        for (final grupo in grupos.entries) tablaEmpresa(grupo.key, grupo.value),
        pw.Divider(),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total general: ${CurrencyFormatter.formatCLP(totalGeneral)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
          ),
        ),
      ],
    ),
  );

  final bytes = await pdf.save();
  await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
}

/// Genera un PDF con el reporte de remuneraciones agrupado por trabajador
/// (encabezado de sección + tabla + subtotal por cada uno, y total general
/// al final), con el mismo estilo visual que el de servicios.
Future<void> exportarPdfRemuneraciones(String nombreArchivo, List<RemuneracionConTrabajador> remuneraciones) async {
  final pdf = pw.Document();
  final formatoFecha = DateFormat('dd/MM/yyyy');
  final totalGeneral = remuneraciones.fold<int>(0, (sum, r) => sum + r.remuneracion.monto);
  final grupos = agruparRemuneracionesPorTrabajador(remuneraciones);

  pw.Widget tablaTrabajador(String trabajador, List<RemuneracionConTrabajador> filas) {
    final totalTrabajador = filas.fold<int>(0, (sum, r) => sum + r.remuneracion.monto);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: PdfColors.blue100,
          child: pw.Text(
            '$trabajador  ·  ${filas.length} pago(s)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(1.2),
            2: pw.FlexColumnWidth(1.8),
            3: pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                for (final titulo in ['Fecha de pago', 'Periodo', 'Concepto', 'Monto'])
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
              ],
            ),
            for (final item in filas)
              pw.TableRow(
                children: [
                  for (final valor in [
                    formatoFecha.format(item.remuneracion.fechaPago),
                    item.remuneracion.periodo,
                    item.remuneracion.concepto ?? '',
                    CurrencyFormatter.formatCLP(item.remuneracion.monto),
                  ])
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(valor, style: const pw.TextStyle(fontSize: 10)),
                    ),
                ],
              ),
          ],
        ),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              'Subtotal $trabajador: ${CurrencyFormatter.formatCLP(totalTrabajador)}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        pw.SizedBox(height: 14),
      ],
    );
  }

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text(
          'Reporte de Remuneraciones',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Generado el ${formatoFecha.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 16),
        for (final grupo in grupos.entries) tablaTrabajador(grupo.key, grupo.value),
        pw.Divider(),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total general: ${CurrencyFormatter.formatCLP(totalGeneral)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
          ),
        ),
      ],
    ),
  );

  final bytes = await pdf.save();
  await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
}
