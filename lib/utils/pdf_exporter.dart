import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'currency_formatter.dart';

/// Genera un PDF con la tabla del historial de servicios y dispara su
/// descarga/impartición (mismo mecanismo que Reporte Diario/Mensual).
Future<void> exportarPdfServicios(String nombreArchivo, List<dynamic> servicios) async {
  final pdf = pw.Document();
  final formatoFecha = DateFormat('dd/MM/yyyy');
  final totalGeneral = servicios.fold<int>(0, (sum, s) => sum + ((s['valor'] as num?)?.toInt() ?? 0));

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
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(1.6),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(1.4),
            4: pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: [
                for (final titulo in ['Fecha', 'Empresa', 'Quién', 'Tipo', 'Valor'])
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
              ],
            ),
            for (final s in servicios)
              pw.TableRow(
                children: [
                  for (final valor in [
                    s['fecha']?.toString() ?? '',
                    s['empresa']?.toString() ?? '',
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
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total: ${CurrencyFormatter.formatCLP(totalGeneral)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
          ),
        ),
      ],
    ),
  );

  final bytes = await pdf.save();
  await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
}
