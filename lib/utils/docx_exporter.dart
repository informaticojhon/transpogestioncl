import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import '../models/remuneracion.dart';
import 'fecha_reporte.dart';
import 'file_downloader.dart';
import 'remuneracion_grouping.dart';
import 'servicio_grouping.dart';

/// Genera un .docx mínimo (sin depender de una plantilla) con el
/// historial de servicios con el mismo orden que el Excel: una tabla con
/// todos los servicios del más reciente al más antiguo, total general, y
/// debajo un resumen con la cantidad y el subtotal de cada empresa.
///
/// Un .docx es, por dentro, un .zip con archivos XML en rutas fijas que
/// exige el estándar OOXML de Word. Se arma esa estructura a mano con el
/// paquete `archive` en vez de depender de una plantilla binaria.
void exportarDocxServicios(String nombreArchivo, List<dynamic> servicios) {
  final bytes = construirDocxServicios(servicios);
  if (bytes != null) _descargarDocx(nombreArchivo, bytes);
}

/// Arma el .docx del historial de servicios (sin descargarlo).
List<int>? construirDocxServicios(List<dynamic> servicios) {
  final ordenados = ordenarServiciosPorFechaDesc(servicios);
  int valorDe(dynamic s) => (s['valor'] as num?)?.toInt() ?? 0;
  final totalGeneral = ordenados.fold<int>(0, (sum, s) => sum + valorDe(s));

  // Anchos en dxa (1440 dxa = 1 pulgada); suman ~6.0", dentro de carta/A4.
  final cuerpo = StringBuffer()
    ..write(_titulo('Historial de Servicios'))
    ..write(_tabla(
      encabezados: ['Fecha', 'Empresa', 'Quién', 'Tipo', 'Valor'],
      anchos: [1400, 2300, 2000, 1500, 1500],
      filas: [
        for (final s in ordenados)
          [
            fechaReporte(s['fecha']),
            s['empresa']?.toString() ?? '',
            s['quien']?.toString() ?? '',
            s['tipo']?.toString() ?? '',
            _formatearValor(valorDe(s)),
          ],
      ],
    ))
    ..write(_totalGeneral(totalGeneral))
    ..write(_subtitulo('Resumen por empresa'))
    ..write(_tabla(
      encabezados: ['Empresa', 'Servicios', 'Subtotal'],
      anchos: [4000, 1500, 2000],
      filas: [
        for (final grupo in agruparServiciosPorEmpresa(ordenados).entries)
          [
            grupo.key,
            '${grupo.value.length}',
            _formatearValor(grupo.value.fold<int>(0, (sum, s) => sum + valorDe(s))),
          ],
      ],
    ));

  return _empaquetarDocx(cuerpo.toString());
}

/// Genera un .docx con el reporte de remuneraciones: todos los pagos del
/// más reciente al más antiguo, total general y un resumen por
/// trabajador al final (mismo formato que el de servicios).
void exportarDocxRemuneraciones(String nombreArchivo, List<RemuneracionConTrabajador> remuneraciones) {
  final bytes = construirDocxRemuneraciones(remuneraciones);
  if (bytes != null) _descargarDocx(nombreArchivo, bytes);
}

/// Arma el .docx del reporte de remuneraciones (sin descargarlo).
List<int>? construirDocxRemuneraciones(List<RemuneracionConTrabajador> remuneraciones) {
  final ordenadas = ordenarRemuneracionesPorFechaDesc(remuneraciones);
  final totalGeneral = ordenadas.fold<int>(0, (sum, r) => sum + r.remuneracion.monto);

  final cuerpo = StringBuffer()
    ..write(_titulo('Reporte de Remuneraciones'))
    ..write(_tabla(
      encabezados: ['Fecha de pago', 'Trabajador', 'Periodo', 'Concepto', 'Monto'],
      anchos: [1500, 2100, 1300, 2200, 1500],
      filas: [
        for (final item in ordenadas)
          [
            fechaReporte(item.remuneracion.fechaPago),
            item.nombreTrabajador,
            item.remuneracion.periodo,
            item.remuneracion.concepto ?? '',
            _formatearValor(item.remuneracion.monto),
          ],
      ],
    ))
    ..write(_totalGeneral(totalGeneral))
    ..write(_subtitulo('Resumen por trabajador'))
    ..write(_tabla(
      encabezados: ['Trabajador', 'Pagos', 'Subtotal'],
      anchos: [4000, 1500, 2000],
      filas: [
        for (final grupo in agruparRemuneracionesPorTrabajador(ordenadas).entries)
          [
            grupo.key,
            '${grupo.value.length}',
            _formatearValor(grupo.value.fold<int>(0, (sum, r) => sum + r.remuneracion.monto)),
          ],
      ],
    ));

  return _empaquetarDocx(cuerpo.toString());
}

