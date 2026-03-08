import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'weather_service.dart';
import 'memory_service.dart';
import 'mood_service.dart';
import 'quote_service.dart';
import 'reminder_service.dart';
import 'news_service.dart';
import 'contacts_lookup_service.dart';
import 'affection_service.dart';

class OpenAppActionResult {
  final bool launched;
  final String assistantMessage;

  const OpenAppActionResult({
    required this.launched,
    required this.assistantMessage,
  });
}

/// Handles all structured AI assistant actions parsed from reply text.
class OpenAppService {
  static const MethodChannel _nativeChannel =
      MethodChannel('anime_waifu/assistant_mode');

  // ─── Regex helpers ──────────────────────────────────────────────────────────

  static RegExp _actionPattern(String actionName) => RegExp(
        r'Action\s*:\s*' + RegExp.escape(actionName),
        caseSensitive: false,
      );

  static String? _extractField(String reply, String fieldName) {
    final pattern = RegExp(
      r'^' + RegExp.escape(fieldName) + r'\s*:\s*(.+?)\s*$',
      caseSensitive: false,
      multiLine: true,
    );
    final match = pattern.firstMatch(reply);
    return match?.group(1)?.trim();
  }

  // ─── 1. OPEN_APP ────────────────────────────────────────────────────────────

  static final RegExp _openActionPattern =
      RegExp(r'Action\s*:\s*open[\s_-]*app', caseSensitive: false);
  static final RegExp _appLinePattern =
      RegExp(r'^\s*App\s*:\s*(.+?)\s*$', caseSensitive: false, multiLine: true);
  static final RegExp _appInlinePattern = RegExp(
      r'Action\s*:\s*open[\s_-]*app[\s\S]*?App\s*:\s*([^\r\n]+)',
      caseSensitive: false);

