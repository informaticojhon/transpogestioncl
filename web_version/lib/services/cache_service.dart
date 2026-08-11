import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const Duration cacheDuration = Duration(minutes: 15);

  // Singleton
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // ============ GUARDAR EN CACHÉ ============

  Future<void> saveToCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';
      
      final jsonData = jsonEncode(data);
      await prefs.setString(cacheKey, jsonData);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Datos guardados en caché: $key');
    } catch (e) {
      print('❌ Error al guardar en caché: $e');
    }
  }

  // ============ OBTENER DE CACHÉ ============

  Future<dynamic> getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';
      
      final jsonData = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);
      
      if (jsonData == null || timestamp == null) {
        print('⚠️ No hay datos en caché para: $key');
        return null;
      }
      
      // Verificar si el caché expiró
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);
      
      if (difference > cacheDuration) {
        print('⏰ Caché expirado para: $key');
        await clearCache(key);
        return null;
      }
      
      print('✅ Datos obtenidos de caché: $key');
      return jsonDecode(jsonData);
    } catch (e) {
      print('❌ Error al leer caché: $e');
      return null;
    }
  }

  // ============ VERIFICAR VALIDEZ DEL CACHÉ ============

  Future<bool> isCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = '$_cacheTimestampPrefix$key';
      final timestamp = prefs.getInt(timestampKey);
      
      if (timestamp == null) return false;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);
      
      return difference <= cacheDuration;
    } catch (e) {
      return false;
    }
  }

  // ============ LIMPIAR CACHÉ ESPECÍFICO ============

  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_cacheTimestampPrefix$key';
      
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
      
      print('🗑️ Caché eliminado: $key');
    } catch (e) {
      print('❌ Error al eliminar caché: $e');
    }
  }

  // ============ LIMPIAR TODO EL CACHÉ ============

  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (var key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)) {
          await prefs.remove(key);
        }
      }
      
      print('🗑️ Todo el caché eliminado');
    } catch (e) {
      print('❌ Error al eliminar todo el caché: $e');
    }
  }

  // ============ OBTENER TIEMPO RESTANTE DEL CACHÉ ============

  Future<Duration?> getCacheTimeRemaining(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = '$_cacheTimestampPrefix$key';
      final timestamp = prefs.getInt(timestampKey);
      
      if (timestamp == null) return null;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expirationTime = cacheTime.add(cacheDuration);
      final now = DateTime.now();
      
      if (now.isAfter(expirationTime)) return null;
      
      return expirationTime.difference(now);
    } catch (e) {
      return null;
    }
  }
}
