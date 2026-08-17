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