String _titulo(String titulo) {
  final generado = DateFormat('dd-MM-yyyy').format(DateTime.now());
  return '''
    <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>${_escaparXml(titulo)}</w:t></w:r></w:p>
    <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:color w:val="666666"/><w:sz w:val="18"/></w:rPr><w:t>Generado el $generado</w:t></w:r></w:p>
    <w:p/>
''';
}

String _subtitulo(String texto) => '''
    <w:p/>
    <w:p><w:pPr><w:shd w:val="clear" w:color="auto" w:fill="D9E2FF"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t xml:space="preserve">${_escaparXml(texto)}</w:t></w:r></w:p>
''';

String _totalGeneral(int total) => '''
    <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>Total general: ${_formatearValor(total)}</w:t></w:r></w:p>
''';

/// Tabla con bordes y encabezado sombreado; la última columna (montos)
/// va alineada a la derecha.
String _tabla({required List<String> encabezados, required List<int> anchos, required List<List<String>> filas}) {
  final gridCols = anchos.map((w) => '<w:gridCol w:w="$w"/>').join();
  final filasTabla = StringBuffer();
  for (final fila in filas) {
    filasTabla.write(_filaTabla(fila, anchos: anchos));
  }
  return '''
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="0" w:type="auto"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="4" w:space="0" w:color="B0B0B0"/>
          <w:left w:val="single" w:sz="4" w:space="0" w:color="B0B0B0"/>
          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="B0B0B0"/>
          <w:right w:val="single" w:sz="4" w:space="0" w:color="B0B0B0"/>
          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="B0B0B0"/>
          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="B0B0B0"/>
        </w:tblBorders>
        <w:tblCellMar>
          <w:top w:w="80" w:type="dxa"/>
          <w:bottom w:w="80" w:type="dxa"/>
          <w:left w:w="120" w:type="dxa"/>
          <w:right w:w="120" w:type="dxa"/>
        </w:tblCellMar>
      </w:tblPr>
      <w:tblGrid>$gridCols</w:tblGrid>
      ${_filaTabla(encabezados, encabezado: true, fill: 'F2F4FA', anchos: anchos)}
      $filasTabla
    </w:tbl>
''';
}

List<int>? _empaquetarDocx(String cuerpo) {
  final documentoXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
$cuerpo
    <w:sectPr/>
  </w:body>
</w:document>
''';

  const contentTypesXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
''';

  const relsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
''';

  final archivo = Archive();
  _agregarArchivoTexto(archivo, '[Content_Types].xml', contentTypesXml);
  _agregarArchivoTexto(archivo, '_rels/.rels', relsXml);
  _agregarArchivoTexto(archivo, 'word/document.xml', documentoXml);
  return ZipEncoder().encode(archivo);
}

void _descargarDocx(String nombreArchivo, List<int> bytes) {
  descargarArchivo(
    nombreArchivo,
    bytes,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  );
}

void _agregarArchivoTexto(Archive archivo, String ruta, String contenido) {
  final bytes = utf8.encode(contenido);
  archivo.addFile(ArchiveFile(ruta, bytes.length, bytes));
}

String _formatearValor(int valor) {
  final texto = valor.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
    buffer.write(texto[i]);
  }
  return '\$$buffer';
}

String _filaTabla(
  List<String> celdas, {
  required List<int> anchos,
  bool encabezado = false,
  String? fill,
}) {
  final buffer = StringBuffer('<w:tr>');
  for (var i = 0; i < celdas.length; i++) {
    final contenido = _escaparXml(celdas[i]);
    final negrita = encabezado ? '<w:b/>' : '';
    final sombreado = fill != null ? '<w:shd w:val="clear" w:color="auto" w:fill="$fill"/>' : '';
    final alineacion = i == celdas.length - 1 ? '<w:pPr><w:jc w:val="right"/></w:pPr>' : '';
    buffer.write(
      '<w:tc>'
      '<w:tcPr><w:tcW w:w="${anchos[i]}" w:type="dxa"/>$sombreado</w:tcPr>'
      '<w:p>$alineacion<w:r><w:rPr>$negrita</w:rPr><w:t xml:space="preserve">$contenido</w:t></w:r></w:p>'
      '</w:tc>',
    );
  }
  buffer.write('</w:tr>');
  return buffer.toString();
}

String _escaparXml(String texto) {
  return texto
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
