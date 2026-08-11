class MovimientoMaterial {
  final int? id;
  final int materialId;
  final String userId;
  final DateTime fecha;
  final String tipo; // entrada, salida
  final int cantidad;
  final String? observaciones;
  final DateTime? createdAt;

  MovimientoMaterial({
    this.id,
    required this.materialId,
    this.userId = '',
    required this.fecha,
    required this.tipo,
    required this.cantidad,
    this.observaciones,
    this.createdAt,
  });

  factory MovimientoMaterial.fromJson(Map<String, dynamic> json) {
    return MovimientoMaterial(
      id: json['id'] as int?,
      materialId: json['material_id'] as int,
      userId: json['user_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      tipo: json['tipo'] as String,
      cantidad: json['cantidad'] as int,
      observaciones: json['observaciones'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'material_id': materialId,
      'user_id': userId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'tipo': tipo,
      'cantidad': cantidad,
      'observaciones': observaciones,
    };
  }
}
