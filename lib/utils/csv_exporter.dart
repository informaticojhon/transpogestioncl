import 'dart:convert';
import 'package:universal_html/html.dart' as html;

/// Genera un CSV a partir de [filas] (la primera fila debe ser el
/// encabezado) y dispara su descarga en el navegador.
void exportarCsv(String nombreArchivo, List<List<dynamic>> filas) {
  final buffer = StringBuffer();
  for (final fila in filas) {
    buffer.writeln(fila.map(_escaparCampo).join(','));
  }

  // BOM al inicio para que Excel detecte UTF-8 y no rompa las tildes/ñ.
  final bytes = utf8.encode('﻿${buffer.toString()}');
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', nombreArchivo)
    ..click();
  html.Url.revokeObjectUrl(url);
}

String _escaparCampo(dynamic valor) {
  final texto = valor?.toString() ?? '';
  if (texto.contains(',') || texto.contains('"') || texto.contains('\n')) {
    return '"${texto.replaceAll('"', '""')}"';
  }
  return texto;
}
