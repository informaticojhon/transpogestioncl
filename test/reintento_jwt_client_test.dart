import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_app/config/reintento_jwt_client.dart';

const _jwtFuturo = '{"code":"PGRST303","details":null,"hint":null,"message":"JWT issued at future"}';

ReintentoJwtClient _cliente(List<http.Response> respuestas, List<http.Request> recibidas) {
  return ReintentoJwtClient(
    inner: MockClient((request) async {
      recibidas.add(request);
      return respuestas[recibidas.length - 1];
    }),
    esperas: const [Duration.zero, Duration.zero],
  );
}

void main() {
  group('ReintentoJwtClient', () {
    test('reintenta con el mismo cuerpo y token si el JWT viene del futuro', () async {
      final recibidas = <http.Request>[];
      final cliente = _cliente([http.Response(_jwtFuturo, 401), http.Response('[]', 200)], recibidas);

      final r = await cliente.post(
        Uri.parse('https://x.supabase.co/rest/v1/servicios'),
        headers: {'Authorization': 'Bearer abc'},
        body: '{"valor":1000}',
      );

      expect(r.statusCode, 200);
      expect(recibidas, hasLength(2));
      expect(recibidas[1].body, '{"valor":1000}');
      expect(recibidas[1].headers['Authorization'], 'Bearer abc');
    });

    test('se rinde tras agotar los reintentos', () async {
      final recibidas = <http.Request>[];
      final cliente = _cliente(List.filled(3, http.Response(_jwtFuturo, 401)), recibidas);

      final r = await cliente.get(Uri.parse('https://x.supabase.co/rest/v1/servicios'));

      expect(r.statusCode, 401);
      expect(r.body, _jwtFuturo);
      expect(recibidas, hasLength(3));
    });

    test('no reintenta otros 401 y conserva su cuerpo', () async {
      final recibidas = <http.Request>[];
      const expirado = '{"code":"PGRST301","message":"JWT expired"}';
      final cliente = _cliente([http.Response(expirado, 401)], recibidas);

      final r = await cliente.get(Uri.parse('https://x.supabase.co/rest/v1/servicios'));

      expect(r.statusCode, 401);
      expect(r.body, expirado);
      expect(recibidas, hasLength(1));
    });
  });
}
