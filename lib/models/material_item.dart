class MaterialItem {
  final int? id;
  final String userId;
  final String nombre;
  final String? categoria;
  final String unidadMedida;
  final int stockInicial;
  final int stockMinimo;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MaterialItem({
    this.id,
    this.userId = '',
    required this.nombre,
    this.categoria,
    this.unidadMedida = 'unidad',
    this.stockInicial = 0,
    this.stockMinimo = 0,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      nombre: json['nombre'] as String,
      categoria: json['categoria'] as String?,
      unidadMedida: json['unidad_medida'] as String? ?? 'unidad',
      stockInicial: json['stock_inicial'] as int? ?? 0,
      stockMinimo: json['stock_minimo'] as int? ?? 0,
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
      'nombre': nombre,
      'categoria': categoria,
      'unidad_medida': unidadMedida,
      'stock_inicial': stockInicial,
      'stock_minimo': stockMinimo,
      'activo': activo,
    };
  }
}
