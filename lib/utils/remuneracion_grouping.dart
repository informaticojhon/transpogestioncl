import '../models/remuneracion.dart';

/// Agrupa remuneraciones por trabajador, en orden alfabético, para que el
/// reporte consolidado (pantalla y exportaciones) muestre los pagos de
/// cada persona juntos en vez de mezclados por fecha.
Map<String, List<RemuneracionConTrabajador>> agruparRemuneracionesPorTrabajador(
  List<RemuneracionConTrabajador> remuneraciones,
) {
  final grupos = <String, List<RemuneracionConTrabajador>>{};
  for (final r in remuneraciones) {
    grupos.putIfAbsent(r.nombreTrabajador, () => []).add(r);
  }

  final claves = grupos.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return {for (final clave in claves) clave: grupos[clave]!};
}

/// Remuneraciones ordenadas por fecha de pago, de la más reciente a la
/// más antigua (a igual fecha, por nombre del trabajador).
List<RemuneracionConTrabajador> ordenarRemuneracionesPorFechaDesc(
  List<RemuneracionConTrabajador> remuneraciones,
) {
  return List<RemuneracionConTrabajador>.from(remuneraciones)
    ..sort((a, b) {
      final porFecha = b.remuneracion.fechaPago.compareTo(a.remuneracion.fechaPago);
      if (porFecha != 0) return porFecha;
      return a.nombreTrabajador.toLowerCase().compareTo(b.nombreTrabajador.toLowerCase());
    });
}
