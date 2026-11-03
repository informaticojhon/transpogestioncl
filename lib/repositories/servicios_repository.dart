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

  Future<List<dynamic>> obtenerServiciosPorRangoFecha(String fechaInicio, String fechaFin) async {
    return await _supabaseRepo.getServiciosPorRangoFecha(fechaInicio, fechaFin);
  }

  Future<List<dynamic>> obtenerServiciosRecientes({int limite = 20}) async {
    return await _supabaseRepo.getServiciosRecientes(limite: limite);
  }

  Future<Map<String, int>> obtenerEstadisticas() async {
    return await _supabaseRepo.getEstadisticasServicios();
  }

  Future<List<dynamic>> buscarServiciosPaginado({
    required int offset,
    required int limit,
    String? busqueda,
    String? empresaCliente,
  }) async {
    return await _supabaseRepo.buscarServiciosPaginado(
      offset: offset,
      limit: limit,
      busqueda: busqueda,
      empresaCliente: empresaCliente,
    );
  }

  Future<List<({DateTime mes, int total})>> obtenerIngresosPorMes({int meses = 6}) async {
    return await _supabaseRepo.getIngresosPorMes(meses: meses);
  }

  Future<List<dynamic>> obtenerTodosParaExportar({String? busqueda, String? empresaCliente}) async {
    return await _supabaseRepo.getTodosLosServiciosParaExportar(
      busqueda: busqueda,
      empresaCliente: empresaCliente,
    );
  }

  Future<List<String>> obtenerEmpresasClientesUnicas() async {
    return await _supabaseRepo.getEmpresasClientesUnicas();
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

  Future<void> restaurarServicio(Map<String, dynamic> servicio) async {
    await _supabaseRepo.restaurarServicio(servicio);
  }
}
