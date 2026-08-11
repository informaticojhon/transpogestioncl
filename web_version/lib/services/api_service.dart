import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'cache_service.dart';

class ApiService {
  // 10.0.2.2 es la IP especial que Android usa para localhost de la PC host
  static String get baseUrl => kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';
  static const Duration timeout = Duration(seconds: 30);

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  final _cacheService = CacheService();

  // ============ MÉTODOS AUXILIARES ============

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _saveUserName(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Limpiar caché también
    await _cacheService.clearAllCache();
    print('🗑️ Sesión y caché limpiados');
  }

  Map<String, String> _getHeaders({bool requiresAuth = false, String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Manejo de respuestas HTTP
  dynamic _handleResponse(http.Response response) {
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      String message = 'Token expirado o inválido';
      try {
        final error = jsonDecode(response.body);
        if (error['mensaje'] != null) {
          message = error['mensaje'];
        }
      } catch (_) {}
      throw TokenExpiredException(message);
    } else {
      try {
        final error = jsonDecode(response.body);
        throw ApiException(
          error['mensaje'] ?? error['message'] ?? 'Error desconocido',
          response.statusCode,
        );
      } catch (e) {
        throw ApiException(
          'Error ${response.statusCode}: ${response.body}',
          response.statusCode,
        );
      }
    }
  }

  // ============ AUTENTICACIÓN ============

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔵 Intentando login con: $email');
      print('🔵 URL: $baseUrl/auth/login');
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _getHeaders(),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(timeout);

      print('🟢 Respuesta recibida: ${response.statusCode}');
      
      final data = _handleResponse(response);

      if (data['token'] != null) {
        await _saveToken(data['token']);
        await _saveUserName(data['nombre'] ?? '');
      }

      return data;
    } on TokenExpiredException {
      print('🔴 Token expirado');
      rethrow;
    } on ApiException catch (e) {
      print('🔴 Error de API: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔴 Error de conexión: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(
      String nombre, String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _getHeaders(),
            body: jsonEncode({
              'nombre': nombre,
              'email': email,
              'password': password,
            }),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ SERVICIOS (Pure HTTP) ============

  Future<List<dynamic>> fetchServicios() async {
    final token = await _getToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/servicios'),
          headers: _getHeaders(requiresAuth: token != null, token: token),
        )
        .timeout(timeout);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postServicio(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http
        .post(
          Uri.parse('$baseUrl/servicios'),
          headers: _getHeaders(requiresAuth: token != null, token: token),
          body: jsonEncode(data),
        )
        .timeout(timeout);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> putServicio(int id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http
        .put(
          Uri.parse('$baseUrl/servicios/$id'),
          headers: _getHeaders(requiresAuth: token != null, token: token),
          body: jsonEncode(data),
        )
        .timeout(timeout);

    return _handleResponse(response);
  }

  Future<void> deleteServicio(int id) async {
    final token = await _getToken();
    final response = await http
        .delete(
          Uri.parse('$baseUrl/servicios/$id'),
          headers: _getHeaders(requiresAuth: token != null, token: token),
        )
        .timeout(timeout);

    _handleResponse(response);
  }

  Future<void> deleteAllServicios() async {
    final token = await _getToken();
    final response = await http
        .delete(
          Uri.parse('$baseUrl/servicios'),
          headers: _getHeaders(requiresAuth: token != null, token: token),
        )
        .timeout(timeout);

    _handleResponse(response);
  }
}

// ============ EXCEPCIONES PERSONALIZADAS ============

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);

  @override
  String toString() => message;
}
