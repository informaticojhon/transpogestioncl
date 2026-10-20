import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_app/models/remuneracion.dart';
import 'package:transporte_app/utils/remuneracion_grouping.dart';
import 'package:transporte_app/utils/servicio_grouping.dart';

void main() {
  group('ordenarServiciosPorFechaDesc', () {
    test('ordena del más reciente al más antiguo, sin importar la empresa', () {
      final servicios = [
        {'id': 1, 'fecha': '2026-10-01', 'empresa': 'Beta'},
        {'id': 2, 'fecha': '2026-10-20', 'empresa': 'Alfa'},
        {'id': 3, 'fecha': '2026-09-15', 'empresa': 'Alfa'},
        {'id': 4, 'fecha': '2026-10-05', 'empresa': 'Beta'},
      ];

      final ordenados = ordenarServiciosPorFechaDesc(servicios);

      expect(ordenados.map((s) => s['fecha']), ['2026-10-20', '2026-10-05', '2026-10-01', '2026-09-15']);
    });

    test('a igual fecha, el último registrado (id mayor) va primero', () {
      final servicios = [
        {'id': 7, 'fecha': '2026-10-20'},
        {'id': 9, 'fecha': '2026-10-20'},
        {'id': 8, 'fecha': '2026-10-20'},
      ];

      expect(ordenarServiciosPorFechaDesc(servicios).map((s) => s['id']), [9, 8, 7]);
    });

    test('no modifica la lista original', () {
      final servicios = [
        {'id': 1, 'fecha': '2026-01-01'},
        {'id': 2, 'fecha': '2026-12-31'},
      ];

      ordenarServiciosPorFechaDesc(servicios);

      expect(servicios.first['id'], 1);
    });
  });

  group('ordenarRemuneracionesPorFechaDesc', () {
    RemuneracionConTrabajador pago(String nombre, DateTime fecha) => RemuneracionConTrabajador(
          nombreTrabajador: nombre,
          remuneracion: Remuneracion(trabajadorId: 1, fechaPago: fecha, monto: 1000, periodo: '2026-10'),
        );

    test('ordena por fecha de pago descendente y, a igual fecha, por nombre', () {
      final pagos = [
        pago('Pedro', DateTime(2026, 9, 30)),
        pago('Ana', DateTime(2026, 10, 15)),
        pago('Carla', DateTime(2026, 10, 31)),
        pago('Bruno', DateTime(2026, 10, 15)),
      ];

      final ordenados = ordenarRemuneracionesPorFechaDesc(pagos);

      expect(ordenados.map((p) => p.nombreTrabajador), ['Carla', 'Ana', 'Bruno', 'Pedro']);
    });
  });
}
