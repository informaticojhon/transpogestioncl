import 'dart:convert';
import 'file_downloader.dart';

/// Genera un CSV a partir de [filas] (la primera fila debe ser el
/// encabezado) y dispara su descarga en el navegador.
///
/// Usa ';' como separador (no ',') porque en configuración regional
/// chilena/hispana, Excel abre un .csv de doble clic usando el separador
/// de listas del sistema, que en esa configuración es ';' — con coma,
/// Excel no separa en columnas y todo aparece amontonado en una sola.
void exportarCsv(String nombreArchivo, List<List<dynamic>> filas) {
  final buffer = StringBuffer();
  for (final fila in filas) {
    buffer.writeln(fila.map(_escaparCampo).join(';'));
  }

  // BOM al inicio para que Excel detecte UTF-8 y no rompa las tildes/ñ.
  final bytes = utf8.encode('﻿${buffer.toString()}');
  descargarArchivo(nombreArchivo, bytes, 'text/csv;charset=utf-8');
}

String _escaparCampo(dynamic valor) {
  final texto = valor?.toString() ?? '';
  if (texto.contains(';') || texto.contains('"') || texto.contains('\n')) {
    return '"${texto.replaceAll('"', '""')}"';
  }
  return texto;
}
