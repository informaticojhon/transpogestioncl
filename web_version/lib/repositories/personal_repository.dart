import '../main.dart';
import '../models/trabajador.dart';
import '../models/turno.dart';
import '../models/remuneracion.dart';

class PersonalRepository {
  static final PersonalRepository _instance = PersonalRepository._internal();
  factory PersonalRepository() => _instance;
  PersonalRepository._internal();

  String? _getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }

  // ============ TRABAJADORES ============

  Future<List<Trabajador>> getTrabajadores({bool soloActivos = false}) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    var query = supabase
        .from('trabajadores')
        .select()
        .eq('user_id', userId);

    if (soloActivos) {
      query = query.eq('activo', true);
    }

    final response = await query.order('nombre', ascending: true);
    return (response as List).map((json) => Trabajador.fromJson(json)).toList();
  }

  Future<Trabajador?> getTrabajador(int id) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('trabajadores')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Trabajador.fromJson(response);
  }

  Future<Trabajador> crearTrabajador(Trabajador trabajador) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final data = trabajador.toJson();
    data['user_id'] = userId;

    final response = await supabase
        .from('trabajadores')
        .insert(data)
        .select()
        .single();

    return Trabajador.fromJson(response);
  }

  Future<Trabajador> actualizarTrabajador(Trabajador trabajador) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('trabajadores')
        .update(trabajador.toJson())
        .eq('id', trabajador.id!)
        .eq('user_id', userId)
        .select()
        .single();

    return Trabajador.fromJson(response);
  }

  Future<void> eliminarTrabajador(int id) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    await supabase
        .from('trabajadores')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<void> cambiarEstadoTrabajador(int id, bool activo) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    await supabase
        .from('trabajadores')
        .update({'activo': activo})
        .eq('id', id)
        .eq('user_id', userId);
  }

  // ============ TURNOS ============

  Future<List<Turno>> getTurnosPorTrabajador(int trabajadorId) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('turnos')
        .select()
        .eq('trabajador_id', trabajadorId)
        .eq('user_id', userId)
        .order('fecha', ascending: false);

    return (response as List).map((json) => Turno.fromJson(json)).toList();
  }

  Future<List<Turno>> getTurnosPorFecha(DateTime fecha) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final fechaStr = fecha.toIso8601String().split('T')[0];
    final response = await supabase
        .from('turnos')
        .select()
        .eq('fecha', fechaStr)
        .eq('user_id', userId);

    return (response as List).map((json) => Turno.fromJson(json)).toList();
  }

  Future<int> contarTurnosTrabajador(int trabajadorId) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('turnos')
        .select('id')
        .eq('trabajador_id', trabajadorId)
        .eq('user_id', userId);

    return (response as List).length;
  }

  Future<Turno> registrarTurno(Turno turno) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final data = turno.toJson();
    data['user_id'] = userId;

    final response = await supabase
        .from('turnos')
        .insert(data)
        .select()
        .single();

    return Turno.fromJson(response);
  }

  Future<void> eliminarTurno(int id) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    await supabase
        .from('turnos')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  // ============ REMUNERACIONES ============

  Future<List<Remuneracion>> getRemuneracionesPorTrabajador(int trabajadorId) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('remuneraciones')
        .select()
        .eq('trabajador_id', trabajadorId)
        .eq('user_id', userId)
        .order('fecha_pago', ascending: false);

    return (response as List).map((json) => Remuneracion.fromJson(json)).toList();
  }

  Future<int> totalRemuneracionesTrabajador(int trabajadorId) async {
    final remuneraciones = await getRemuneracionesPorTrabajador(trabajadorId);
    return remuneraciones.fold<int>(0, (sum, rem) => sum + rem.monto);
  }

  Future<Remuneracion> registrarRemuneracion(Remuneracion remuneracion) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    final data = remuneracion.toJson();
    data['user_id'] = userId;

    final response = await supabase
        .from('remuneraciones')
        .insert(data)
        .select()
        .single();

    return Remuneracion.fromJson(response);
  }

  Future<void> eliminarRemuneracion(int id) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    await supabase
        .from('remuneraciones')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  // ============ ESTADÍSTICAS ============

  Future<Map<String, dynamic>> getEstadisticasTrabajador(int trabajadorId) async {
    final turnos = await getTurnosPorTrabajador(trabajadorId);
    final remuneraciones = await getRemuneracionesPorTrabajador(trabajadorId);

    final totalTurnos = turnos.length;
    final totalHoras = turnos.fold<double>(0, (sum, t) => sum + t.horasTrabajadas);
    final totalPagado = remuneraciones.fold<int>(0, (sum, r) => sum + r.monto);

    return {
      'total_turnos': totalTurnos,
      'total_horas': totalHoras,
      'total_pagado': totalPagado,
      'promedio_horas_turno': totalTurnos > 0 ? totalHoras / totalTurnos : 0,
    };
  }
}
