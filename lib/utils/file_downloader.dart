import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

/// Dispara la descarga de [bytes] en el navegador con el nombre y tipo
/// de archivo indicados.
void descargarArchivo(String nombreArchivo, List<int> bytes, String mimeType) {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', nombreArchivo)
    ..click();
  html.Url.revokeObjectUrl(url);
}
