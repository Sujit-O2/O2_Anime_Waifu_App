import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Voice recognition service: STT, voice commands, continuous listening
class VoiceRecognitionService {
  static final VoiceRecognitionService _instance =
      VoiceRecognitionService._internal();
  factory VoiceRecognitionService() => _instance;
  VoiceRecognitionService._internal();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  final _firestore = FirebaseFirestore.instance;

  // ── Initialize ───────────────────────────────────────────────────────────

  /// Initialize speech recognition
  Future<bool> initializeSpeechRecognition() async {
    try {
      final available = await _speechToText.initialize(
        onError: (error) {
          if (kDebugMode) debugPrint('Error: $error');
        },
        onStatus: (status) {
          if (kDebugMode) debugPrint('Status: $status');
        },
      );
      return available;
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing speech: $e');
      return false;
    }
  }

  // ── Start Listening ──────────────────────────────────────────────────────

  /// Start continuous speech recognition
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    try {
      if (!_isListening) {
        final available = await initializeSpeechRecognition();
        if (!available) {
          onError('Speech recognition not available');
          return;
        }

        _isListening = true;
        _speechToText.listen(
          onResult: (result) {
            _lastWords = result.recognizedWords;
            onResult(_lastWords);

            // Check if it's a command
            _parseVoiceCommand(_lastWords);
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
        );
      }
    } catch (e) {
      onError('Error starting listening: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error stopping listening: $e');
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get last recognized words
  String get lastWords => _lastWords;

  // ── Voice Command Parser ─────────────────────────────────────────────────

  /// Parse and execute voice commands
  Future<Map<String, dynamic>> _parseVoiceCommand(String command) async {
    try {
      final lowerCommand = command.toLowerCase().trim();

      // Define command patterns
      final commands = {
        'send message': _handleSendMessage,
        'add to vault': _handleAddToVault,
        'set reminder': _handleSetReminder,
        'check affection': _handleCheckAffection,
        'open settings': _handleOpenSettings,
        'start quest': _handleStartQuest,
        'record mood': _handleRecordMood,
        'play music': _handlePlayMusic,
        'take screenshot': _handleTakeScreenshot,
        'help': _handleHelp,
      };

      for (var entry in commands.entries) {
        final trigger = entry.key;
        final handler = entry.value;
        if (lowerCommand.contains(trigger)) {
          return await handler(command);
        }
      }

      // Log unrecognized command
      await _logVoiceCommand(command, 'unrecognized');
      return {'success': false, 'message': 'Command not recognized'};
    } catch (e) {
      if (kDebugMode) debugPrint('Error parsing command: $e');
      return {'success': false, 'message': 'Error parsing command'};
    }
  }

  // ── Command Handlers ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _handleSendMessage(String command) async {
    await _logVoiceCommand(command, 'send_message');
    return {'success': true, 'action': 'send_message'};
  }

  Future<Map<String, dynamic>> _handleAddToVault(String command) async {
    await _logVoiceCommand(command, 'add_vault');
    return {'success': true, 'action': 'add_vault'};
  }

  Future<Map<String, dynamic>> _handleSetReminder(String command) async {
    await _logVoiceCommand(command, 'set_reminder');
    return {'success': true, 'action': 'set_reminder'};
  }

  Future<Map<String, dynamic>> _handleCheckAffection(String command) async {
    await _logVoiceCommand(command, 'check_affection');
    return {'success': true, 'action': 'check_affection'};
  }

  Future<Map<String, dynamic>> _handleOpenSettings(String command) async {
    await _logVoiceCommand(command, 'open_settings');
    return {'success': true, 'action': 'open_settings'};
  }

  Future<Map<String, dynamic>> _handleStartQuest(String command) async {
    await _logVoiceCommand(command, 'start_quest');
    return {'success': true, 'action': 'start_quest'};
  }

  Future<Map<String, dynamic>> _handleRecordMood(String command) async {
    await _logVoiceCommand(command, 'record_mood');
    return {'success': true, 'action': 'record_mood'};
  }

  Future<Map<String, dynamic>> _handlePlayMusic(String command) async {
    await _logVoiceCommand(command, 'play_music');
    return {'success': true, 'action': 'play_music'};
  }

  Future<Map<String, dynamic>> _handleTakeScreenshot(String command) async {
    await _logVoiceCommand(command, 'take_screenshot');
    return {'success': true, 'action': 'take_screenshot'};
  }

  Future<Map<String, dynamic>> _handleHelp(String command) async {
    await _logVoiceCommand(command, 'help');
    return {
      'success': true,
      'action': 'help',
      'commands': [
        'Send message',
        'Add to vault',
        'Set reminder',
        'Check affection',
        'Open settings',
        'Start quest',
        'Record mood',
        'Play music',
      ]
    };
  }

  // ── Logging ──────────────────────────────────────────────────────────────

  /// Log voice command for analytics
  Future<void> _logVoiceCommand(String command, String action) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('voice_commands').add({
        'uid': uid,
        'command': command,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging voice command: $e');
    }
  }

  // ── Voice Analytics ──────────────────────────────────────────────────────

  /// Get voice command history
  static Future<List<Map<String, dynamic>>> getVoiceCommandHistory(
    String uid, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('voice_commands')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching voice history: $e');
      return [];
    }
  }

  /// Get most used voice commands
  static Future<Map<String, int>> getMostUsedCommands(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('voice_commands')
          .where('uid', isEqualTo: uid)
          .get();

      final commandCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final action = doc.get('action') as String? ?? 'unknown';
        commandCounts[action] = (commandCounts[action] ?? 0) + 1;
      }

      return commandCounts;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting most used commands: $e');
      return {};
    }
  }

  // ── Voice Settings ───────────────────────────────────────────────────────

  /// Enable/disable voice recognition globally
  static Future<void> setVoiceRecognitionEnabled(
    String uid,
    bool enabled,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('voice_settings')
          .doc(uid)
          .set({
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating voice settings: $e');
    }
  }

  /// Get voice recognition settings
  static Future<bool> isVoiceRecognitionEnabled(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('voice_settings')
          .doc(uid)
          .get();
      return doc.get('enabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  void dispose() {
    _speechToText.stop();
  }
}


