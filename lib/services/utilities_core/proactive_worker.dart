import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

// Platform interface for Flutter plugin access
class _PlatformBindings {
  static Future<void> ensureInitialized() async {
    // No-op for web/desktop, but provides stable interface
  }
}

const String proactiveTaskName = 'proactiveAiCheckinTask';
const String proactiveTaskUniqueName = 'proactive-ai-checkin';
const String _bgEnabledPrefKey = 'true_background_proactive_enabled';
const String _lastBgRunEpochMsKey = 'bg_proactive_last_run_epoch_ms';
const String _proactiveIntervalSecondsPrefKey = 'proactive_interval_seconds_v2';
const String _lastBgSuccessEpochMsKey = 'bg_proactive_last_success_epoch_ms';
const String _lastBgErrorKey = 'bg_proactive_last_error';
const String _lastBgMessageKey = 'bg_proactive_last_message';
const String _lastBgHealEpochMsKey = 'bg_proactive_last_heal_epoch_ms';
const String _bgHealCountKey = 'bg_proactive_heal_count';

// Retry configuration constants
const int _maxApiRetries = 3;
const Duration _apiTimeout = Duration(seconds: 15);
const Duration _minInterval = Duration(minutes: 15);
const Duration _maxInterval = Duration(hours: 24);

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (kDebugMode) debugPrint('[ProactiveWorker] Native background task triggered: $task');

    int retryCount = 0;
    while (retryCount <= _maxApiRetries) {
      try {
        if (task != proactiveTaskName) {
          return Future.value(true);
        }

        // 1. Initialize dependencies for background isolate with health check
        await _PlatformBindings.ensureInitialized();
        
        // Load environment with retry
        String? dotenvError;
        try {
          await dotenv.load();
        } catch (loadError) {
          dotenvError = loadError.toString();
          if (kDebugMode) debugPrint('[ProactiveWorker] .env load error: $dotenvError');
        }
        
        final prefs = await SharedPreferences.getInstance();

        // Check if true background check-ins are enabled
        final enabled = prefs.getBool(_bgEnabledPrefKey) ?? false;
        if (!enabled) {
          if (kDebugMode) debugPrint('[ProactiveWorker] True background check-ins disabled. Skipping.');
          return Future.value(true);
        }

        // Battery-aware throttling with stale-state detection and self-heal
        final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
        final lastRunEpochMs = prefs.getInt(_lastBgRunEpochMsKey) ?? 0;
        final minIntervalSecs = (prefs.getInt(_proactiveIntervalSecondsPrefKey) ?? _minInterval.inSeconds)
            .clamp(_minInterval.inSeconds, _maxInterval.inSeconds);
        final elapsedSecs = (nowEpochMs - lastRunEpochMs) ~/ 1000;
        
        // Stale-state detection: if scheduler looks stale for more than 48h, re-sync
        if (lastRunEpochMs > 0 && (nowEpochMs - lastRunEpochMs) > 48 * 60 * 60 * 1000) {
          if (kDebugMode) debugPrint('[ProactiveWorker] Detected stale scheduler, re-syncing...');
          await syncProactiveBackgroundSchedule();
          final healPrefs = await SharedPreferences.getInstance();
          await healPrefs.setInt(_lastBgHealEpochMsKey, nowEpochMs);
          final currentHealCount = healPrefs.getInt(_bgHealCountKey) ?? 0;
          await healPrefs.setInt(_bgHealCountKey, currentHealCount + 1);
        }
        
        if (elapsedSecs < minIntervalSecs) {
          if (kDebugMode) {
            debugPrint(
              '[ProactiveWorker] Skipping due to min interval. Elapsed=${elapsedSecs}s, required=${minIntervalSecs}s',
            );
          }
          return Future.value(true);
        }
        await prefs.setInt(_lastBgRunEpochMsKey, nowEpochMs);

        // 2. Fetch API Key and Preferences with retry logic
        String apiKey = '';
        for (int attempt = 0; attempt < _maxApiRetries; attempt++) {
          apiKey = prefs.getString('dev_api_key_override') ?? '';
          if (apiKey.isEmpty) {
            apiKey = dotenv.env['API_KEY'] ?? dotenv.env['GROQ_API_KEY'] ?? '';
          }
          if (apiKey.isNotEmpty) break;
          
          if (kDebugMode) debugPrint('[ProactiveWorker] Attempt ${attempt + 1}: No API key found, retrying...');
          await Future.delayed(Duration(seconds: 1 << attempt)); // Exponential backoff
        }

        if (apiKey.isEmpty) {
          if (kDebugMode) debugPrint('[ProactiveWorker] No API key found after retries. Skipping.');
          await prefs.setString(_lastBgErrorKey, 'No API key found after $_maxApiRetries retries');
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
        
        String activeSysPrompt = 'You are a loving anime companion. Keep it very short (under 15 words) and sweet.';
        if (systemOverride.isNotEmpty) {
          activeSysPrompt = systemOverride;
        }

        const prompt = "[SYSTEM NOTIFICATION: The user hasn't opened the app in a while. Generate an unprompted, warm, and sweet check-in message. Under 15 words. Do not use actions or asterisks.]";

        // 3. Generate Message via API with retry, timeout, and backoff
        http.Response? resp;
        for (int attempt = 0; attempt < _maxApiRetries; attempt++) {
          try {
            resp = await http.post(
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
            ).timeout(_apiTimeout);
            if (resp.statusCode == 200) break;
            await Future.delayed(Duration(seconds: 1 << attempt)); // Exponential backoff
          } on TimeoutException catch (e) {
            if (kDebugMode) debugPrint('[ProactiveWorker] API timeout attempt ${attempt + 1}: $e');
            if (attempt == _maxApiRetries - 1) rethrow;
          }
        }

        if (resp != null && resp.statusCode == 200) {
          final data = (jsonDecode(resp.body) as Map<String, dynamic>).cast<String, dynamic>();
          final aiMessage = data['choices'][0]['message']['content'] as String;
          if (kDebugMode) debugPrint('[ProactiveWorker] Generated message: $aiMessage');

          // 4. Push to Local Notifications with health tracking
          await _showNotification(aiMessage);
          await prefs.setInt(_lastBgSuccessEpochMsKey, nowEpochMs);
          await prefs.setString(_lastBgMessageKey, aiMessage.toString());
          await prefs.remove(_lastBgErrorKey);
          return Future.value(true);
        } else {
          throw Exception('API returned status: ${resp?.statusCode}');
        }
        
      } catch (e) {
        final prefs = await SharedPreferences.getInstance();
        final errorMsg = e.toString();
        await prefs.setString(_lastBgErrorKey, errorMsg);
        if (kDebugMode) debugPrint('[ProactiveWorker] Task failed (attempt ${retryCount + 1}): $errorMsg');
        
        if (retryCount < _maxApiRetries) {
          await Future.delayed(Duration(seconds: 1 << retryCount)); // Exponential backoff
          retryCount++;
          continue;
        }
        return Future.value(true);
      }
    }
    return Future.value(true);
  });
}

