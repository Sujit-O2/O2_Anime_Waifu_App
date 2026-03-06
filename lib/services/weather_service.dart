import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Fetches weather for [city]. Returns a human-readable string.
  static Future<String> getWeather(String city) async {
    if (_apiKey.isEmpty) {
      return 'Weather API key not set. Add OPENWEATHER_API_KEY to your .env file.';
    }
    final safeCity = city.trim().isEmpty ? 'Bhubaneswar' : city.trim();
    try {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeQueryComponent(safeCity)}&appid=$_apiKey&units=metric',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final name = data['name'] ?? safeCity;
        final main = data['main'] as Map<String, dynamic>?;
        final weather =
            (data['weather'] as List?)?.first as Map<String, dynamic>?;
        final temp = main?['temp']?.toStringAsFixed(1) ?? '?';
        final feels = main?['feels_like']?.toStringAsFixed(1) ?? '?';
        final humidity = main?['humidity']?.toString() ?? '?';
        final desc = weather?['description'] ?? 'unknown';
        final wind = (data['wind'] as Map?)?['speed']?.toString() ?? '?';
        return '📍 $name: $desc, ${temp}°C (feels ${feels}°C), humidity ${humidity}%, wind ${wind} m/s.';
      } else if (res.statusCode == 404) {
        return 'Could not find weather for "$safeCity". Try a different city name.';
      } else {
        return 'Weather fetch failed (${res.statusCode}).';
      }
    } catch (e) {
      debugPrint('WeatherService error: $e');
      return 'Could not reach the weather service. Check your internet.';
    }
  }
}
