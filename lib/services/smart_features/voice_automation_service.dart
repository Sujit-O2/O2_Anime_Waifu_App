import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class VoiceCommandEntry {
  final String rawText;
  final String actionType;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final bool success;

  VoiceCommandEntry({
    required this.rawText,
    required this.actionType,
    required this.parameters,
    required this.timestamp,
    required this.success,
  });

  Map<String, dynamic> toJson() => {
        'rawText': rawText,
        'actionType': actionType,
        'parameters': parameters,
        'timestamp': timestamp.toIso8601String(),
        'success': success,
      };

  factory VoiceCommandEntry.fromJson(Map<String, dynamic> json) =>
      VoiceCommandEntry(
        rawText: json['rawText'] as String? ?? '',
        actionType: json['actionType'] as String? ?? '',
        parameters:
            Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        success: json['success'] as bool? ?? false,
      );
}

class VoiceAutomationService {
  static final VoiceAutomationService instance =
      VoiceAutomationService._internal();
  factory VoiceAutomationService() => instance;
  VoiceAutomationService._internal();

  static const String _historyKey = 'voice_automation_history';
  static const int _maxHistory = 50;

  final List<VoiceCommandEntry> _localHistory = [];

  final List<Map<String, dynamic>> _commands = [
    {
      'id': 'call',
      'label': 'Call',
      'icon': 'Icons.phone',
      'description': 'Call a contact or number',
      'examples': ['call mom', 'call 911'],
      'color': 0xFF4CAF50,
    },
    {
      'id': 'message',
      'label': 'Message',
      'icon': 'Icons.message',
      'description': 'Send a message via WhatsApp or SMS',
      'examples': ['message john hello', 'send message to sarah'],
      'color': 0xFF2196F3,
    },
    {
      'id': 'open_app',
      'label': 'Open App',
      'icon': 'Icons.apps',
      'description': 'Open any installed app',
      'examples': ['open whatsapp', 'launch youtube'],
      'color': 0xFF9C27B0,
    },
    {
      'id': 'set_reminder',
      'label': 'Set Reminder',
      'icon': 'Icons.notifications',
      'description': 'Create a reminder with time',
      'examples': ['remind me to drink water in 30 minutes'],
      'color': 0xFFFF9800,
    },
    {
      'id': 'play_music',
      'label': 'Play Music',
      'icon': 'Icons.music_note',
      'description': 'Play music on Spotify or YouTube',
      'examples': ['play lofi music', 'play despacito on spotify'],
      'color': 0xFFE91E63,
    },
    {
      'id': 'search',
      'label': 'Search',
      'icon': 'Icons.search',
      'description': 'Search the web via Google',
      'examples': ['search anime news', 'google best restaurants'],
      'color': 0xFF00BCD4,
    },
    {
      'id': 'weather',
      'label': 'Weather',
      'icon': 'Icons.wb_sunny',
      'description': 'Check current weather',
      'examples': ['weather today', 'whats the weather in tokyo'],
      'color': 0xFFFFC107,
    },
    {
      'id': 'alarm',
      'label': 'Alarm',
      'icon': 'Icons.alarm',
      'description': 'Set an alarm for a specific time',
      'examples': ['set alarm for 7 am', 'wake me at 6:30'],
      'color': 0xFFF44336,
    },
    {
      'id': 'note',
      'label': 'Note',
      'icon': 'Icons.note_add',
      'description': 'Save a quick note',
      'examples': ['note buy groceries', 'save this idea for later'],
      'color': 0xFF607D8B,
    },
    {
      'id': 'email',
      'label': 'Email',
      'icon': 'Icons.email',
      'description': 'Open email or compose new email',
      'examples': ['open gmail', 'email john about the meeting'],
      'color': 0xFF3F51B5,
    },
  ];

  Future<void> _initLocalHistory() async {
    if (_localHistory.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getStringList(_historyKey) ?? [];
        for (final item in raw) {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          _localHistory.add(VoiceCommandEntry.fromJson(decoded));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('VoiceAutomationService history load error: $e');
      }
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _localHistory
          .take(_maxHistory)
          .map((e) => jsonEncode(e.toJson()))
          .toList();
      await prefs.setStringList(_historyKey, raw);
    } catch (e) {
      if (kDebugMode) debugPrint('VoiceAutomationService history save error: $e');
    }
  }

  Future<Map<String, dynamic>> processVoiceCommand(String command) async {
    await _initLocalHistory();
    final lower = command.trim().toLowerCase();
    final result = _parseCommand(lower);

    final entry = VoiceCommandEntry(
      rawText: command,
      actionType: result['actionType'] as String,
      parameters:
          Map<String, dynamic>.from(result['parameters'] as Map? ?? {}),
      timestamp: DateTime.now(),
      success: result['actionType'] != 'unknown',
    );

    _localHistory.insert(0, entry);
    if (_localHistory.length > _maxHistory) {
      _localHistory.removeRange(_maxHistory, _localHistory.length);
    }
    await _saveHistory();

    return result;
  }

