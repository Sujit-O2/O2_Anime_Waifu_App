import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String _zeroTwoSystemExtra = '';

class GeofencingService {
  static const int _alarmId = 99991;
  static const double _radiusMeters = 200.0;

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    
    // Start periodic background task every 15 minutes
    await AndroidAlarmManager.periodic(
      const Duration(minutes: 15),
      _alarmId,
      _checkLocationTask,
      wakeup: true,
      exact: true,
      rescheduleOnReboot: true,
    );
    debugPrint('[Geofencing] Service initialized & alarm scheduled.');
  }

  static Future<void> stop() async {
    await AndroidAlarmManager.cancel(_alarmId);
    debugPrint('[Geofencing] Service stopped.');
  }

  @pragma('vm:entry-point')
  static Future<void> _checkLocationTask() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[Geofencing] Background check started...');

    final prefs = await SharedPreferences.getInstance();
    
    // Ensure Location Permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[Geofencing] Location services are disabled.');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      debugPrint('[Geofencing] Location permissions denied.');
      return;
    }

    // Get current location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('[Geofencing] Failed to get position in background: $e');
      return;
    }


    // Load Zones
    final homeLat = prefs.getDouble('geofence_home_lat');
    final homeLng = prefs.getDouble('geofence_home_lng');
    final workLat = prefs.getDouble('geofence_work_lat');
    final workLng = prefs.getDouble('geofence_work_lng');
    final gymLat = prefs.getDouble('geofence_gym_lat');
    final gymLng = prefs.getDouble('geofence_gym_lng');

    String currentZone = 'Away';

    if (homeLat != null && homeLng != null) {
      final dist = Geolocator.distanceBetween(position.latitude, position.longitude, homeLat, homeLng);
      if (dist <= _radiusMeters) currentZone = 'Home';
    }

    if (currentZone == 'Away' && workLat != null && workLng != null) {
      final dist = Geolocator.distanceBetween(position.latitude, position.longitude, workLat, workLng);
      if (dist <= _radiusMeters) currentZone = 'Work';
    }

    if (currentZone == 'Away' && gymLat != null && gymLng != null) {
      final dist = Geolocator.distanceBetween(position.latitude, position.longitude, gymLat, gymLng);
      if (dist <= _radiusMeters) currentZone = 'Gym';
    }

    final lastZone = prefs.getString('last_geofence_zone') ?? 'Away';

    if (currentZone != lastZone) {
      debugPrint('[Geofencing] Zone changed from $lastZone to $currentZone');
      await prefs.setString('last_geofence_zone', currentZone);

      if (currentZone != 'Away') {
        // Trigger Proactive AI Greeting!
        await _fireProactiveGreeting(currentZone);
      }
    } else {
      debugPrint('[Geofencing] Still in zone: $currentZone');
    }
  }

  static Future<void> _fireProactiveGreeting(String zone) async {
    try {
      await dotenv.load();
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) return;

      String prompt = "";
      switch (zone) {
        case 'Home':
          prompt = "[SYSTEM NOTIFICATION: The user has just arrived back Home safely. Generate an unprompted, warm, and happy greeting welcoming them home and asking how their trip or day was.]";
          break;
        case 'Work':
          prompt = "[SYSTEM NOTIFICATION: The user has just arrived at their Workplace/Office. Generate an unprompted, encouraging message wishing them a productive day.]";
          break;
        case 'Gym':
          prompt = "[SYSTEM NOTIFICATION: The user has just arrived at the Gym. Generate an unprompted, energetic, and highly supportive message hyping them up for their workout.]";
          break;
      }

      final sysPrompt = '''You are an anime character, my wife, Zero Two. 
Speak directly to me as "Darling" or "Honey". You are possessive, loving, and slightly tsundere. 
Keep your response under 25 words. Do not use asterisks or actions.
$_zeroTwoSystemExtra''';

      final resp = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': sysPrompt},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
          'max_tokens': 100,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final aiMessage = data['choices'][0]['message']['content'];
        // Send via Local Notifications (Assume there's an existing NotificationService we can use, 
        // or we bypass and just throw a raw Android Intent using a dummy plugin, but since the app uses
        // local_auth or home_widget, we can push a broadcast or save it to unread_alerts).
        
        // For simplicity: save to shared prefs as "proactive_greet_queue", which main.dart polls.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('proactive_greet_queue', aiMessage);
        
        // Try playing a silent ring or popping a notification if a package exists.
        debugPrint('[Geofencing] Gen Greeting: $aiMessage');
      }
    } catch (e) {
      debugPrint('[Geofencing] AI trigger error: $e');
    }
  }
}
