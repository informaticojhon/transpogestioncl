class Remuneracion {
  final int? id;
  final int trabajadorId;
  final String userId;
  final DateTime fechaPago;
  final int monto;
  final String periodo; // semanal, quincenal, mensual
  final String? concepto;
  final DateTime? createdAt;

  Remuneracion({
    this.id,
    required this.trabajadorId,
    this.userId = '',
    required this.fechaPago,
    required this.monto,
    required this.periodo,
    this.concepto,
    this.createdAt,
  });

  factory Remuneracion.fromJson(Map<String, dynamic> json) {
    return Remuneracion(
      id: json['id'] as int?,
      trabajadorId: json['trabajador_id'] as int,
      userId: json['user_id'] as String,
      fechaPago: DateTime.parse(json['fecha_pago'] as String),
      monto: json['monto'] as int,
      periodo: json['periodo'] as String,
      concepto: json['concepto'] as String?,
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
      'fecha_pago': fechaPago.toIso8601String().split('T')[0],
      'monto': monto,
      'periodo': periodo,
      'concepto': concepto,
    };
  }
}

/// Una remuneración junto con el nombre del trabajador al que pertenece,
/// para el reporte consolidado de pagos de toda la empresa (en vez del
/// detalle de un solo trabajador).
class RemuneracionConTrabajador {
  final Remuneracion remuneracion;
  final String nombreTrabajador;

  RemuneracionConTrabajador({required this.remuneracion, required this.nombreTrabajador});
}
