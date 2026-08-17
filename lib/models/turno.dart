class Turno {
  final int? id;
  final int trabajadorId;
  final String userId;
  final DateTime fecha;
  final double horasTrabajadas;
  final String tipoTurno; // normal, extra, nocturno
  final String? observaciones;
  final DateTime? createdAt;

  Turno({
    this.id,
    required this.trabajadorId,
    this.userId = '',
    required this.fecha,
    this.horasTrabajadas = 8.0,
    this.tipoTurno = 'normal',
    this.observaciones,
    this.createdAt,
  });

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      id: json['id'] as int?,
      trabajadorId: json['trabajador_id'] as int,
      userId: json['user_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      horasTrabajadas: (json['horas_trabajadas'] as num?)?.toDouble() ?? 8.0,
      tipoTurno: json['tipo_turno'] as String? ?? 'normal',
      observaciones: json['observaciones'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'trabajador_id': trabajadorId,
      'user_id': userId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'horas_trabajadas': horasTrabajadas,
      'tipo_turno': tipoTurno,
      'observaciones': observaciones,
    };
  }
}

/// Un turno junto con el nombre del trabajador al que pertenece, para
/// vistas que abarcan a todos los trabajadores de la empresa (ej. el
/// calendario de turnos) en vez de a uno solo.
class TurnoConTrabajador {
  final Turno turno;
  final String nombreTrabajador;

  TurnoConTrabajador({required this.turno, required this.nombreTrabajador});
}
