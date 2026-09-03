import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherInfo {
  final double temperature;
  final String description;
  final IconData icon;
  final String? ciudad;

  WeatherInfo({
    required this.temperature,
    required this.description,
    required this.icon,
    this.ciudad,
  });
}

/// Ubicación de respaldo (Santiago, Chile) si el usuario no otorga permiso
/// de ubicación o el navegador/dispositivo no lo soporta.
const double _fallbackLat = -33.4489;
const double _fallbackLon = -70.6693;
const String _fallbackCiudad = 'Santiago';

class WeatherService {
  static const _cacheKey = 'weather_cache';
  static const _cacheDateKey = 'weather_cache_date';

  Future<WeatherInfo?> getClimaDelDia() async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fechaCache = prefs.getString(_cacheDateKey);

    if (fechaCache == hoy) {
      final cacheJson = prefs.getString(_cacheKey);
      if (cacheJson != null) {
        try {
          final data = jsonDecode(cacheJson) as Map<String, dynamic>;
          final (descripcion, icono) = _interpretarCodigo(data['codigo'] as int);
          return WeatherInfo(
            temperature: (data['temperature'] as num).toDouble(),
            description: descripcion,
            icon: icono,
            ciudad: data['ciudad'] as String?,
          );
        } catch (_) {
          // Cache corrupto: se ignora y se vuelve a consultar.
        }
      }
    }

    try {
      final posicion = await _obtenerPosicion();
      final lat = posicion?.latitude ?? _fallbackLat;
      final lon = posicion?.longitude ?? _fallbackLon;

      final (temperatura, codigo) = await _consultarClima(lat, lon);
      final ciudad = posicion != null ? await _obtenerCiudad(lat, lon) : _fallbackCiudad;
      final (descripcion, icono) = _interpretarCodigo(codigo);

      await prefs.setString(_cacheKey, jsonEncode({
            'temperature': temperatura,
            'codigo': codigo,
            'ciudad': ciudad,
          }));
      await prefs.setString(_cacheDateKey, hoy);

      return WeatherInfo(temperature: temperatura, description: descripcion, icon: icono, ciudad: ciudad);
    } catch (_) {
      return null;
    }
  }

  Future<Position?> _obtenerPosicion() async {
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) return null;

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
    } catch (_) {
      return null;
    }
  }

  Future<(double, int)> _consultarClima(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon&current_weather=true&timezone=auto',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body);
    final actual = data['current_weather'];
    final temperatura = (actual['temperature'] as num).toDouble();
    final codigo = actual['weathercode'] as int;
    return (temperatura, codigo);
  }

  Future<String?> _obtenerCiudad(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client'
        '?latitude=$lat&longitude=$lon&localityLanguage=es',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      final data = jsonDecode(response.body);
      return (data['city'] as String?)?.isNotEmpty == true
          ? data['city'] as String
          : data['locality'] as String?;
    } catch (_) {
      return null;
    }
  }

  (String, IconData) _interpretarCodigo(int codigo) {
    if (codigo == 0) return ('Despejado', Icons.wb_sunny);
    if (codigo <= 2) return ('Parcialmente nublado', Icons.wb_cloudy);
    if (codigo == 3) return ('Nublado', Icons.cloud);
    if (codigo == 45 || codigo == 48) return ('Niebla', Icons.foggy);
    if (codigo >= 51 && codigo <= 57) return ('Llovizna', Icons.grain);
    if (codigo >= 61 && codigo <= 67) return ('Lluvia', Icons.water_drop);
    if (codigo >= 71 && codigo <= 77) return ('Nieve', Icons.ac_unit);
    if (codigo >= 80 && codigo <= 82) return ('Chubascos', Icons.grain);
    if (codigo >= 85 && codigo <= 86) return ('Chubascos de nieve', Icons.ac_unit);
    if (codigo >= 95) return ('Tormenta eléctrica', Icons.thunderstorm);
    return ('Clima variable', Icons.cloud);
  }
}
