import 'package:intl/intl.dart';

final _formatoFechaReporte = DateFormat('dd-MM-yyyy');

/// Fecha con el formato que usan todas las exportaciones (dd-mm-aaaa),
/// para que Excel, PDF, Word y CSV muestren lo mismo. Acepta un
/// [DateTime] o el texto "YYYY-MM-DD" que guarda la base de datos; si no
/// se puede interpretar, devuelve el texto tal cual para no perder el dato.
String fechaReporte(Object? valor) {
  if (valor is DateTime) return _formatoFechaReporte.format(valor);
  final texto = valor?.toString() ?? '';
  final fecha = DateTime.tryParse(texto);
  return fecha != null ? _formatoFechaReporte.format(fecha) : texto;
}