Future<Map<String, Object?>> getProactiveBackgroundTelemetry() async {
  final prefs = await SharedPreferences.getInstance();
  return <String, Object?>{
    'enabled': prefs.getBool(_bgEnabledPrefKey) ?? false,
    'intervalSeconds': prefs.getInt(_proactiveIntervalSecondsPrefKey) ?? _minInterval.inSeconds,
    'lastRunEpochMs': prefs.getInt(_lastBgRunEpochMsKey) ?? 0,
    'lastSuccessEpochMs': prefs.getInt(_lastBgSuccessEpochMsKey) ?? 0,
    'lastError': prefs.getString(_lastBgErrorKey) ?? '',
    'lastMessage': prefs.getString(_lastBgMessageKey) ?? '',
    'lastHealEpochMs': prefs.getInt(_lastBgHealEpochMsKey) ?? 0,
    'healCount': prefs.getInt(_bgHealCountKey) ?? 0,
  };
}

Future<void> ensureProactiveBackgroundHealthy() async {
  final telemetry = await getProactiveBackgroundTelemetry();
  final enabled = (telemetry['enabled'] as bool?) ?? false;
  if (!enabled) return;

  final lastRunEpochMs = (telemetry['lastRunEpochMs'] as int?) ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  
  // Self-heal: if scheduler looks stale for more than 48h, re-sync
  if (lastRunEpochMs == 0 || (now - lastRunEpochMs) > 48 * 60 * 60 * 1000) {
    await syncProactiveBackgroundSchedule();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBgHealEpochMsKey, now);
    final currentHealCount = prefs.getInt(_bgHealCountKey) ?? 0;
    await prefs.setInt(_bgHealCountKey, currentHealCount + 1);
  }
}

Future<void> syncProactiveBackgroundSchedule() async {
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool(_bgEnabledPrefKey) ?? false;
  final intervalSecs =
      (prefs.getInt(_proactiveIntervalSecondsPrefKey) ?? 6 * 60 * 60)
          .clamp(15 * 60, 24 * 60 * 60);
  await configureProactiveBackgroundTask(
    enabled: enabled,
    interval: Duration(seconds: intervalSecs),
  );
}

Future<void> configureProactiveBackgroundTask({
  required bool enabled,
  required Duration interval,
}) async {
  await Workmanager().cancelByUniqueName(proactiveTaskUniqueName);
  if (!enabled) return;

  final safeMinutes = interval.inMinutes.clamp(15, 24 * 60);
  await Workmanager().registerPeriodicTask(
    proactiveTaskUniqueName,
    proactiveTaskName,
    frequency: Duration(minutes: safeMinutes),
    flexInterval: const Duration(minutes: 30),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    initialDelay: const Duration(minutes: 15),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 30),
  );
}

Future<void> _showNotification(String message) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_stat_waifu');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  // Required for Android O+
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'true_background_proactive',
    'Background Check-ins',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

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
