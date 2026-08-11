import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class SupabaseRepository {
  static final SupabaseRepository _instance = SupabaseRepository._internal();
  factory SupabaseRepository() => _instance;
  SupabaseRepository._internal();

  // ============ AUTENTICACIÓN ============
  
  Future<void> register(String nombre, String email, String password) async {
    try {
      // 1. Crear usuario en Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Error al crear usuario');
      }
      
      // 2. Guardar datos adicionales en tabla usuarios
      await supabase.from('usuarios').insert({
        'id': response.user!.id,
        'nombre': nombre,
        'email': email,
        'password': password, // En producción usar hash
      });
      
    } catch (e) {
      throw Exception('Error al registrar: ${e.toString()}');
    }
  }
  
  Future<void> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Credenciales inválidas');
      }
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }
  
  Future<void> logout() async {
    await supabase.auth.signOut();
  }
  
  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }
  
  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  // ============ SERVICIOS ============
  
  Future<List<Map<String, dynamic>>> getServicios() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    final response = await supabase
        .from('servicios')
        .select()
        .eq('user_id', userId)
        .order('fecha', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<List<Map<String, dynamic>>> getServiciosPorFecha(String fecha) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    final response = await supabase
        .from('servicios')
        .select()
        .eq('user_id', userId)
        .eq('fecha', fecha)
        .order('id', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<void> crearServicio({
    required String fecha,
    required int valor,
    required String quien,
    required String empresa,
    required String tipo,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await supabase.from('servicios').insert({
      'user_id': userId,
      'fecha': fecha,
      'valor': valor,
      'quien': quien,
      'empresa': empresa,
      'tipo': tipo,
    });
  }
  
  Future<void> actualizarServicio({
    required int id,
    required String fecha,
    required int valor,
    required String quien,
    required String empresa,
    required String tipo,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await supabase
        .from('servicios')
        .update({
          'fecha': fecha,
          'valor': valor,
          'quien': quien,
          'empresa': empresa,
          'tipo': tipo,
        })
        .eq('id', id)
        .eq('user_id', userId);
  }
  
  Future<void> eliminarServicio(int id) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await supabase
        .from('servicios')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
  
  Future<void> eliminarTodosLosServicios() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');
    
    await supabase
        .from('servicios')
        .delete()
        .eq('user_id', userId);
  }
}
