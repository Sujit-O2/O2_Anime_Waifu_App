import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Fetches weather for the device's current GPS location.
  /// Falls back to [fallbackCity] if location permission is denied.
  static Future<String> getWeather([String fallbackCity = 'auto']) async {
    if (_apiKey.isEmpty) {
      return 'Weather API key not set. Add OPENWEATHER_API_KEY to your .env file.';
    }

    try {
      // Try GPS first
      final position = await _getCurrentPosition();
      if (position != null) {
        return await _fetchByCoords(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('WeatherService GPS error: $e');
    }

    // GPS unavailable — fall back to city if provided, else skip
    if (fallbackCity == 'auto' || fallbackCity.trim().isEmpty) {
      return 'Location unavailable. Enable GPS or provide a city name.';
    }
    return await _fetchByCity(fallbackCity.trim());
  }

  /// Request location permissions and get current position.
  static Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('WeatherService: Location services disabled.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('WeatherService: Location permission denied.');
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('WeatherService: Location permission permanently denied.');
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // city-level is enough for weather
        timeLimit: Duration(seconds: 8),
      ),
    );
  }

  /// Fetch weather by lat/lon using OpenWeatherMap.
  static Future<String> _fetchByCoords(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=en',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return _parseWeather(jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        return 'Weather fetch failed (${res.statusCode}).';
      }
    } catch (e) {
      debugPrint('WeatherService coord fetch error: $e');
      return 'Could not reach the weather service. Check your internet.';
    }
  }

  /// Fetch weather by city name (fallback).
  static Future<String> _fetchByCity(String city) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeQueryComponent(city)}&appid=$_apiKey&units=metric&lang=en',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return _parseWeather(jsonDecode(res.body) as Map<String, dynamic>);
      } else if (res.statusCode == 404) {
        return 'Could not find weather for "$city".';
      } else {
        return 'Weather fetch failed (${res.statusCode}).';
      }
    } catch (e) {
      debugPrint('WeatherService city fetch error: $e');
      return 'Could not reach the weather service. Check your internet.';
    }
  }

  /// Parse OpenWeatherMap JSON into a human-readable string.
  static String _parseWeather(Map<String, dynamic> data) {
    final name = data['name'] ?? 'Your Location';
    final main = data['main'] as Map<String, dynamic>?;
    final weather =
        (data['weather'] as List?)?.first as Map<String, dynamic>?;
    final temp = main?['temp']?.toStringAsFixed(1) ?? '?';
    final feels = main?['feels_like']?.toStringAsFixed(1) ?? '?';
    final humidity = main?['humidity']?.toString() ?? '?';
    final desc = weather?['description'] ?? 'unknown';
    final wind = (data['wind'] as Map?)?['speed']?.toString() ?? '?';
    return '📍 $name: $desc, $temp°C (feels $feels°C), humidity $humidity%, wind $wind m/s.';
  }
}
