import '../repositories/supabase_repository.dart';

class AuthRepository {
  final _supabaseRepo = SupabaseRepository();
  
  Future<void> login(String email, String password) async {
    await _supabaseRepo.login(email, password);
  }

  Future<void> register(String name, String email, String password) async {
    await _supabaseRepo.register(name, email, password);
  }

  Future<void> logout() async {
    await _supabaseRepo.logout();
  }
  
  Future<bool> isLoggedIn() async {
    return _supabaseRepo.isLoggedIn();
  }
}
