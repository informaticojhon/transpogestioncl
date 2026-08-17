/// Una entrada del historial de auditoría: quién hizo qué, cuándo, y sobre
/// qué registro. Se genera automáticamente en la base de datos (triggers)
/// cada vez que se crea, edita o elimina algo en las tablas sensibles de
/// la empresa — no depende de que la app recuerde registrar el evento.
class RegistroAuditoria {
  final int id;
  final String? userId;
  final String accion; // insert, update, delete
  final String tabla;
  final String? registroId;
  final Map<String, dynamic>? datos;
  final DateTime createdAt;

  RegistroAuditoria({
    required this.id,
    this.userId,
    required this.accion,
    required this.tabla,
    this.registroId,
    this.datos,
    required this.createdAt,
  });

  factory RegistroAuditoria.fromJson(Map<String, dynamic> json) {
    return RegistroAuditoria(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      accion: json['accion'] as String,
      tabla: json['tabla'] as String,
      registroId: json['registro_id'] as String?,
      datos: json['datos'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
