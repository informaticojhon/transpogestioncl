import 'package:shared_preferences/shared_preferences.dart';

/// Bloqueo progresivo de inicio de sesión por correo, para frenar intentos
/// de fuerza bruta desde la propia interfaz. Se guarda en el almacenamiento
/// local del navegador (persiste entre recargas de página, se resetea al
/// iniciar sesión con éxito). Es una barrera del lado del cliente: la
/// protección real contra ataques automatizados vía API la da el rate
/// limiting propio de Supabase Auth (Authentication > Rate Limits).
class LoginLockout {
  static const _intentosParaBloqueo = 5;
  static const _duracionesBloqueoSegundos = [30, 60, 120, 300, 900];

  static String _claveIntentos(String email) => 'login_intentos_${email.toLowerCase().trim()}';
  static String _claveBloqueadoHasta(String email) => 'login_bloqueado_hasta_${email.toLowerCase().trim()}';

  /// Si hay un bloqueo activo para ese correo, devuelve cuánto falta para
  /// que expire; null si puede intentar de nuevo.
  static Future<Duration?> tiempoRestante(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final hastaMs = prefs.getInt(_claveBloqueadoHasta(email));
    if (hastaMs == null) return null;

    final restante = DateTime.fromMillisecondsSinceEpoch(hastaMs).difference(DateTime.now());
    return restante.isNegative ? null : restante;
  }

  /// Registra un intento fallido. Devuelve la duración del bloqueo recién
  /// activado, o null si todavía quedan intentos antes de bloquear.
  static Future<Duration?> registrarIntentoFallido(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final claveIntentos = _claveIntentos(email);
    final intentos = (prefs.getInt(claveIntentos) ?? 0) + 1;
    await prefs.setInt(claveIntentos, intentos);

    if (intentos < _intentosParaBloqueo) return null;

    final indice = (intentos - _intentosParaBloqueo).clamp(0, _duracionesBloqueoSegundos.length - 1);
    final duracion = Duration(seconds: _duracionesBloqueoSegundos[indice]);
    await prefs.setInt(_claveBloqueadoHasta(email), DateTime.now().add(duracion).millisecondsSinceEpoch);
    return duracion;
  }

  /// Limpia el contador de intentos tras un inicio de sesión exitoso.
  static Future<void> reset(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveIntentos(email));
    await prefs.remove(_claveBloqueadoHasta(email));
  }
}
