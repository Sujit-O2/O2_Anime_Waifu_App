import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OpenWeatherMap integration with fallback location.
class WeatherService {
  String _defaultCity = 'Bhubaneswar';
  double? _lat;
  double? _lon;

  set defaultCity(String city) => _defaultCity = city;

  String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  Future<Map<String, dynamic>?> getWeather({String? city}) async {
    if (_apiKey.isEmpty) return null;

    final targetCity = city ?? _defaultCity;
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$targetCity&appid=$_apiKey&units=metric',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> getWeatherSummary({String? city}) async {
    final data = await getWeather(city: city);
    if (data == null) return 'Weather data unavailable.';

    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final temp = main['temp'];
    final feelsLike = main['feels_like'];
    final description = weather['description'];
    final humidity = main['humidity'];

    return 'Current weather: $description, ${temp}°C (feels like ${feelsLike}°C), humidity: $humidity%.';
  }
}
