// Modelo unificado que coincide con la API
class Servicio {
  int? id;
  String tipo;
  String empresa;
  String quien;
  int valor;
  DateTime fecha;
  bool isLocal; // Nuevo: Para saber si está pendiente de sincronizar
  String? localAction; // Nuevo: 'crear', 'actualizar', 'eliminar'

  Servicio({
    this.id,
    required this.tipo,
    required this.empresa,
    required this.quien,
    required this.valor,
    required this.fecha,
    this.isLocal = false,
    this.localAction,
  });

  // Convierte el objeto a Map para enviar a la API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'empresa': empresa,
      'quien': quien,
      'valor': valor,
      'fecha': fecha.toIso8601String().split('T')[0], // Solo fecha (YYYY-MM-DD)
    };
  }

  // Crea un objeto desde la respuesta de la API
  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'],
      tipo: json['tipo'] ?? '',
      empresa: json['empresa'] ?? '',
      quien: json['quien'] ?? '',
      valor: json['valor'] ?? 0,
      fecha: DateTime.parse(json['fecha']),
      isLocal: json['isLocal'] ?? false,
      localAction: json['localAction'],
    );
  }

  // Métodos auxiliares para compatibilidad (si se necesitan)
  @override
  String toString() {
    return 'Servicio{id: $id, tipo: $tipo, empresa: $empresa, quien: $quien, valor: $valor, fecha: $fecha}';
  }
}
