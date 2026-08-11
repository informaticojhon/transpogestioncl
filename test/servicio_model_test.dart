import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_app/models/servicio.dart';

void main() {
  group('Servicio Model', () {
    test('toJson serializa correctamente', () {
      final servicio = Servicio(
        id: 1,
        tipo: 'Transporte',
        empresa: 'ABC Corp',
        quien: 'Juan Pérez',
        valor: 50000,
        fecha: DateTime(2025, 12, 3),
      );

      final json = servicio.toJson();

      expect(json['id'], 1);
      expect(json['tipo'], 'Transporte');
      expect(json['empresa'], 'ABC Corp');
      expect(json['quien'], 'Juan Pérez');
      expect(json['valor'], 50000);
      expect(json['fecha'], '2025-12-03');
    });

    test('fromJson deserializa correctamente', () {
      final json = {
        'id': 2,
        'tipo': 'Carga',
        'empresa': 'XYZ SA',
        'quien': 'María González',
        'valor': 75000,
        'fecha': '2025-12-04',
      };

      final servicio = Servicio.fromJson(json);

      expect(servicio.id, 2);
      expect(servicio.tipo, 'Carga');
      expect(servicio.empresa, 'XYZ SA');
      expect(servicio.quien, 'María González');
      expect(servicio.valor, 75000);
      expect(servicio.fecha, DateTime(2025, 12, 4));
    });

    test('fromJson maneja valores null correctamente', () {
      final json = {
        'id': 3,
        'tipo': null,
        'empresa': null,
        'quien': null,
        'valor': null,
        'fecha': '2025-12-03',
      };

      final servicio = Servicio.fromJson(json);

      expect(servicio.id, 3);
      expect(servicio.tipo, '');
      expect(servicio.empresa, '');
      expect(servicio.quien, '');
      expect(servicio.valor, 0);
    });

    test('toString retorna formato legible', () {
      final servicio = Servicio(
        id: 1,
        tipo: 'Test',
        empresa: 'Test Corp',
        quien: 'Test User',
        valor: 10000,
        fecha: DateTime(2025, 12, 3),
      );

      final string = servicio.toString();

      expect(string, contains('id: 1'));
      expect(string, contains('tipo: Test'));
      expect(string, contains('empresa: Test Corp'));
      expect(string, contains('valor: 10000'));
    });

    test('Servicio se puede crear sin ID', () {
      final servicio = Servicio(
        tipo: 'Nuevo',
        empresa: 'Nueva Empresa',
        quien: 'Usuario',
        valor: 20000,
        fecha: DateTime.now(),
      );

      expect(servicio.id, null);
      expect(servicio.tipo, 'Nuevo');
      expect(servicio.valor, 20000);
    });
  });
}
