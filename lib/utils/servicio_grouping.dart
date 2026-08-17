/// Agrupa una lista de servicios por su campo "empresa" (cliente), en
/// orden alfabético (los sin empresa quedan al final), y dentro de cada
/// grupo mantiene el orden en que llegaron (normalmente por fecha).
/// Se usa para que todos los reportes (Historial, Diario, Mensual)
/// organicen la información de la misma forma.
Map<String, List<dynamic>> agruparServiciosPorEmpresa(List<dynamic> servicios) {
  final grupos = <String, List<dynamic>>{};
  for (final s in servicios) {
    final empresa = (s['empresa'] as String?)?.trim();
    final clave = (empresa == null || empresa.isEmpty) ? 'Sin empresa' : empresa;
    grupos.putIfAbsent(clave, () => []).add(s);
  }

  final claves = grupos.keys.toList()
    ..sort((a, b) {
      if (a == 'Sin empresa') return 1;
      if (b == 'Sin empresa') return -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

  return {for (final clave in claves) clave: grupos[clave]!};
}

/// Misma agrupación, pero aplanada de vuelta a una lista (útil para
/// tablas planas como CSV/Excel: quedan contiguas por empresa en vez
/// de mezcladas).
List<dynamic> ordenarServiciosPorEmpresa(List<dynamic> servicios) {
  return agruparServiciosPorEmpresa(servicios).values.expand((lista) => lista).toList();
}