  Future<bool> executeAction(String actionType, Map<String, dynamic> params) async {
    try {
      switch (actionType) {
        case 'call':
          return await _executeCall(params);
        case 'message':
          return await _executeMessage(params);
        case 'open_app':
          return await _executeOpenApp(params);
        case 'set_reminder':
          return await _executeReminder(params);
        case 'play_music':
          return await _executePlayMusic(params);
        case 'search':
          return await _executeSearch(params);
        case 'weather':
          return await _executeWeather(params);
        case 'alarm':
          return await _executeAlarm(params);
        case 'note':
          return await _executeNote(params);
        case 'email':
          return await _executeEmail(params);
        default:
          return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('VoiceAutomationService execute error: $e');
      return false;
    }
  }

  Future<List<VoiceCommandEntry>> getCommandHistory() async {
    await _initLocalHistory();
    return List.unmodifiable(_localHistory);
  }

  Future<void> clearCommandHistory() async {
    _localHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  List<Map<String, dynamic>> getAvailableCommands() {
    return List.unmodifiable(_commands);
  }

  Map<String, dynamic> _parseCommand(String text) {
    if (text.isEmpty) {
      return {'actionType': 'unknown', 'parameters': <String, dynamic>{}};
    }

    final callMatch = RegExp(
            r'(?:call|dial|ring)\s+(.+?)(?:\s+please|\s+now|\s*$)',
            caseSensitive: false)
        .firstMatch(text);
    if (callMatch != null) {
      return {
        'actionType': 'call',
        'parameters': {'query': callMatch.group(1)?.trim() ?? ''},
      };
    }

    final msgMatch = RegExp(
            r'(?:message|msg|send message|text)\s+(?:to\s+)?(\w+)\s+(.*)',
            caseSensitive: false)
        .firstMatch(text);
    if (msgMatch != null) {
      return {
        'actionType': 'message',
        'parameters': {
          'recipient': msgMatch.group(1)?.trim() ?? '',
          'body': msgMatch.group(2)?.trim() ?? '',
        },
      };
    }

    final openMatch = RegExp(
            r'(?:open|launch|start)\s+(.+?)(?:\s+please|\s+now|\s*$)',
            caseSensitive: false)
        .firstMatch(text);
    if (openMatch != null &&
        !openMatch.group(1)!.contains(RegExp(r'gmail|mail|email'))) {
      return {
        'actionType': 'open_app',
        'parameters': {'app_name': openMatch.group(1)?.trim() ?? ''},
      };
    }

    final reminderMatch = RegExp(
            r'(?:remind|reminder|set reminder)\s+(?:me\s+)?(?:to\s+)?(.+?)(?:\s+in\s+(\d+\s*\w+))?',
            caseSensitive: false)
        .firstMatch(text);
    if (reminderMatch != null) {
      return {
        'actionType': 'set_reminder',
        'parameters': {
          'text': reminderMatch.group(1)?.trim() ?? '',
          'delay': reminderMatch.group(2)?.trim() ?? 'in 30 minutes',
        },
      };
    }

    final musicMatch = RegExp(
            r'(?:play|listen to)\s+(?:some\s+|the\s+)?(?:music|song|songs)?\s*(.+?)(?:\s+on\s+(\w+))?$',
            caseSensitive: false)
        .firstMatch(text);
    if (musicMatch != null &&
        (text.contains('play') || text.contains('listen'))) {
      return {
        'actionType': 'play_music',
        'parameters': {
          'query': musicMatch.group(1)?.trim() ?? 'popular songs',
          'platform': musicMatch.group(2)?.trim().toLowerCase() ?? 'spotify',
        },
      };
    }

    final searchMatch = RegExp(
            r'(?:search|google|look up|find)\s+(?:for\s+|on google\s+)?(.+)$',
            caseSensitive: false)
        .firstMatch(text);
    if (searchMatch != null) {
      return {
        'actionType': 'search',
        'parameters': {'query': searchMatch.group(1)?.trim() ?? ''},
      };
    }

    final weatherMatch = RegExp(
            r'(?:weather|temperature|mausam)(?:\s+in\s+(.+?))?(?:\s+today|\s+now)?$',
            caseSensitive: false)
        .firstMatch(text);
    if (weatherMatch != null) {
      return {
        'actionType': 'weather',
        'parameters': {
          'location': weatherMatch.group(1)?.trim() ?? 'current location',
        },
      };
    }

    final alarmMatch = RegExp(
            r'(?:set alarm|alarm|wake me)\s+(?:at|for)?\s*(.+?)(?:\s+am|\s+pm|\s*$)',
            caseSensitive: false)
        .firstMatch(text);
    if (alarmMatch != null) {
      var timeStr = alarmMatch.group(1)?.trim() ?? '';
      if (text.contains('am') && !timeStr.toLowerCase().endsWith('am')) {
        timeStr = '$timeStr am';
      }
      if (text.contains('pm') && !timeStr.toLowerCase().endsWith('pm')) {
        timeStr = '$timeStr pm';
      }
      return {
        'actionType': 'alarm',
        'parameters': {'time': timeStr},
      };
    }

    final noteMatch = RegExp(
            r'(?:note|save note|take note)\s+(?:down\s+)?(.+)$',
            caseSensitive: false)
        .firstMatch(text);
    if (noteMatch != null) {
      return {
        'actionType': 'note',
        'parameters': {'content': noteMatch.group(1)?.trim() ?? ''},
      };
    }

    final emailMatch = RegExp(
            r'(?:email|mail|gmail)(?:\s+(?:to\s+)?(\w+))?(?:\s+(?:about|regarding|say)\s+(.+))?$',
            caseSensitive: false)
        .firstMatch(text);
    if (emailMatch != null) {
      return {
        'actionType': 'email',
        'parameters': {
          'recipient': emailMatch.group(1)?.trim() ?? '',
          'subject': emailMatch.group(2)?.trim() ?? '',
        },
      };
    }

    return {'actionType': 'unknown', 'parameters': <String, dynamic>{}};
  }

  Future<bool> _executeCall(Map<String, dynamic> params) async {
    final query = params['query'] as String? ?? '';
    if (query.isEmpty) return false;
    final uri = query.contains(RegExp(r'\d'))
        ? Uri.parse('tel:${Uri.encodeComponent(query)}')
        : Uri.parse(
            'https://www.google.com/search?q=call+${Uri.encodeComponent(query)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _executeMessage(Map<String, dynamic> params) async {
    final recipient = params['recipient'] as String? ?? '';
    final body = params['body'] as String? ?? '';
    if (recipient.isEmpty) return false;
    final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent('$body - for $recipient')}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _executeOpenApp(Map<String, dynamic> params) async {
    final appName = params['app_name'] as String? ?? '';
    if (appName.isEmpty) return false;
    final lowerName = appName.toLowerCase();
    final appUrls = {
      'whatsapp': 'https://wa.me',
      'youtube': 'https://youtube.com',
      'spotify': 'https://open.spotify.com',
      'instagram': 'https://instagram.com',
      'twitter': 'https://twitter.com',
      'facebook': 'https://facebook.com',
      'telegram': 'https://t.me',
      'gmail': 'https://mail.google.com',
      'maps': 'https://maps.google.com',
      'google maps': 'https://maps.google.com',
      'chrome': 'https://google.com',
      'netflix': 'https://netflix.com',
      'amazon': 'https://amazon.com',
      'tiktok': 'https://tiktok.com',
      'discord': 'https://discord.com',
      'reddit': 'https://reddit.com',
    };
    for (final entry in appUrls.entries) {
      if (lowerName.contains(entry.key)) {
        return launchUrl(Uri.parse(entry.value),
            mode: LaunchMode.externalApplication);
      }
    }
    return launchUrl(
        Uri.parse(
            'https://www.google.com/search?q=${Uri.encodeComponent(appName)}+app'),
        mode: LaunchMode.externalApplication);
  }

  Future<bool> _executeReminder(Map<String, dynamic> params) async {
    final reminderText = params['text'] as String? ?? '';
    final delay = params['delay'] as String? ?? 'in 30 minutes';
    if (reminderText.isEmpty) return false;
    final uri = Uri.parse(
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent('Reminder: $reminderText')}&details=${Uri.encodeComponent('Set via voice: $delay')}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _executePlayMusic(Map<String, dynamic> params) async {
    final query = params['query'] as String? ?? '';
    final platform = params['platform'] as String? ?? 'spotify';
    final encodedQuery = Uri.encodeComponent(query);
    final uri = platform.contains('youtube')
        ? Uri.parse('https://www.youtube.com/results?search_query=$encodedQuery')
        : Uri.parse('https://open.spotify.com/search/$encodedQuery');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _executeSearch(Map<String, dynamic> params) async {
    final query = params['query'] as String? ?? '';
    if (query.isEmpty) return false;
    final uri =
        Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _executeWeather(Map<String, dynamic> params) async {
    final location = params['location'] as String? ?? 'current location';
    final uri = Uri.parse(
        'https://www.google.com/search?q=weather+${Uri.encodeComponent(location)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _executeAlarm(Map<String, dynamic> params) async {
    final time = params['time'] as String? ?? '';
    if (time.isEmpty) return false;
    final uri = Uri.parse(
        'https://www.google.com/search?q=set+alarm+for+${Uri.encodeComponent(time)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _executeNote(Map<String, dynamic> params) async {
    final content = params['content'] as String? ?? '';
    if (content.isEmpty) return false;
    final uri = Uri.parse(
        'https://keep.google.com/#/note/new?title=${Uri.encodeComponent('Voice Note')}&text=${Uri.encodeComponent(content)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _executeEmail(Map<String, dynamic> params) async {
    final recipient = params['recipient'] as String? ?? '';
    final subject = params['subject'] as String? ?? '';
    final uri = Uri.parse(
        'mailto:${Uri.encodeComponent(recipient)}?subject=${Uri.encodeComponent(subject)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
