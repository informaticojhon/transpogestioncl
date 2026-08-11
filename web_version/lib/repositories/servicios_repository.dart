import '../repositories/supabase_repository.dart';

class ServiciosRepository {
  static final ServiciosRepository _instance = ServiciosRepository._internal();
  factory ServiciosRepository() => _instance;
  ServiciosRepository._internal();

  final _supabaseRepo = SupabaseRepository();

  Future<List<dynamic>> obtenerServicios({bool forceRefresh = false}) async {
    return await _supabaseRepo.getServicios();
  }

  Future<List<dynamic>> obtenerServiciosPorFecha(String fecha) async {
    return await _supabaseRepo.getServiciosPorFecha(fecha);
  }

  Future<Map<String, dynamic>> crearServicio({
    required String fecha,
    required int valor,
    required String quien,
    required String empresa,
    required String tipo,
  }) async {
    await _supabaseRepo.crearServicio(
      fecha: fecha,
      valor: valor,
      quien: quien,
      empresa: empresa,
      tipo: tipo,
    );
    return {'mensaje': 'Servicio creado exitosamente'};
  }

  Future<Map<String, dynamic>> actualizarServicio({
    required int id,
    required String fecha,
    required int valor,
    required String quien,
    required String empresa,
    required String tipo,
  }) async {
    await _supabaseRepo.actualizarServicio(
      id: id,
      fecha: fecha,
      valor: valor,
      quien: quien,
      empresa: empresa,
      tipo: tipo,
    );
    return {'mensaje': 'Servicio actualizado'};
  }

  Future<void> eliminarServicio(int id) async {
    await _supabaseRepo.eliminarServicio(id);
  }

  Future<void> eliminarTodosLosServicios() async {
    await _supabaseRepo.eliminarTodosLosServicios();
  }
}
