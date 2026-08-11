import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/empresa.dart';

class SupabaseRepository {
  static final SupabaseRepository _instance = SupabaseRepository._internal();
  factory SupabaseRepository() => _instance;
  SupabaseRepository._internal();

  String? _cachedEmpresaId;

  // ============ AUTENTICACIÓN ============

  /// Registra un usuario. Debe indicarse exactamente uno de los dos:
  /// [nombreEmpresa] (crea una empresa nueva, el usuario queda como admin) o
  /// [codigoInvitacion] (se une a una empresa existente, como empleado).
  ///
  /// Devuelve el código de invitación de la empresa recién creada (para que
  /// el admin lo comparta con su equipo), o `null` si se unió a una existente.
  Future<String?> register({
    required String nombre,
    required String email,
    required String password,
    String? nombreEmpresa,
    String? codigoInvitacion,
  }) async {
    try {
      final response = await supabase.auth.signUp(email: email, password: password);

      if (response.user == null) {
        throw Exception('Error al crear usuario');
      }

      String empresaId;
      String rol;
      String? codigoGenerado;

      if (codigoInvitacion != null) {
        final encontrada = await supabase.rpc(
          'buscar_empresa_por_codigo',
          params: {'codigo': codigoInvitacion.trim().toUpperCase()},
        );
        if (encontrada == null) {
          throw Exception('El código de invitación no es válido');
        }
        empresaId = encontrada as String;
        rol = 'empleado';
      } else {
        final empresaCreada = await supabase.rpc(
          'crear_empresa',
          params: {'nombre_empresa': nombreEmpresa ?? '$nombre - Empresa'},
        );
        empresaId = empresaCreada['id'] as String;
        codigoGenerado = empresaCreada['codigo_invitacion'] as String;
        rol = 'admin';
      }

      await supabase.from('usuarios').insert({
        'id': response.user!.id,
        'nombre': nombre,
        'email': email,
        'empresa_id': empresaId,
        'rol': rol,
      });

      return codigoGenerado;
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
    _cachedEmpresaId = null;
    await supabase.auth.signOut();
  }

  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }

  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  Future<String?> getNombreUsuario() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    final response = await supabase
        .from('usuarios')
        .select('nombre')
        .eq('id', userId)
        .maybeSingle();

    return response?['nombre'] as String?;
  }

  /// Devuelve el id de la empresa a la que pertenece el usuario actual,
  /// cacheado en memoria para no consultarlo en cada operación.
  Future<String?> getEmpresaId() async {
    if (_cachedEmpresaId != null) return _cachedEmpresaId;

    final userId = getCurrentUserId();
    if (userId == null) return null;

    final response = await supabase
        .from('usuarios')
        .select('empresa_id')
        .eq('id', userId)
        .maybeSingle();

    _cachedEmpresaId = response?['empresa_id'] as String?;
    return _cachedEmpresaId;
  }

  Future<String?> getRolUsuario() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    final response = await supabase
        .from('usuarios')
        .select('rol')
        .eq('id', userId)
        .maybeSingle();

    return response?['rol'] as String?;
  }

  Future<Empresa?> getMiEmpresa() async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) return null;

    final response = await supabase
        .from('empresas')
        .select()
        .eq('id', empresaId)
        .maybeSingle();

    if (response == null) return null;
    return Empresa.fromJson(response);
  }

  Future<List<MiembroEquipo>> getMiembrosEquipo() async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) return [];

    final response = await supabase
        .from('usuarios')
        .select('id, nombre, email, rol, created_at')
        .eq('empresa_id', empresaId)
        .order('rol', ascending: true)
        .order('nombre', ascending: true);

    return (response as List).map((json) => MiembroEquipo.fromJson(json)).toList();
  }

  /// Elimina por completo la cuenta de un miembro del equipo (requiere
  /// ser admin). Corre en una Edge Function porque borrar una cuenta de
  /// Supabase Auth exige la service_role key, que nunca debe estar en la app.
  Future<void> eliminarMiembroEquipo(String userId) async {
    try {
      final response = await supabase.functions.invoke(
        'eliminar-empleado',
        body: {'targetUserId': userId},
      );

      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }
    } on FunctionException catch (e) {
      final detalle = e.details;
      final mensaje = (detalle is Map && detalle['error'] != null)
          ? detalle['error'].toString()
          : 'Error al eliminar la cuenta';
      throw Exception(mensaje);
    }
  }

  // ============ SERVICIOS ============

  Future<List<Map<String, dynamic>>> getServicios() async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('servicios')
        .select()
        .eq('empresa_id', empresaId)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getServiciosPorFecha(String fecha) async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('servicios')
        .select()
        .eq('empresa_id', empresaId)
        .eq('fecha', fecha)
        .order('id', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Trae solo los servicios entre [fechaInicio] y [fechaFin] (ambas
  /// 'yyyy-MM-dd'), consultado en el servidor en vez de traer todo el
  /// historial y filtrar en la app.
  Future<List<Map<String, dynamic>>> getServiciosPorRangoFecha(
    String fechaInicio,
    String fechaFin,
  ) async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('servicios')
        .select()
        .eq('empresa_id', empresaId)
        .gte('fecha', fechaInicio)
        .lte('fecha', fechaFin)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Los servicios más recientes (para el panel principal, que solo
  /// necesita mostrar un vistazo, no el historial completo).
  Future<List<Map<String, dynamic>>> getServiciosRecientes({int limite = 20}) async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('servicios')
        .select()
        .eq('empresa_id', empresaId)
        .order('fecha', ascending: false)
        .order('id', ascending: false)
        .limit(limite);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Total de servicios y monto acumulado de la empresa, calculado en
  /// el servidor (no requiere traer todas las filas a la app).
  Future<Map<String, int>> getEstadisticasServicios() async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');

    final conteo = await supabase
        .from('servicios')
        .select('id')
        .eq('empresa_id', empresaId)
        .count(CountOption.exact);

    final suma = await supabase.rpc('suma_servicios_empresa');

    return {
      'total_servicios': conteo.count,
      'total_valor': (suma as num).toInt(),
    };
  }

  /// Servicios paginados para el Historial, con búsqueda hecha en el
  /// servidor (empresa, quién y tipo) en vez de filtrar una lista que
  /// podría no tener todos los datos cargados.
  Future<List<Map<String, dynamic>>> buscarServiciosPaginado({
    required int offset,
    required int limit,
    String? busqueda,
  }) async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');

    var query = supabase.from('servicios').select().eq('empresa_id', empresaId);

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      final termino = busqueda.trim();
      query = query.or(
        'empresa.ilike.%$termino%,quien.ilike.%$termino%,tipo.ilike.%$termino%',
      );
    }

    final response = await query
        .order('fecha', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

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
    final empresaId = await getEmpresaId();
    if (userId == null || empresaId == null) throw Exception('Usuario no autenticado');

    await supabase.from('servicios').insert({
      'user_id': userId,
      'empresa_id': empresaId,
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
    final empresaId = await getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');

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
        .eq('empresa_id', empresaId);
  }

  Future<void> eliminarServicio(int id) async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');

    await supabase
        .from('servicios')
        .delete()
        .eq('id', id)
        .eq('empresa_id', empresaId);
  }

  Future<void> eliminarTodosLosServicios() async {
    final empresaId = await getEmpresaId();
    if (empresaId == null) throw Exception('Usuario no autenticado');

    await supabase
        .from('servicios')
        .delete()
        .eq('empresa_id', empresaId);
  }
}
