import 'dart:convert';
import 'dart:math' as dart_math;
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[ProactiveWorker] Native background task triggered: $task');

    try {
      // 1. Initialize dependencies for background isolate
      WidgetsFlutterBinding.ensureInitialized();
      // If fallback is not a named parameter, some versions of dotenv don't have it. We'll load normally.
      try {
        await dotenv.load();
      } catch (e) {
        debugPrint('[ProactiveWorker] .env load error, might already be populated: $e');
      }
      final prefs = await SharedPreferences.getInstance();

      // Check if true background check-ins are enabled
      final enabled = prefs.getBool('true_background_proactive_enabled') ?? false;
      if (!enabled) {
        debugPrint('[ProactiveWorker] True background check-ins disabled. Skipping.');
        return Future.value(true);
      }

      // 2. Fetch API Key and Preferences
      String apiKey = prefs.getString('dev_api_key_override') ?? '';
      if (apiKey.isEmpty) {
        apiKey = dotenv.env['API_KEY'] ?? dotenv.env['GROQ_API_KEY'] ?? '';
      }

      if (apiKey.isEmpty) {
        debugPrint('[ProactiveWorker] No API key found. Skipping.');
        return Future.value(true);
      }

      String model = prefs.getString('dev_model_override') ?? '';
      if (model.isEmpty) {
        model = dotenv.env['MODEL'] ?? 'llama-3.3-70b-versatile';
      }

      String apiUrl = prefs.getString('dev_api_url_override') ?? '';
      if (apiUrl.isEmpty) {
        apiUrl = dotenv.env['API_URL'] ?? 'https://api.groq.com/openai/v1/chat/completions';
      }

      String systemOverride = prefs.getString('dev_system_query') ?? '';
      
      String activeSysPrompt = "You are a loving anime companion. Keep it very short (under 15 words) and sweet.";
      if (systemOverride.isNotEmpty) {
        activeSysPrompt = systemOverride;
      }

      final prompt = "[SYSTEM NOTIFICATION: The user hasn't opened the app in a while. Generate an unprompted, warm, and sweet check-in message. Under 15 words. Do not use actions or asterisks.]";

      // 3. Generate Message via API
      final resp = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': activeSysPrompt},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
          'max_tokens': 50,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final aiMessage = data['choices'][0]['message']['content'];
        debugPrint('[ProactiveWorker] Generated message: $aiMessage');

        // 4. Push to Local Notifications
        await _showNotification(aiMessage);
      } else {
        debugPrint('[ProactiveWorker] API Error: ${resp.statusCode} ${resp.body}');
      }
      
      // 5. Setup Next Random Loop Check-In!
      final options = [15, 60, 120, 300, 480]; // 15min, 1h, 2h, 5h, 8h in minutes
      final rand = dart_math.Random();
      final nextDelayMinutes = options[rand.nextInt(options.length)];
      
      Workmanager().registerOneOffTask(
        "proactive-ai-checkin",
        "proactiveAiCheckinTask",
        initialDelay: Duration(minutes: nextDelayMinutes),
        constraints: Constraints(
          networkType: NetworkType.connected, 
          requiresBatteryNotLow: true,
        ),
      );
      debugPrint('[ProactiveWorker] Successfully rescheduled next check-in in $nextDelayMinutes minutes.');
    } catch (e) {
      debugPrint('[ProactiveWorker] Task failed: $e');
    }

    return Future.value(true);
  });
}

Future<void> _showNotification(String message) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'true_background_proactive',
    'Background Check-ins',
    channelDescription: 'Notifications sent when the app is completely closed',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'Zero Two Check-in',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    id: 1001,
    title: 'Zero Two',
    body: message,
    notificationDetails: platformChannelSpecifics,
  );
}


