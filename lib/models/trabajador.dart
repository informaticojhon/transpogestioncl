class Trabajador {
  final int? id;
  final String userId;
  final String rut;
  final String nombre;
  final String apellido;
  final String? cargo;
  final DateTime fechaIngreso;
  final String? telefono;
  final String? email;
  final int salarioBase;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Trabajador({
    this.id,
    this.userId = '',
    required this.rut,
    required this.nombre,
    required this.apellido,
    this.cargo,
    required this.fechaIngreso,
    this.telefono,
    this.email,
    this.salarioBase = 0,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  String get nombreCompleto => '$nombre $apellido';

  String get rutFormateado {
    final limpio = rut.replaceAll(RegExp(r'[.-]'), '');
    if (limpio.length < 2) return limpio;
    final cuerpo = limpio.substring(0, limpio.length - 1);
    final dv = limpio.substring(limpio.length - 1);
    return '$cuerpo-$dv';
  }

  int get diasTrabajados {
    final hoy = DateTime.now();
    return hoy.difference(fechaIngreso).inDays;
  }

  factory Trabajador.fromJson(Map<String, dynamic> json) {
    return Trabajador(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      rut: json['rut'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      cargo: json['cargo'] as String,
      fechaIngreso: DateTime.parse(json['fecha_ingreso'] as String),
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      salarioBase: json['salario_base'] as int? ?? 0,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'rut': rut,
      'nombre': nombre,
      'apellido': apellido,
      'cargo': cargo,
      'fecha_ingreso': fechaIngreso.toIso8601String().split('T')[0],
      'telefono': telefono,
      'email': email,
      'salario_base': salarioBase,
      'activo': activo,
    };
  }

  Trabajador copyWith({
    int? id,
    String? userId,
    String? rut,
    String? nombre,
    String? apellido,
    String? cargo,
    DateTime? fechaIngreso,
    String? telefono,
    String? email,
    int? salarioBase,
    bool? activo,
  }) {
    return Trabajador(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rut: rut ?? this.rut,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      cargo: cargo ?? this.cargo,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      salarioBase: salarioBase ?? this.salarioBase,
      activo: activo ?? this.activo,
    );
  }
}
