import 'dart:convert';
import 'package:archive/archive.dart';
import 'file_downloader.dart';

/// Genera un .docx mínimo (sin depender de una plantilla) con una tabla
/// del historial de servicios, y dispara su descarga.
///
/// Un .docx es, por dentro, un .zip con archivos XML en rutas fijas que
/// exige el estándar OOXML de Word. Se arma esa estructura a mano con el
/// paquete `archive` en vez de depender de una plantilla binaria.
void exportarDocxServicios(String nombreArchivo, List<dynamic> servicios) {
  var totalGeneral = 0;
  final filasTabla = StringBuffer();

  for (final s in servicios) {
    final m = s as Map;
    final valor = (m['valor'] as num?)?.toInt() ?? 0;
    totalGeneral += valor;
    filasTabla.write(_filaTabla([
      m['fecha']?.toString() ?? '',
      m['empresa']?.toString() ?? '',
      m['quien']?.toString() ?? '',
      m['tipo']?.toString() ?? '',
      _formatearValor(valor),
    ]));
  }

  final documentoXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>Historial de Servicios</w:t></w:r></w:p>
    <w:p/>
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="0" w:type="auto"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="4" w:space="0" w:color="999999"/>
          <w:left w:val="single" w:sz="4" w:space="0" w:color="999999"/>
          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="999999"/>
          <w:right w:val="single" w:sz="4" w:space="0" w:color="999999"/>
          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="999999"/>
          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="999999"/>
        </w:tblBorders>
      </w:tblPr>
      ${_filaTabla(['Fecha', 'Empresa', 'Quién', 'Tipo', 'Valor'], encabezado: true)}
      $filasTabla
      ${_filaTabla(['', '', '', 'Total', _formatearValor(totalGeneral)], encabezado: true)}
    </w:tbl>
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

  final bytes = ZipEncoder().encode(archivo);
  if (bytes == null) return;

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

String _filaTabla(List<String> celdas, {bool encabezado = false}) {
  final buffer = StringBuffer('<w:tr>');
  for (final texto in celdas) {
    final contenido = _escaparXml(texto);
    final negrita = encabezado ? '<w:b/>' : '';
    buffer.write('<w:tc><w:p><w:r><w:rPr>$negrita</w:rPr><w:t xml:space="preserve">$contenido</w:t></w:r></w:p></w:tc>');
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
