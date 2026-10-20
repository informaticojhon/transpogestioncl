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

/// Servicios ordenados del más reciente al más antiguo por "fecha"
/// (YYYY-MM-DD, que se ordena bien como texto) y, dentro del mismo día,
/// por id descendente (el último registrado primero). No depende del
/// orden en que vengan desde la base de datos.
List<dynamic> ordenarServiciosPorFechaDesc(List<dynamic> servicios) {
  return List<dynamic>.from(servicios)
    ..sort((a, b) {
      final porFecha = (b['fecha']?.toString() ?? '').compareTo(a['fecha']?.toString() ?? '');
      if (porFecha != 0) return porFecha;
      return ((b['id'] as num?) ?? 0).compareTo((a['id'] as num?) ?? 0);
    });
}
