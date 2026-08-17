import 'dart:convert';
import 'package:archive/archive.dart';
import 'file_downloader.dart';
import 'servicio_grouping.dart';

/// Anchos de columna en dxa (1440 dxa = 1 pulgada): Fecha, Quién, Tipo,
/// Valor (la empresa ahora es el encabezado de cada sección, no una
/// columna). Suman ~5.3", cómodo dentro de una hoja carta/A4.
const List<int> _anchosColumnas = [1600, 2200, 2200, 1600];

/// Genera un .docx mínimo (sin depender de una plantilla) con el
/// historial de servicios agrupado por empresa cliente (encabezado de
/// sección + tabla + subtotal por cada una, y total general al final),
/// y dispara su descarga.
///
/// Un .docx es, por dentro, un .zip con archivos XML en rutas fijas que
/// exige el estándar OOXML de Word. Se arma esa estructura a mano con el
/// paquete `archive` en vez de depender de una plantilla binaria.
void exportarDocxServicios(String nombreArchivo, List<dynamic> servicios) {
  final totalGeneral = servicios.fold<int>(0, (sum, s) => sum + ((s['valor'] as num?)?.toInt() ?? 0));
  final grupos = agruparServiciosPorEmpresa(servicios);
  final secciones = StringBuffer();

  for (final grupo in grupos.entries) {
    secciones.write(_seccionEmpresa(grupo.key, grupo.value));
  }

  final documentoXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>Historial de Servicios</w:t></w:r></w:p>
    <w:p/>
    $secciones
    <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>Total general: ${_formatearValor(totalGeneral)}</w:t></w:r></w:p>
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

String _seccionEmpresa(String empresa, List<dynamic> filas) {
  final totalEmpresa = filas.fold<int>(0, (sum, s) => sum + ((s['valor'] as num?)?.toInt() ?? 0));
  final gridCols = _anchosColumnas.map((w) => '<w:gridCol w:w="$w"/>').join();
  final filasTabla = StringBuffer();

  for (final s in filas) {
    final m = s as Map;
    final valor = (m['valor'] as num?)?.toInt() ?? 0;
    filasTabla.write(_filaTabla([
      m['fecha']?.toString() ?? '',
      m['quien']?.toString() ?? '',
      m['tipo']?.toString() ?? '',
      _formatearValor(valor),
    ]));
  }

  return '''
    <w:p><w:pPr><w:shd w:val="clear" w:color="auto" w:fill="D9E2FF"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t xml:space="preserve">${_escaparXml(empresa)} · ${filas.length} servicio(s)</w:t></w:r></w:p>
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
      ${_filaTabla(['Fecha', 'Quién', 'Tipo', 'Valor'], encabezado: true, fill: 'F2F4FA')}
      $filasTabla
    </w:tbl>
    <w:p><w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:rPr><w:b/></w:rPr><w:t xml:space="preserve">Subtotal ${_escaparXml(empresa)}: ${_formatearValor(totalEmpresa)}</w:t></w:r></w:p>
    <w:p/>
''';
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
  bool encabezado = false,
  String? fill,
  bool letraBlanca = false,
}) {
  final buffer = StringBuffer('<w:tr>');
  for (var i = 0; i < celdas.length; i++) {
    final contenido = _escaparXml(celdas[i]);
    final negrita = encabezado ? '<w:b/>' : '';
    final colorLetra = letraBlanca ? '<w:color w:val="FFFFFF"/>' : '';
    final sombreado = fill != null ? '<w:shd w:val="clear" w:color="auto" w:fill="$fill"/>' : '';
    final ancho = _anchosColumnas[i];
    buffer.write(
      '<w:tc>'
      '<w:tcPr><w:tcW w:w="$ancho" w:type="dxa"/>$sombreado</w:tcPr>'
      '<w:p><w:r><w:rPr>$negrita$colorLetra</w:rPr><w:t xml:space="preserve">$contenido</w:t></w:r></w:p>'
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
