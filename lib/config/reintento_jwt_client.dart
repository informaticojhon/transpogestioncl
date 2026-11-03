import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente HTTP para Supabase que reintenta las peticiones rechazadas con
/// "JWT issued at future" (PGRST303).
///
/// Pasa justo después de que Auth renueva la sesión: el token nuevo trae
/// una hora de emisión (iat) unos instantes por delante del reloj del
/// servidor de la API, que lo rechaza con 401. Es un desfase entre
/// servidores de Supabase, no del dispositivo, y un momento después el
/// mismo token ya se acepta.
class ReintentoJwtClient extends http.BaseClient {
  final http.Client _inner;
  final List<Duration> _esperas;

  ReintentoJwtClient({
    http.Client? inner,
    List<Duration> esperas = const [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 4)],
  })  : _inner = inner ?? http.Client(),
        _esperas = esperas;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Solo se pueden repetir peticiones con el cuerpo en memoria
    // (las de la API y Auth); las subidas en streaming pasan tal cual.
    if (request is! http.Request) return _inner.send(request);

    for (var intento = 0;; intento++) {
      final response = await _inner.send(intento == 0 ? request : _copiar(request));
      if (response.statusCode != 401 || intento == _esperas.length) return response;

      final body = await response.stream.toBytes();
      if (!utf8.decode(body, allowMalformed: true).contains('PGRST303')) {
        return http.StreamedResponse(
          http.ByteStream.fromBytes(body),
          response.statusCode,
          contentLength: body.length,
          request: response.request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      }
      await Future.delayed(_esperas[intento]);
    }
  }

  http.Request _copiar(http.Request original) {
    return http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection
      ..bodyBytes = original.bodyBytes;
  }

  @override
  void close() => _inner.close();
}
