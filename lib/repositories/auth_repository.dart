import '../models/empresa.dart';
import '../models/registro_auditoria.dart';
import '../repositories/supabase_repository.dart';

class AuthRepository {
  final _supabaseRepo = SupabaseRepository();

  Future<void> login(String email, String password) async {
    await _supabaseRepo.login(email, password);
  }

  Future<String?> register({
    required String nombre,
    required String email,
    required String password,
    String? nombreEmpresa,
    String? codigoInvitacion,
  }) async {
    return _supabaseRepo.register(
      nombre: nombre,
      email: email,
      password: password,
      nombreEmpresa: nombreEmpresa,
      codigoInvitacion: codigoInvitacion,
    );
  }

  Future<void> logout() async {
    await _supabaseRepo.logout();
  }

  Future<void> enviarRecuperacionPassword(String email) async {
    await _supabaseRepo.enviarRecuperacionPassword(email);
  }

  Future<void> actualizarPassword(String nuevaPassword) async {
    await _supabaseRepo.actualizarPassword(nuevaPassword);
  }

  Future<void> verificarCodigoRecuperacion(String email, String codigo) async {
    await _supabaseRepo.verificarCodigoRecuperacion(email, codigo);
  }

  Future<bool> isLoggedIn() async {
    return _supabaseRepo.isLoggedIn();
  }

  String? getCurrentUserId() {
    return _supabaseRepo.getCurrentUserId();
  }

  Future<String?> getNombreUsuario() async {
    return _supabaseRepo.getNombreUsuario();
  }

  Future<String?> getRolUsuario() async {
    return _supabaseRepo.getRolUsuario();
  }

  Future<Empresa?> getMiEmpresa() async {
    return _supabaseRepo.getMiEmpresa();
  }

  Future<List<MiembroEquipo>> getMiembrosEquipo() async {
    return _supabaseRepo.getMiembrosEquipo();
  }

  Future<void> eliminarMiembroEquipo(String userId) async {
    await _supabaseRepo.eliminarMiembroEquipo(userId);
  }

  Future<List<RegistroAuditoria>> getAuditoria({
    required int offset,
    required int limit,
    String? tabla,
  }) async {
    return _supabaseRepo.getAuditoria(offset: offset, limit: limit, tabla: tabla);
  }
}
