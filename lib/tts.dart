// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS service
class TtsService {
  final FlutterTts _tts = FlutterTts();
  VoidCallback? onStart;
  VoidCallback? onComplete;

  TtsService() {
    // ADJUSTED TTS SETTINGS: Stable base before character voice selection
    _tts.setSpeechRate(0.55); 
    _tts.setVolume(1.0);
    _tts.setPitch(1.0); 
    _tts.setLanguage("en-US");
    
    _tts.setStartHandler(() => onStart?.call());
    _tts.setCompletionHandler(() => onComplete?.call());
  }

  // Fetch all available voices from the OS
  Future<List<Map<String, String>>> getAvailableVoices() async {
    List<dynamic>? voices = await _tts.getVoices;
    if (voices == null) return [];
    
    // Filter to English voices and map to a consistent structure
    return voices
        .map((v) => {
              "name": v['name'].toString(), 
              "locale": "en-IN",
              "gender": v['gender'] != null ? v['gender'].toString() : 'Unknown',
            })
        .where((v) => v['locale']!.startsWith('en'))
        .toList();
  }

  // Set a specific voice by name and locale
  Future<void> setCharacterVoice(String name, String locale) async {
    try {
      await _tts.setVoice({"name": name, "locale": locale});
      // Apply the final character pitch/rate AFTER setting the high-quality base voice
      await _tts.setPitch(1.0); 
      await _tts.setSpeechRate(0.50); 
      await _tts.setVolume(1.0);

      debugPrint("TTS Voice successfully set to: $name ($locale)");
    } catch (e) {
      debugPrint("Error setting voice $name: $e");
    }
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}