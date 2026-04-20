import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _wttrBaseUrl = 'https://wttr.in';

  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  static bool get isConfigured => _apiKey.isNotEmpty;

  static Future<String> getWeather([String fallbackCity = 'auto']) async {
    Position? position;
    try {
      position = await _getCurrentPosition();
    } catch (e) {
      debugPrint('WeatherService GPS error: $e');
    }

    if (_apiKey.isNotEmpty) {
      if (position != null) {
        final byCoords = await _fetchByCoords(
          position.latitude,
          position.longitude,
        );
        if (byCoords != null) {
          return byCoords;
        }
      }

      if (fallbackCity != 'auto' && fallbackCity.trim().isNotEmpty) {
        final byCity = await _fetchByCity(fallbackCity.trim());
        if (byCity != null) {
          return byCity;
        }
      }
    }

    if (position != null) {
      final wttrByCoords =
          await _fetchWttr('${position.latitude},${position.longitude}');
      if (wttrByCoords != null) {
        return wttrByCoords;
      }
    }

    if (fallbackCity != 'auto' && fallbackCity.trim().isNotEmpty) {
      final wttrByCity = await _fetchWttr(fallbackCity.trim());
      if (wttrByCity != null) {
        return wttrByCity;
      }
    }

    return 'Weather unavailable right now. Enable GPS or provide a city name.';
  }

  static Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 8),
      ),
    );
  }

  static Future<String?> _fetchByCoords(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=en',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return _parseOpenWeather(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('WeatherService coord fetch error: $e');
    }
    return null;
  }

  static Future<String?> _fetchByCity(String city) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeQueryComponent(city)}&appid=$_apiKey&units=metric&lang=en',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return _parseOpenWeather(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('WeatherService city fetch error: $e');
    }
    return null;
  }

  static Future<String?> _fetchWttr(String location) async {
    try {
      final uri = Uri.parse(
        '$_wttrBaseUrl/${Uri.encodeComponent(location)}?format=j1',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return _parseWttr(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('WeatherService wttr fetch error: $e');
    }
    return null;
  }

  static String _parseOpenWeather(Map<String, dynamic> data) {
    final name = data['name']?.toString() ?? 'Your Location';
    final main = data['main'] as Map<String, dynamic>? ?? const {};
    final weather =
        (data['weather'] as List?)?.first as Map<String, dynamic>? ?? const {};
    final temp = (main['temp'] as num?)?.toStringAsFixed(1) ?? '?';
    final feels = (main['feels_like'] as num?)?.toStringAsFixed(1) ?? '?';
    final humidity = main['humidity']?.toString() ?? '?';
    final desc = weather['description']?.toString() ?? 'unknown';
    final wind = (data['wind'] as Map?)?['speed']?.toString() ?? '?';
    return '$name: $desc, $temp C (feels $feels C), humidity $humidity%, wind $wind m/s.';
  }

  static String _parseWttr(Map<String, dynamic> data) {
    final current =
        (data['current_condition'] as List?)?.first as Map<String, dynamic>? ??
            const {};
    final nearestArea =
        (data['nearest_area'] as List?)?.first as Map<String, dynamic>? ??
            const {};
    final areaName = ((nearestArea['areaName'] as List?)?.first
                as Map<String, dynamic>?)?['value']
            ?.toString() ??
        'Your Location';
    final weather = ((current['weatherDesc'] as List?)?.first
                as Map<String, dynamic>?)?['value']
            ?.toString() ??
        'unknown';
    final temp = current['temp_C']?.toString() ?? '?';
    final feels = current['FeelsLikeC']?.toString() ?? '?';
    final humidity = current['humidity']?.toString() ?? '?';
    final wind = current['windspeedKmph']?.toString() ?? '?';
    return '$areaName: $weather, $temp C (feels $feels C), humidity $humidity%, wind $wind km/h.';
  }
}


