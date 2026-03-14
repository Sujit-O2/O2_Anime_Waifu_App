import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Open-Meteo weather service — completely free, no API key required.
///
/// Call [fetch] once on app start, then read [current] anywhere.
/// Location defaults to Bangalore, India; call [updateLocation] to
/// pass real GPS coordinates before fetching.
///
/// [WeatherData.summary] returns a compact string suitable for
/// [LauncherClockWidget.weatherSummary].
class WeatherService {
  WeatherService._();
  static final instance = WeatherService._();

  static const _cacheKey = 'weather_json_v2';
  static const _cacheTsKey = 'weather_ts_v2';
  static const _ttlMs = 30 * 60 * 1000; // 30 min

  double _lat = 12.9716; // Bangalore fallback
  double _lon = 77.5946;

  WeatherData? _last;
  WeatherData? get current => _last;

  void updateLocation(double lat, double lon) {
    _lat = lat;
    _lon = lon;
  }

  Future<WeatherData?> fetch({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Serve cache if fresh
    if (!forceRefresh) {
      final ts = prefs.getInt(_cacheTsKey) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - ts < _ttlMs) {
        final raw = prefs.getString(_cacheKey);
        if (raw != null) {
          try {
            _last = WeatherData.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
            return _last;
          } catch (_) {}
        }
      }
    }

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$_lat'
        '&longitude=$_lon'
        '&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m'
        '&temperature_unit=celsius'
        '&wind_speed_unit=kmh'
        '&timezone=auto',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return _last;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final cur = json['current'] as Map<String, dynamic>;

      _last = WeatherData(
        tempC: (cur['temperature_2m'] as num).toDouble(),
        code: (cur['weather_code'] as num).toInt(),
        windKmh: (cur['wind_speed_10m'] as num).toDouble(),
        humidity: (cur['relative_humidity_2m'] as num).toInt(),
        fetchedAt: DateTime.now(),
      );

      await prefs.setString(_cacheKey, jsonEncode(_last!.toJson()));
      await prefs.setInt(
          _cacheTsKey, DateTime.now().millisecondsSinceEpoch);
      return _last;
    } catch (e) {
      debugPrint('[Weather] fetch error: $e');
      return _last;
    }
  }

  /// Also keep the old [getWeather] method (AI tool dispatcher calls it)
  static Future<String> getWeather(String city) async =>
      instance.current?.summary ?? 'Weather data not yet loaded.';
}

class WeatherData {
  final double tempC;
  final int code;
  final double windKmh;
  final int humidity;
  final DateTime fetchedAt;

  const WeatherData({
    required this.tempC,
    required this.code,
    required this.windKmh,
    required this.humidity,
    required this.fetchedAt,
  });

  static ({String label, String emoji}) _describe(int code) {
    if (code == 0) return (label: 'Clear', emoji: '☀️');
    if (code <= 2) return (label: 'Partly Cloudy', emoji: '🌤');
    if (code == 3) return (label: 'Overcast', emoji: '☁️');
    if (code <= 49) return (label: 'Foggy', emoji: '🌫');
    if (code <= 57) return (label: 'Drizzle', emoji: '🌦');
    if (code <= 67) return (label: 'Rain', emoji: '🌧');
    if (code <= 77) return (label: 'Snow', emoji: '❄️');
    if (code <= 82) return (label: 'Showers', emoji: '🌧');
    if (code <= 86) return (label: 'Snow Showers', emoji: '🌨');
    if (code <= 99) return (label: 'Thunderstorm', emoji: '⛈');
    return (label: 'Unknown', emoji: '🌈');
  }

  String get emoji => _describe(code).emoji;
  String get label => _describe(code).label;

  /// One-liner for the clock widget (e.g. "28°C ☀️ Clear")
  String get summary => '${tempC.round()}°C $emoji $label';

  Map<String, dynamic> toJson() => {
        'tempC': tempC,
        'code': code,
        'windKmh': windKmh,
        'humidity': humidity,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory WeatherData.fromJson(Map<String, dynamic> j) => WeatherData(
        tempC: (j['tempC'] as num).toDouble(),
        code: j['code'] as int,
        windKmh: (j['windKmh'] as num).toDouble(),
        humidity: j['humidity'] as int,
        fetchedAt: DateTime.parse(j['fetchedAt'] as String),
      );
}