  static Future<OpenAppActionResult?> handleAssistantReply(String reply) async {
    if (!_openActionPattern.hasMatch(reply)) return null;
    final appName = _extractAppName(reply);
    if (appName == null || appName.isEmpty) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'Which app, Darling? I need a name.');
    }
    if (!Platform.isAndroid) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'App launching only works on Android.');
    }
    try {
      final res = await _nativeChannel
          .invokeMethod<String>('openAppByName', {'query': appName});
      if (res != null && res.trim().isNotEmpty) {
        return OpenAppActionResult(
            launched: true, assistantMessage: 'Opened ${_titleCase(appName)}.');
      }
    } catch (_) {}
    return OpenAppActionResult(
        launched: false,
        assistantMessage:
            'Could not open ${_titleCase(appName)}. Is it installed?');
  }

  static String? _extractAppName(String reply) {
    final line = _appLinePattern.firstMatch(reply)?.group(1)?.trim();
    if (line != null && line.isNotEmpty) return _sanitizeValue(line);
    final inline = _appInlinePattern.firstMatch(reply)?.group(1)?.trim();
    if (inline != null && inline.isNotEmpty) return _sanitizeValue(inline);
    return null;
  }

  // ─── 2. CALL_NUMBER ─────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleCallAction(String reply) async {
    if (!_actionPattern('CALL_NUMBER').hasMatch(reply)) return null;
    final number = _extractField(reply, 'Number');
    if (number == null || number.isEmpty) {
      return const OpenAppActionResult(
          launched: false, assistantMessage: 'Who should I call, Darling?');
    }

    // Check if it's a name (no digits) — look up in contacts first
    String dialTarget = number;
    final isName = !RegExp(r'\d').hasMatch(number);
    if (isName) {
      final resolved = await ContactsLookupService.resolvePhoneNumber(number);
      if (resolved != null && resolved.isNotEmpty) {
        dialTarget = resolved;
      } else {
        // No contact found — dial raw (Android may handle name query)
        dialTarget = number;
      }
    } else {
      dialTarget = number.replaceAll(RegExp(r'[^\d+\s\-()]'), '').trim();
      if (dialTarget.isEmpty) dialTarget = number;
    }

    try {
      final uri = Uri(scheme: 'tel', path: dialTarget);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return OpenAppActionResult(
            launched: true, assistantMessage: 'Calling $number now.');
      }
    } catch (_) {}
    return OpenAppActionResult(
        launched: false,
        assistantMessage: 'Could not open the dialer for $number.');
  }

  // ─── 3. WEB_SEARCH ──────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleWebSearchAction(
      String reply) async {
    if (!_actionPattern('WEB_SEARCH').hasMatch(reply)) return null;
    final query = _extractField(reply, 'Query');
    if (query == null || query.isEmpty) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'What should I search for, Darling?');
    }
    try {
      final uri = Uri.parse(
          'https://www.google.com/search?q=${Uri.encodeQueryComponent(query)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return OpenAppActionResult(
            launched: true, assistantMessage: 'Searching for "$query".');
      }
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not open the browser.');
  }

  // ─── 4. OPEN_URL ────────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleOpenUrlAction(String reply) async {
    if (!_actionPattern('OPEN_URL').hasMatch(reply)) return null;
    var url = _extractField(reply, 'Url') ?? _extractField(reply, 'URL');
    if (url == null || url.isEmpty) {
      return const OpenAppActionResult(
          launched: false, assistantMessage: 'Which website, Darling?');
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return OpenAppActionResult(
            launched: true, assistantMessage: 'Opening $url.');
      }
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not open that URL.');
  }

  // ─── 5. MAPS_NAVIGATE ───────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleMapsAction(String reply) async {
    if (!_actionPattern('MAPS_NAVIGATE').hasMatch(reply)) return null;
    final place = _extractField(reply, 'Place') ??
        _extractField(reply, 'Location') ??
        _extractField(reply, 'Destination');
    if (place == null || place.isEmpty) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'Where do you want to go, Darling?');
    }
    try {
      final encoded = Uri.encodeQueryComponent(place);
      final geoUri = Uri.parse('geo:0,0?q=$encoded');
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return OpenAppActionResult(
            launched: true, assistantMessage: 'Navigating to $place.');
      }
      final mapsUri = Uri.parse('https://www.google.com/maps/search/$encoded');
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      return OpenAppActionResult(
          launched: true, assistantMessage: 'Opening maps for $place.');
    } catch (_) {}
    return OpenAppActionResult(
        launched: false, assistantMessage: 'Could not open maps for $place.');
  }

  // ─── 6. SET_ALARM ───────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleSetAlarmAction(String reply) async {
    if (!_actionPattern('SET_ALARM').hasMatch(reply)) return null;
    final timeStr = _extractField(reply, 'Time');
    if (timeStr == null || timeStr.isEmpty) {
      return const OpenAppActionResult(
          launched: false, assistantMessage: 'What time, Darling?');
    }

    int hour, minute;
    String displayStr;

    // First try relative time: "in 10 minutes", "after 1 hour 30 minutes"
    final relativeSeconds = _parseRelativeToSeconds(timeStr);
    if (relativeSeconds != null && relativeSeconds > 0) {
      final target = DateTime.now().add(Duration(seconds: relativeSeconds));
      hour = target.hour;
      minute = target.minute;
      final h = relativeSeconds ~/ 3600;
      final m = (relativeSeconds % 3600) ~/ 60;
      displayStr = h > 0 ? (m > 0 ? 'in ${h}h ${m}m' : 'in ${h}h') : 'in ${m}m';
    } else {
      // Try absolute time: "7:30 AM", "7am", "19:00" etc.
      final parsed = _parseTime(timeStr);
      if (parsed == null) {
        return OpenAppActionResult(
            launched: false,
            assistantMessage:
                'I didn\'t understand "$timeStr". Try "7:30 AM" or "in 10 minutes".');
      }
      hour = parsed.$1;
      minute = parsed.$2;
      displayStr = timeStr;
    }

    try {
      final ok = await _nativeChannel.invokeMethod<bool>('setAlarm',
          {'hour': hour, 'minute': minute, 'message': 'Zero Two Alarm'});
      if (ok == true) {
        return OpenAppActionResult(
            launched: true,
            assistantMessage: 'Alarm set $displayStr, Darling.');
      }
    } catch (_) {}
    return OpenAppActionResult(
        launched: false,
        assistantMessage: 'Could not set alarm for $displayStr.');
  }

  /// Parses relative duration strings like "in 10 minutes", "after 1 hour 30 min"
  static int? _parseRelativeToSeconds(String input) {
    final s = input.toLowerCase();
    // Only treat as relative if there's an explicit relative keyword
    if (!s.contains('in ') &&
        !s.contains('after') &&
        !s.contains('min') &&
        !s.contains('hour') &&
        !s.contains('sec')) {
      return null;
    }
    int total = 0;
    final mHrs = RegExp(r'(\d+)\s*(?:hour|hr)').firstMatch(s);
    final mMin = RegExp(r'(\d+)\s*min').firstMatch(s);
    final mSec = RegExp(r'(\d+)\s*sec').firstMatch(s);
    if (mHrs != null) total += int.parse(mHrs.group(1)!) * 3600;
    if (mMin != null) total += int.parse(mMin.group(1)!) * 60;
    if (mSec != null) total += int.parse(mSec.group(1)!);
    return total > 0 ? total : null;
  }

  // ─── 7. SET_TIMER ───────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleSetTimerAction(String reply) async {
    if (!_actionPattern('SET_TIMER').hasMatch(reply)) return null;
    final durationStr = _extractField(reply, 'Duration');
    if (durationStr == null || durationStr.isEmpty) {
      return const OpenAppActionResult(
          launched: false, assistantMessage: 'For how long, Darling?');
    }
    final seconds = _parseDurationToSeconds(durationStr);
    if (seconds == null || seconds <= 0) {
      return OpenAppActionResult(
          launched: false,
          assistantMessage:
              'I didn\'t understand "$durationStr". Try "5 minutes".');
    }
    try {
      final ok = await _nativeChannel.invokeMethod<bool>(
          'setTimer', {'seconds': seconds, 'message': 'Zero Two Timer'});
      if (ok == true) {
        return OpenAppActionResult(
            launched: true, assistantMessage: 'Timer set for $durationStr.');
      }
    } catch (_) {}
    return OpenAppActionResult(
        launched: false, assistantMessage: 'Could not set timer.');
  }

  // ─── 8. SHARE_TEXT ──────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleShareAction(String reply) async {
    if (!_actionPattern('SHARE_TEXT').hasMatch(reply)) return null;
    final text =
        _extractField(reply, 'Text') ?? _extractField(reply, 'Content');
    if (text == null || text.isEmpty) {
      return const OpenAppActionResult(
          launched: false, assistantMessage: 'What should I share, Darling?');
    }
    try {
      await _nativeChannel.invokeMethod('shareText', {'text': text});
      return const OpenAppActionResult(
          launched: true, assistantMessage: 'Sharing that for you.');
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not open the share menu.');
  }

  // ─── 11. OPEN_CALENDAR ──────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleOpenCalendarAction(
      String reply) async {
    if (!_actionPattern('OPEN_CALENDAR').hasMatch(reply)) return null;
    try {
      final ok = await _nativeChannel.invokeMethod<bool>(
        'openResolvedIntent',
        {
          'action': 'android.intent.action.MAIN',
          'category': 'android.intent.category.APP_CALENDAR',
          'data': null
        },
      );
      if (ok == true) {
        return const OpenAppActionResult(
            launched: true, assistantMessage: 'Opening calendar.');
      }
      // Fallback to package name
      await _nativeChannel
          .invokeMethod<String>('openAppByName', {'query': 'calendar'});
      return const OpenAppActionResult(
          launched: true, assistantMessage: 'Opening calendar.');
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not open the calendar.');
  }

  // ─── 12. FLASHLIGHT ─────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleFlashlightAction(
      String reply) async {
    final turnOn = _actionPattern('FLASHLIGHT_ON').hasMatch(reply);
    final turnOff = _actionPattern('FLASHLIGHT_OFF').hasMatch(reply);
    if (!turnOn && !turnOff) return null;

    // Ensure CAMERA permission is granted (required for setTorchMode)
    if (Platform.isAndroid) {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          return OpenAppActionResult(
              launched: false,
              assistantMessage:
                  'Camera permission is needed to control the flashlight. Please grant it in Settings.');
        }
      }
    }

    try {
      final ok = await _nativeChannel
          .invokeMethod<bool>('toggleFlashlight', {'on': turnOn});
      if (ok == true) {
        return OpenAppActionResult(
            launched: true,
            assistantMessage: turnOn ? 'Flashlight on.' : 'Flashlight off.');
      }
    } catch (_) {}
    return OpenAppActionResult(
        launched: false,
        assistantMessage:
            'Could not ${turnOn ? 'turn on' : 'turn off'} the flashlight.');
  }

  // ─── 13. BATTERY_STATUS ─────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleBatteryAction(String reply) async {
    if (!_actionPattern('BATTERY_STATUS').hasMatch(reply)) return null;
    try {
      final level = await _nativeChannel.invokeMethod<int>('getBatteryLevel');
      if (level != null) {
        final emoji = level >= 80
            ? '🔋'
            : level >= 40
                ? '⚡'
                : '🪫';
        return OpenAppActionResult(
            launched: true, assistantMessage: '$emoji Battery is at $level%.');
      }
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not read battery level.');
  }

  // ─── 14. VOLUME_SET ─────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleVolumeAction(String reply) async {
    if (!_actionPattern('VOLUME_SET').hasMatch(reply)) return null;
    final levelStr = _extractField(reply, 'Level');
    if (levelStr == null) {
      return const OpenAppActionResult(
          launched: false, assistantMessage: 'What volume level, Darling?');
    }
    final level = int.tryParse(levelStr.replaceAll('%', '').trim());
    if (level == null || level < 0 || level > 100) {
      return const OpenAppActionResult(
          launched: false, assistantMessage: 'Volume must be 0–100%.');
    }
    try {
      await _nativeChannel.invokeMethod('setVolume', {'level': level});
      return OpenAppActionResult(
          launched: true, assistantMessage: 'Volume set to $level%.');
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not change the volume.');
  }

  // ─── 15. WIFI_CHECK ─────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleWifiCheckAction(
      String reply) async {
    if (!_actionPattern('WIFI_CHECK').hasMatch(reply)) return null;
    try {
      final connected =
          await _nativeChannel.invokeMethod<bool>('isWifiConnected') ?? false;
      return OpenAppActionResult(
          launched: true,
          assistantMessage: connected
              ? '📶 Connected to WiFi.'
              : '📵 Not connected to WiFi right now.');
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not check WiFi status.');
  }

  // ─── 16. MUSIC (play/pause/next/prev) ───────────────────────────────────────

  static Future<OpenAppActionResult?> handleMusicAction(String reply) async {
    String? action;
    String? query;
    String? app;
    if (_actionPattern('MUSIC_PLAY').hasMatch(reply)) {
      action = 'play';
      query = _extractField(reply, 'Query') ?? _extractField(reply, 'Song');
      app = _extractField(reply, 'App');
    } else if (_actionPattern('MUSIC_PAUSE').hasMatch(reply)) {
      action = 'pause';
    } else if (_actionPattern('MUSIC_NEXT').hasMatch(reply)) {
      action = 'next';
    } else if (_actionPattern('MUSIC_PREV').hasMatch(reply)) {
      action = 'prev';
    } else {
      return null;
    }

    try {
      if (action == 'play' && query != null && query.isNotEmpty) {
        // Try to open Spotify or YT Music with the query
        final appLower = (app ?? '').toLowerCase();
        String deepLink;
        if (appLower.contains('spotify')) {
          deepLink = 'spotify:search:${Uri.encodeComponent(query)}';
        } else if (appLower.contains('youtube')) {
          deepLink =
              'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent(query)}';
        } else {
          // Default: YouTube Music search
          deepLink =
              'https://music.youtube.com/search?q=${Uri.encodeQueryComponent(query)}';
        }
        final uri = Uri.parse(deepLink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return OpenAppActionResult(
              launched: true, assistantMessage: 'Playing "$query".');
        }
      }
      // Media key control
      await _nativeChannel.invokeMethod('mediaControl', {'action': action});
      final msg = action == 'pause'
          ? 'Music paused.'
          : action == 'next'
              ? 'Next track.'
              : action == 'prev'
                  ? 'Previous track.'
                  : 'Music control applied.';
      return OpenAppActionResult(launched: true, assistantMessage: msg);
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not control music.');
  }

  // ─── 17. GET_WEATHER ────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleWeatherAction(String reply) async {
    if (!_actionPattern('GET_WEATHER').hasMatch(reply)) return null;
    final city = _extractField(reply, 'City') ?? 'current location';
    final weatherText = await WeatherService.getWeather(city);
    return OpenAppActionResult(launched: true, assistantMessage: weatherText);
  }

  // ─── 18. SET_REMINDER ────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleReminderAction(String reply) async {
    if (!_actionPattern('SET_REMINDER').hasMatch(reply)) return null;
    final text =
        _extractField(reply, 'Text') ?? _extractField(reply, 'Message');
    final delayStr =
        _extractField(reply, 'Delay') ?? _extractField(reply, 'In');
    if (text == null || text.isEmpty) {
      return const OpenAppActionResult(
          launched: false, assistantMessage: 'What should I remind you about?');
    }
    final delayMinutes =
        delayStr != null ? ReminderService.parseDelayMinutes(delayStr) : null;
    if (delayMinutes == null) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'When should I remind you? Try "in 30 minutes".');
    }
    final result = await ReminderService.scheduleReminder(
        text: text, delayMinutes: delayMinutes);
    return OpenAppActionResult(launched: true, assistantMessage: result);
  }

  // ─── 19. MEMORY_SAVE ────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleMemorySaveAction(
      String reply) async {
    if (!_actionPattern('MEMORY_SAVE').hasMatch(reply)) return null;
    final key = _extractField(reply, 'Key') ?? _extractField(reply, 'Fact');
    final value = _extractField(reply, 'Value') ?? _extractField(reply, 'Info');
    if (key == null || value == null) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'Could not parse what to remember.');
    }
    await MemoryService.saveFact(key, value);
    return OpenAppActionResult(
        launched: true,
        assistantMessage: 'I will remember that "$key" is "$value".');
  }

  // ─── 20. MEMORY_RECALL ──────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleMemoryRecallAction(
      String reply) async {
    if (!_actionPattern('MEMORY_RECALL').hasMatch(reply)) return null;
    final key = _extractField(reply, 'Key') ?? _extractField(reply, 'Fact');
    if (key == null) {
      final all = await MemoryService.getAllFacts();
      if (all.isEmpty) {
        return const OpenAppActionResult(
            launched: true,
            assistantMessage:
                'I don\'t remember anything special yet, Darling.');
      }
      final text = all.entries.map((e) => '• ${e.key}: ${e.value}').join('\n');
      return OpenAppActionResult(
          launched: true, assistantMessage: 'Here\'s what I remember:\n$text');
    }
    final value = await MemoryService.getFact(key);
    if (value == null) {
      return OpenAppActionResult(
          launched: true,
          assistantMessage: 'I don\'t remember anything about "$key" yet.');
    }
    return OpenAppActionResult(
        launched: true, assistantMessage: '"$key" is "$value".');
  }

  // ─── 21. DAILY_SUMMARY ──────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleDailySummaryAction(
      String reply) async {
    if (!_actionPattern('DAILY_SUMMARY').hasMatch(reply)) return null;
    final city = _extractField(reply, 'City') ?? 'Bhubaneswar';
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${_dayName(now.weekday)}, ${now.day} ${_monthName(now.month)} ${now.year}';
    final weather = await WeatherService.getWeather(city);
    final reminders = await ReminderService.getAllReminders();
    final pending = reminders
        .where((r) => !r.fired && r.triggerAt.isAfter(now))
        .take(3)
        .toList();
    String reminderText = pending.isEmpty
        ? 'No pending reminders.'
        : pending.map((r) => '• ${r.text}').join('\n');

    final summary = '''📅 $dateStr
🕐 Time: $timeStr

🌤️ Weather: $weather

⏰ Reminders:
$reminderText''';

    return OpenAppActionResult(launched: true, assistantMessage: summary);
  }

  // ─── 22. GET_NEWS ─────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleNewsAction(String reply) async {
    if (!_actionPattern('GET_NEWS').hasMatch(reply)) return null;
    final newsText = await NewsService.getTopHeadlines();
    if (newsText == null || newsText.isEmpty) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'I could not fetch the latest news at the moment.');
    }
    return OpenAppActionResult(
        launched: true,
        assistantMessage: 'Here are the top headlines:\n$newsText');
  }

  // ─── 23. YOUTUBE_PLAY ───────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleYoutubeAction(String reply) async {
    if (!_actionPattern('YOUTUBE_PLAY').hasMatch(reply)) return null;
    final query = _extractField(reply, 'Query') ??
        _extractField(reply, 'Song') ??
        _extractField(reply, 'Video');
    if (query == null || query.isEmpty) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'What should I play on YouTube, Darling?');
    }
    try {
      // Try YouTube app deep link first
      final ytApp = Uri.parse(
          'vnd.youtube://results?search_query=${Uri.encodeQueryComponent(query)}');
      if (await canLaunchUrl(ytApp)) {
        await launchUrl(ytApp, mode: LaunchMode.externalApplication);
        return OpenAppActionResult(
            launched: true, assistantMessage: 'Searching "$query" on YouTube.');
      }
      // Fallback to browser
      final ytWeb = Uri.parse(
          'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent(query)}');
      await launchUrl(ytWeb, mode: LaunchMode.externalApplication);
      return OpenAppActionResult(
          launched: true, assistantMessage: 'Opening YouTube for "$query".');
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not open YouTube.');
  }

  // ─── 23. WHATSAPP_MSG ───────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleWhatsAppAction(String reply) async {
    if (!_actionPattern('WHATSAPP_MSG').hasMatch(reply)) return null;
    final to = _extractField(reply, 'To') ?? _extractField(reply, 'Number');
    final text =
        _extractField(reply, 'Text') ?? _extractField(reply, 'Message') ?? '';
    try {
      // wa.me with number (international format recommended)
      final number = to?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
      final encodedText = Uri.encodeQueryComponent(text);
      if (number.isNotEmpty) {
        final uri = Uri.parse('https://wa.me/$number?text=$encodedText');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return OpenAppActionResult(
              launched: true, assistantMessage: 'Opening WhatsApp to $to.');
        }
      }
      // Fallback: open WhatsApp share sheet with just text
      final shareUri = Uri.parse('whatsapp://send?text=$encodedText');
      if (await canLaunchUrl(shareUri)) {
        await launchUrl(shareUri, mode: LaunchMode.externalApplication);
        return const OpenAppActionResult(
            launched: true, assistantMessage: 'Opening WhatsApp.');
      }
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false,
        assistantMessage: 'Could not open WhatsApp. Is it installed?');
  }

  // ─── 24. DND_TOGGLE ─────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleDndAction(String reply) async {
    final enable = _actionPattern('DND_ON').hasMatch(reply);
    final disable = _actionPattern('DND_OFF').hasMatch(reply);
    if (!enable && !disable) return null;
    try {
      // Open notification policy access settings — user must toggle manually
      // (Programmatic DND requires MANAGE_NOTIFICATION_POLICY permission)
      final ok = await _nativeChannel.invokeMethod<bool>(
        'openResolvedIntent',
        {
          'action': 'android.settings.NOTIFICATION_POLICY_ACCESS_SETTINGS',
          'category': null
        },
      );
      if (ok == true) {
        return OpenAppActionResult(
            launched: true,
            assistantMessage: enable
                ? 'Opening DND settings. Toggle it on there, Darling.'
                : 'Opening DND settings. Toggle it off there, Darling.');
      }
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false, assistantMessage: 'Could not open DND settings.');
  }

  // ─── 25. ADD_CALENDAR_EVENT ─────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleCalendarEventAction(
      String reply) async {
    if (!_actionPattern('ADD_CALENDAR_EVENT').hasMatch(reply)) return null;
    final title =
        _extractField(reply, 'Title') ?? _extractField(reply, 'Event');
    final date = _extractField(reply, 'Date');
    final time = _extractField(reply, 'Time');
    if (title == null || title.isEmpty) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'What event should I add, Darling?');
    }
    try {
      // Build calendar insert intent via platform channel
      final ok = await _nativeChannel.invokeMethod<bool>(
        'addCalendarEvent',
        {'title': title, 'date': date ?? '', 'time': time ?? ''},
      );
      if (ok == true) {
        return OpenAppActionResult(
            launched: true,
            assistantMessage: 'Adding "$title" to your calendar.');
      }
    } catch (_) {}
    // Fallback: open calendar
    try {
      await _nativeChannel.invokeMethod<bool>(
        'openResolvedIntent',
        {
          'action': 'android.intent.action.MAIN',
          'category': 'android.intent.category.APP_CALENDAR'
        },
      );
    } catch (_) {}
    return OpenAppActionResult(
        launched: true, assistantMessage: 'Opening calendar for "$title".');
  }

  /// Parses many time formats: "7am", "7:30 AM", "7 30 pm", "730", "19:00", "7.30PM"
  static (int, int)? _parseTime(String input) {
    final s = input.trim().toUpperCase().replaceAll('.', ':');

    // Patterns to try in order:
    // 1) "7:30 AM" or "7:30AM" or "7:30"
    // 2) "730" (HHMM digits only)
    // 3) "7 30 AM" or "7 AM"
    // 4) "7am", "7pm"

    // Extract optional AM/PM suffix
    final hasPm = s.contains('PM');
    final hasAm = s.contains('AM');
    final cleaned = s.replaceAll(RegExp(r'[AP]M'), '').trim();

    int hour = -1;
    int minute = 0;

    // Colon-separated "H:MM"
    if (cleaned.contains(':')) {
      final parts = cleaned.split(':');
      hour = int.tryParse(parts[0].trim()) ?? -1;
      minute = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
    }
    // Space-separated "H MM" or just "H"
    else if (cleaned.contains(' ')) {
      final parts = cleaned.split(RegExp(r'\s+'));
      hour = int.tryParse(parts[0]) ?? -1;
      minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    }
    // 3-4 digit compact "730" or "1230"
    else if (cleaned.length == 3 || cleaned.length == 4) {
      final raw = int.tryParse(cleaned);
      if (raw != null) {
        hour = raw ~/ 100;
        minute = raw % 100;
      }
    }
    // Plain number  "7"
    else {
      hour = int.tryParse(cleaned) ?? -1;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    // Apply AM/PM
    if (hasPm && hour < 12) hour += 12;
    if (hasAm && hour == 12) hour = 0;

    return (hour, minute);
  }

  // ─── TRANSLATE ───────────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleTranslateAction(
      String reply) async {
    if (!_actionPattern('TRANSLATE').hasMatch(reply)) return null;
    final text = _extractField(reply, 'Text');
    final lang = _extractField(reply, 'Language') ??
        _extractField(reply, 'Lang') ??
        'en';
    if (text == null || text.isEmpty) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'What should I translate, Darling?');
    }
    try {
      final encoded = Uri.encodeQueryComponent(text);
      final uri = Uri.parse(
          'https://api.mymemory.translated.net/get?q=$encoded&langpair=auto|${Uri.encodeQueryComponent(lang)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final translated =
            data['responseData']?['translatedText']?.toString() ?? '';
        if (translated.isNotEmpty && translated != text) {
          return OpenAppActionResult(
              launched: true, assistantMessage: 'Translation: **$translated**');
        }
      }
    } catch (_) {}
    return const OpenAppActionResult(
        launched: false,
        assistantMessage:
            'Sorry Darling, translation failed. Check your internet connection.');
  }

  // ─── POMODORO ────────────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handlePomodoroAction(String reply) async {
    if (!_actionPattern('POMODORO').hasMatch(reply)) return null;
    final durationStr = _extractField(reply, 'Duration') ?? '25';
    final minutes =
        int.tryParse(durationStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 25;
    // Set alarm via native channel for (now + minutes)
    try {
      final targetTime = DateTime.now().add(Duration(minutes: minutes));
      await _nativeChannel.invokeMethod('setAlarm', {
        'hour': targetTime.hour,
        'minute': targetTime.minute,
        'label': 'Pomodoro Session Complete 🍅',
      });
      return OpenAppActionResult(
          launched: true,
          assistantMessage:
              '🍅 Pomodoro started! I\'ll remind you in $minutes minutes, Darling. Stay focused~ 💪');
    } catch (_) {}
    return OpenAppActionResult(
        launched: false,
        assistantMessage:
            'Starting your $minutes-minute focus session now, Darling! Go get \'em~ 🍅');
  }

  // ─── TRACK_MOOD ──────────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleMoodAction(String reply) async {
    if (!_actionPattern('TRACK_MOOD').hasMatch(reply)) return null;
    final mood = _extractField(reply, 'Mood') ??
        _extractField(reply, 'Feeling') ??
        'Neutral';
    await MoodService.saveMood(mood);
    return OpenAppActionResult(
        launched: true,
        assistantMessage:
            'Noted, Darling! I\'ve logged your mood as "$mood". I\'ll keep track of how you\'re feeling 💕');
  }

  // ─── GET_QUOTE ───────────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleQuoteAction(String reply) async {
    if (!_actionPattern('GET_QUOTE').hasMatch(reply)) return null;
    final type = (_extractField(reply, 'Type') ?? 'daily').toLowerCase();
    final quote = type.contains('zero') || type.contains('gacha')
        ? QuoteService.getRandomZeroTwoQuote()
        : QuoteService.getDailyQuote();
    return OpenAppActionResult(launched: true, assistantMessage: quote);
  }

  // ─── CLIPBOARD_READ ──────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleClipboardAction(
      String reply) async {
    if (!_actionPattern('CLIPBOARD_READ').hasMatch(reply)) return null;
    try {
      final data = await _nativeChannel.invokeMethod<String>('getClipboard');
      if (data != null && data.isNotEmpty) {
        return OpenAppActionResult(
            launched: true, assistantMessage: 'Your clipboard says: "$data"');
      }
      return const OpenAppActionResult(
          launched: true,
          assistantMessage: 'Your clipboard is empty, Darling.');
    } catch (_) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage:
              'I couldn\'t read your clipboard this time, Darling.');
    }
  }

  // ─── SUMMARIZE_CHAT ──────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleSummarizeChatAction(
      String reply) async {
    if (!_actionPattern('SUMMARIZE_CHAT').hasMatch(reply)) return null;
    // Returns a trigger — actual summarization is done in main.dart
    return const OpenAppActionResult(
        launched: true, assistantMessage: '__SUMMARIZE_CHAT__');
  }

  // ─── EXPORT_CHAT ─────────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleExportChatAction(
      String reply) async {
    if (!_actionPattern('EXPORT_CHAT').hasMatch(reply)) return null;
    // Returns a trigger — actual export is done in main.dart with access to _messages
    return const OpenAppActionResult(
        launched: true, assistantMessage: '__EXPORT_CHAT__');
  }

  // ─── READ_NOTIFICATIONS ──────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleReadNotificationsAction(
      String reply) async {
    if (!_actionPattern('READ_NOTIFICATIONS').hasMatch(reply)) return null;
    try {
      final List<dynamic>? notifs =
          await _nativeChannel.invokeMethod('getRecentNotifications');
      if (notifs == null || notifs.isEmpty) {
        return const OpenAppActionResult(
            launched: true,
            assistantMessage: 'No recent notifications, Darling.');
      }
      final lines =
          notifs.take(5).map((n) => '• ${n['app']}: ${n['text']}').join('\n');
      return OpenAppActionResult(
          launched: true,
          assistantMessage: 'Here are your recent notifications:\n$lines');
    } catch (_) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage:
              'I need notification access to read those. Please grant it in Settings → Notification Access.');
    }
  }

  // ─── READ_SMS ────────────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleReadSmsAction(String reply) async {
    if (!_actionPattern('READ_SMS').hasMatch(reply)) return null;
    final contact =
        _extractField(reply, 'Contact') ?? _extractField(reply, 'From');
    try {
      final Map<dynamic, dynamic>? result = await _nativeChannel.invokeMethod(
          'getLastSms', contact != null ? {'contact': contact} : null);
      if (result != null) {
        final from = result['from']?.toString() ?? 'Unknown';
        final body = result['body']?.toString() ?? '';
        return OpenAppActionResult(
            launched: true, assistantMessage: 'Last SMS from $from: "$body"');
      }
      return const OpenAppActionResult(
          launched: true, assistantMessage: 'No messages found, Darling.');
    } catch (_) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage:
              'I need SMS read permission. Please grant READ_SMS in app permissions.');
    }
  }

  // ─── LOOKUP_CONTACT ──────────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleContactLookupAction(
      String reply) async {
    if (!_actionPattern('LOOKUP_CONTACT').hasMatch(reply)) return null;
    final name =
        _extractField(reply, 'Name') ?? _extractField(reply, 'Contact');
    if (name == null || name.isEmpty) {
      return const OpenAppActionResult(
          launched: false, assistantMessage: 'Who should I look up, Darling?');
    }
    try {
      final Map<dynamic, dynamic>? result =
          await _nativeChannel.invokeMethod('lookupContact', {'name': name});
      if (result != null) {
        final fullName = result['name']?.toString() ?? name;
        final phone = result['phone']?.toString() ?? 'No number';
        return OpenAppActionResult(
            launched: true, assistantMessage: '$fullName: $phone');
      }
      return OpenAppActionResult(
          launched: true,
          assistantMessage:
              'I couldn\'t find anyone named "$name" in your contacts.');
    } catch (_) {
      return const OpenAppActionResult(
          launched: false,
          assistantMessage: 'I need contacts permission to look that up.');
    }
  }

  static int? _parseDurationToSeconds(String input) {
    final s = input.toLowerCase().trim();
    final mSec = RegExp(r'(\d+)\s*sec').firstMatch(s);
    final mMin = RegExp(r'(\d+)\s*min').firstMatch(s);
    final mHrs = RegExp(r'(\d+)\s*hour').firstMatch(s);
    int total = 0;
    if (mHrs != null) total += int.parse(mHrs.group(1)!) * 3600;
    if (mMin != null) total += int.parse(mMin.group(1)!) * 60;
    if (mSec != null) total += int.parse(mSec.group(1)!);
    return total > 0 ? total : null;
  }

  static String _dayName(int wd) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][wd - 1];

  static String _monthName(int m) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];

  static String _sanitizeValue(String value) {
    return value
        .trim()
        .replaceAll(RegExp("^[\"']+"), '')
        .replaceAll(RegExp("[\"']+\$"), '')
        .replaceAll(RegExp(r'[\.;,\)\]]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((word) {
      final lower = word.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.length > 1 ? lower.substring(1) : ''}';
    }).join(' ');
  }

  // ─── 42. MORNING_ROUTINE ──────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleMorningRoutine(String reply) async {
    if (!_actionPattern('MORNING_ROUTINE').hasMatch(reply)) return null;

    String weatherInfo = "It looks nice outside.";
    try {
      final w = await WeatherService.getWeather("Bhubaneswar");
      weatherInfo = w;
    } catch (_) {}

    String quoteInfo = "";
    try {
      final q = QuoteService.getDailyQuote();
      quoteInfo = "\n\nQuote for today: \"$q\"";
    } catch (_) {}

    // Reward for checking in morning
    await AffectionService.instance.addPoints(10);

    return OpenAppActionResult(
        launched: false,
        assistantMessage:
            "Good morning, Darling! ☀️\n\nWeather today: $weatherInfo$quoteInfo\n\nLet's make today wonderful!");
  }

  // ─── 43. NIGHT_ROUTINE ────────────────────────────────────────────────────

  static Future<OpenAppActionResult?> handleNightRoutine(String reply) async {
    if (!_actionPattern('NIGHT_ROUTINE').hasMatch(reply)) return null;

    // Reward for checking in before bed
    await AffectionService.instance.addPoints(10);

    return OpenAppActionResult(
        launched: false,
        assistantMessage:
            "Good night, Darling. 🌙 You did great today. Get some rest, and I'll be right here waiting for you tomorrow.");
  }
}
