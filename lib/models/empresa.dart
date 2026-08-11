class Empresa {
  final String id;
  final String nombre;
  final String codigoInvitacion;
  final DateTime? createdAt;

  Empresa({
    required this.id,
    required this.nombre,
    required this.codigoInvitacion,
    this.createdAt,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoInvitacion: json['codigo_invitacion'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

class MiembroEquipo {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final DateTime? createdAt;

  MiembroEquipo({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.createdAt,
  });

  factory MiembroEquipo.fromJson(Map<String, dynamic> json) {
    return MiembroEquipo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
