import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voice Mail Service - Send voice messages as email attachments
class VoiceMailService {
  static final VoiceMailService _instance = VoiceMailService._internal();
  factory VoiceMailService() => _instance;
  VoiceMailService._internal();

  static const String _voicemailsKey = 'voice_mails';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Record and save voice message
  Future<String?> saveVoiceMessage(
    Uint8List audioData, {
    required String description,
    String? recipientEmail,
  }) async {
    try {
      final id = _generateId();
      final base64Audio = base64Encode(audioData);

      final voicemail = VoiceMail(
        id: id,
        audioBase64: base64Audio,
        description: description,
        recipientEmail: recipientEmail,
        recordedAt: DateTime.now(),
        durationSeconds: (audioData.length / 16000).toInt(), // Estimate
      );

      final voicemails = _prefs.getString(_voicemailsKey) ?? '{}';
      final voicemailsMap = jsonDecode(voicemails) as Map<String, dynamic>;
      voicemailsMap[id] = voicemail.toJson();

      await _prefs.setString(_voicemailsKey, jsonEncode(voicemailsMap));
      debugPrint('✅ Voice message saved: $id (${voicemail.durationSeconds}s)');
      return id;
    } catch (e) {
      debugPrint('❌ Error saving voice message: $e');
      return null;
    }
  }

  /// Get voice message by ID
  Future<VoiceMail?> getVoiceMessage(String id) async {
    try {
      final voicemails = _prefs.getString(_voicemailsKey) ?? '{}';
      final voicemailsMap = jsonDecode(voicemails) as Map<String, dynamic>;
      if (voicemailsMap.containsKey(id)) {
        return VoiceMail.fromJson(voicemailsMap[id]);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting voice message: $e');
      return null;
    }
  }

  /// Get all voice messages
  Future<List<VoiceMail>> getAllVoiceMessages() async {
    try {
      final voicemails = _prefs.getString(_voicemailsKey) ?? '{}';
      final voicemailsMap = jsonDecode(voicemails) as Map<String, dynamic>;
      return voicemailsMap.values
          .cast<Map<String, dynamic>>()
          .map((json) => VoiceMail.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading voice messages: $e');
      return [];
    }
  }

  /// Delete voice message
  Future<bool> deleteVoiceMessage(String id) async {
    try {
      final voicemails = _prefs.getString(_voicemailsKey) ?? '{}';
      final voicemailsMap = jsonDecode(voicemails) as Map<String, dynamic>;
      voicemailsMap.remove(id);
      await _prefs.setString(_voicemailsKey, jsonEncode(voicemailsMap));
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting voice message: $e');
      return false;
    }
  }

  /// Prepare voice message for email attachment
  /// Returns base64 encoded audio file
  Future<String?> prepareForEmailAttachment(String voiceMailId) async {
    try {
      final vm = await getVoiceMessage(voiceMailId);
      if (vm == null) return null;
      return vm.audioBase64;
    } catch (e) {
      debugPrint('❌ Error preparing voice attachment: $e');
      return null;
    }
  }

  /// Build voice mail email content
  String buildVoiceMailEmailContent(VoiceMail voicemail) {
    final duration = _formatDuration(voicemail.durationSeconds);
    return '''
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 20px auto; background: white; padding: 30px; border-radius: 10px; }
        .header { color: #333; font-size: 24px; font-weight: bold; margin-bottom: 20px; }
        .voice-info { background-color: #e3f2fd; padding: 15px; border-radius: 8px; margin: 15px 0; }
        .info-item { margin: 10px 0; color: #555; }
        .label { font-weight: bold; color: #1976d2; }
        .description { font-size: 16px; line-height: 1.6; color: #333; margin: 15px 0; }
        .footer { font-size: 12px; color: #999; margin-top: 20px; border-top: 1px solid #eee; padding-top: 15px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">🎙️ Voice Mail Received</div>
        
        <div class="voice-info">
          <div class="info-item">
            <span class="label">Duration:</span> $duration
          </div>
          <div class="info-item">
            <span class="label">Recorded:</span> ${voicemail.recordedAt.toString().split('.')[0]}
          </div>
        </div>
        
        <div class="description">
          <strong>Message:</strong><br>
          ${voicemail.description}
        </div>
        
        <div class="footer">
          <p>This email contains an audio attachment. Open the attached file to listen to the voice message.</p>
          <p>File size: ${(voicemail.audioBase64.length / 1024).toStringAsFixed(2)} KB</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Get voice message statistics
  Future<VoiceMailStats> getVoiceMailStats() async {
    try {
      final all = await getAllVoiceMessages();
      int totalDuration = 0;
      for (final vm in all) {
        totalDuration += vm.durationSeconds;
      }

      return VoiceMailStats(
        totalVoiceMessages: all.length,
        totalDurationSeconds: totalDuration,
        averageDurationSeconds:
            all.isEmpty ? 0 : totalDuration ~/ all.length,
      );
    } catch (e) {
      debugPrint('❌ Error getting voice mail stats: $e');
      return VoiceMailStats(
        totalVoiceMessages: 0,
        totalDurationSeconds: 0,
        averageDurationSeconds: 0,
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _generateId() {
    return 'vm_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Voice Mail Model
class VoiceMail {
  final String id;
  final String audioBase64; // Base64 encoded audio data
  final String description;
  final String? recipientEmail;
  final DateTime recordedAt;
  final int durationSeconds;
  final bool isSent;

  VoiceMail({
    required this.id,
    required this.audioBase64,
    required this.description,
    this.recipientEmail,
    required this.recordedAt,
    required this.durationSeconds,
    this.isSent = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'audioBase64': audioBase64,
        'description': description,
        'recipientEmail': recipientEmail,
        'recordedAt': recordedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'isSent': isSent,
      };

  factory VoiceMail.fromJson(Map<String, dynamic> json) => VoiceMail(
        id: json['id'],
        audioBase64: json['audioBase64'],
        description: json['description'],
        recipientEmail: json['recipientEmail'],
        recordedAt: DateTime.parse(json['recordedAt']),
        durationSeconds: json['durationSeconds'],
        isSent: json['isSent'] ?? false,
      );

  Uint8List? getAudioData() {
    try {
      return base64Decode(audioBase64);
    } catch (e) {
      debugPrint('❌ Error decoding audio data: $e');
      return null;
    }
  }
}

/// Voice Mail Statistics
class VoiceMailStats {
  final int totalVoiceMessages;
  final int totalDurationSeconds;
  final int averageDurationSeconds;

  VoiceMailStats({
    required this.totalVoiceMessages,
    required this.totalDurationSeconds,
    required this.averageDurationSeconds,
  });

  @override
  String toString() =>
      'VoiceMailStats(total: $totalVoiceMessages, duration: ${totalDurationSeconds}s, avg: ${averageDurationSeconds}s)';
}

/// Global instance
final voiceMailService = VoiceMailService();


