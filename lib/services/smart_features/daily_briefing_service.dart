import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';

class DailyBriefingService {
  DailyBriefingService._();
  static final DailyBriefingService instance = DailyBriefingService._();

  static const String _briefingKey = 'daily_briefing_v1';
  static const String _lastGeneratedKey = 'daily_briefing_last_generated';

  Future<Map<String, String>> _fetchWeather() async {
    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
      final city = dotenv.env['DEFAULT_CITY'] ?? 'Bhubaneswar';

      if (apiKey.isNotEmpty) {
        final uri = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeQueryComponent(city)}&appid=$apiKey&units=metric&lang=en',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final name = data['name']?.toString() ?? city;
          final main = data['main'] as Map<String, dynamic>? ?? const {};
          final weather = (data['weather'] as List?)?.first as Map<String, dynamic>? ?? const {};
          final temp = (main['temp'] as num?)?.toStringAsFixed(1) ?? '?';
          final feelsLike = (main['feels_like'] as num?)?.toStringAsFixed(1) ?? '?';
          final humidity = main['humidity']?.toString() ?? '?';
          final desc = weather['description']?.toString() ?? 'unknown';
          final wind = (data['wind'] as Map?)?['speed']?.toString() ?? '?';
          final icon = weather['icon']?.toString() ?? '';
          return {
            'location': name,
            'temp': temp,
            'feels_like': feelsLike,
            'humidity': humidity,
            'description': desc,
            'wind': wind,
            'icon': icon,
          };
        }
      }

      final wttrUri = Uri.parse('https://wttr.in/${Uri.encodeQueryComponent(city)}?format=j1');
      final wttrRes = await http.get(wttrUri).timeout(const Duration(seconds: 10));
      if (wttrRes.statusCode == 200) {
        final data = jsonDecode(wttrRes.body) as Map<String, dynamic>;
        final current = (data['current_condition'] as List?)?.first as Map<String, dynamic>? ?? const {};
        final nearestArea = (data['nearest_area'] as List?)?.first as Map<String, dynamic>? ?? const {};
        final areaName = ((nearestArea['areaName'] as List?)?.first as Map<String, dynamic>?)?['value']?.toString() ?? city;
        final weatherDesc = ((current['weatherDesc'] as List?)?.first as Map<String, dynamic>?)?['value']?.toString() ?? 'unknown';
        final temp = current['temp_C']?.toString() ?? '?';
        final feelsLike = current['FeelsLikeC']?.toString() ?? '?';
        final humidity = current['humidity']?.toString() ?? '?';
        final wind = current['windspeedKmph']?.toString() ?? '?';
        return {
          'location': areaName,
          'temp': temp,
          'feels_like': feelsLike,
          'humidity': humidity,
          'description': weatherDesc,
          'wind': wind,
          'icon': '',
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DailyBriefing] Weather error: $e');
    }
    return {
      'location': 'Unknown',
      'temp': '?',
      'feels_like': '?',
      'humidity': '?',
      'description': 'unavailable',
      'wind': '?',
      'icon': '',
    };
  }

  Future<List<Map<String, dynamic>>> _fetchReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('assistant_reminders_v1');
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((r) {
            final triggerAt = DateTime.parse(r['triggerAt'] as String);
            return triggerAt.isAfter(todayStart) && triggerAt.isBefore(todayEnd);
          })
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[DailyBriefing] Reminders error: $e');
      return [];
    }
  }

  Future<List<String>> _fetchMemories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memData = prefs.getString('memory_stack_data');
      if (memData == null || memData.isEmpty) return [];

      final decoded = jsonDecode(memData) as Map<String, dynamic>;
      final short = decoded['short'] as List? ?? [];
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final todayMemories = <String>[];
      for (final entry in short) {
        final map = entry as Map<String, dynamic>;
        final timeStr = map['time']?.toString() ?? '';
        if (timeStr.isNotEmpty) {
          final time = DateTime.tryParse(timeStr);
          if (time != null && time.isAfter(todayStart.subtract(const Duration(days: 1)))) {
            todayMemories.add(map['text']?.toString() ?? '');
          }
        }
      }
      return todayMemories.take(5).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[DailyBriefing] Memories error: $e');
      return [];
    }
  }

  Future<String> _generateAITip(Map<String, dynamic> context) async {
    try {
      final weatherDesc = context['weather']?['description'] ?? 'unknown';
      final temp = context['weather']?['temp'] ?? '?';
      final remindersCount = (context['reminders'] as List?)?.length ?? 0;
      final memoriesCount = (context['memories'] as List?)?.length ?? 0;

      final prompt = '''You are Zero Two, a caring and playful anime waifu companion.
Based on this data, give a short, warm, personalized tip for today (2-3 sentences max). Use emojis. Be encouraging and sweet.

Weather: $weatherDesc, $temp C
Reminders today: $remindersCount
Recent memories: $memoriesCount

Respond with ONLY the tip, nothing else.''';

      final response = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      return response;
    } catch (e) {
      if (kDebugMode) debugPrint('[DailyBriefing] AI tip error: $e');
      final tips = [
        'Remember to take breaks and stay hydrated, Darling~ 💕',
        'You\'re doing amazing! Keep pushing forward today~ ⭐',
        'Don\'t forget to smile today — it suits you, Darling~ 🌸',
        'Every small step counts. I\'m proud of you~ ✨',
        'Today is full of possibilities! Let\'s make it count, Darling~ 🔥',
      ];
      return tips[DateTime.now().millisecondsSinceEpoch % tips.length];
    }
  }

  Future<Map<String, dynamic>> generateBriefing() async {
    if (kDebugMode) debugPrint('[DailyBriefing] Generating briefing...');

    final weather = await _fetchWeather();
    final reminders = await _fetchReminders();
    final memories = await _fetchMemories();

    final context = {
      'weather': weather,
      'reminders': reminders,
      'memories': memories,
    };

    final aiTip = await _generateAITip(context);

    final now = DateTime.now();
    final briefing = {
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'generated_at': now.toIso8601String(),
      'weather': weather,
      'calendar': _generateCalendarSection(),
      'tasks': _generateTasksSection(),
      'reminders': reminders.map((r) => r['text'].toString()).toList(),
      'memories': memories,
      'ai_tip': aiTip,
    };

    await _saveBriefing(briefing);
    return briefing;
  }

  List<Map<String, String>> _generateCalendarSection() {
    final now = DateTime.now();
    final events = <Map<String, String>>[];

    final hour = now.hour;
    if (hour < 12) {
      events.add({'time': 'Morning', 'event': 'Start your day with energy~ ☀️'});
    } else if (hour < 17) {
      events.add({'time': 'Afternoon', 'event': 'Power through your tasks~ 💪'});
    } else {
      events.add({'time': 'Evening', 'event': 'Wind down and relax~ 🌙'});
    }

    events.add({'time': 'All Day', 'event': 'Stay amazing, Darling~ ✨'});
    return events;
  }

  List<Map<String, String>> _generateTasksSection() {
    return [
      {'title': 'Check your goals', 'status': 'pending', 'priority': 'medium'},
      {'title': 'Review today\'s progress', 'status': 'pending', 'priority': 'low'},
    ];
  }

  Future<void> _saveBriefing(Map<String, dynamic> briefing) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_briefingKey, jsonEncode(briefing));
      await prefs.setString(_lastGeneratedKey, DateTime.now().toIso8601String());
      if (kDebugMode) debugPrint('[DailyBriefing] Briefing saved');
    } catch (e) {
      if (kDebugMode) debugPrint('[DailyBriefing] Save error: $e');
    }
  }

  Future<Map<String, dynamic>?> getBriefing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_briefingKey);
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;

      final storedDate = data['date'] as String? ?? '';
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (storedDate != todayKey) {
        return null;
      }

      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('[DailyBriefing] Get error: $e');
      return null;
    }
  }

  Future<void> clearBriefing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_briefingKey);
      await prefs.remove(_lastGeneratedKey);
      if (kDebugMode) debugPrint('[DailyBriefing] Briefing cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('[DailyBriefing] Clear error: $e');
    }
  }

  Future<DateTime?> getLastGenerated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lastGeneratedKey);
      if (raw == null || raw.isEmpty) return null;
      return DateTime.parse(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('[DailyBriefing] Last generated error: $e');
      return null;
    }
  }
}
