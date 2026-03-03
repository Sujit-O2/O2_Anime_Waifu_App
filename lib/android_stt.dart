import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AndroidSpeechService {
  final SpeechToText _speech = SpeechToText();

  Function(String)? onStatus;
  Function(String)? onError;
  Function(String, bool)? onResult;

  bool listening = false;
  bool _available = false;
  bool _starting = false;
  bool _stopping = false;
  bool _finalDispatched = false;
  String _latestText = "";
  Timer? _sessionGuardTimer;

  static const Duration _listenFor = Duration(seconds: 12);
  static const Duration _pauseFor = Duration(seconds: 3);

  void configure({
    String? apiKeyOverride,
    String? transcriptionModelOverride,
    String? transcriptionUrlOverride,
    String? transcriptionLanguageOverride,
  }) {
    // Android on-device STT does not use API/transcription config.
  }

  Future<void> init() async {
    if (!Platform.isAndroid) {
      _available = false;
      return;
    }
    try {
      _available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: false,
      );
    } catch (e) {
      _available = false;
      debugPrint("Android STT init error: $e");
    }
  }

  Future<bool> startListening() async {
    if (!Platform.isAndroid) {
      if (onError != null) onError!("android_stt_not_supported");
      return false;
    }
    if (listening || _starting || _stopping) return false;

    _starting = true;
    if (!_available) {
      await init();
    }
    if (!_available) {
      _starting = false;
      if (onError != null) onError!("android_stt_unavailable");
      return false;
    }

    _latestText = "";
    _finalDispatched = false;

    try {
      final started = await _speech.listen(
        onResult: (result) {
          _latestText = result.recognizedWords.trim();
          if (_latestText.isNotEmpty && onResult != null) {
            onResult!(_latestText, false);
          }
          if (result.finalResult) {
            _emitFinalResult();
          }
        },
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: _listenFor,
        pauseFor: _pauseFor,
      );

      listening = started;
      _starting = false;

      if (!started) {
        if (onError != null) onError!("android_stt_start_failed");
        return false;
      }

      if (onStatus != null) onStatus!("listening");

      _sessionGuardTimer?.cancel();
      _sessionGuardTimer =
          Timer(_listenFor + const Duration(milliseconds: 500), () async {
        if (listening && !_stopping) {
          await stopListening();
        }
      });
      return true;
    } catch (e) {
      listening = false;
      _starting = false;
      if (onError != null) onError!("android_stt_start_exception: $e");
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!listening || _stopping) return;
    _stopping = true;
    _sessionGuardTimer?.cancel();
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint("Android STT stop error: $e");
    }
    listening = false;
    _stopping = false;
    _starting = false;
    if (onStatus != null) onStatus!("done");
    _emitFinalResult();
  }

  Future<void> cancel() async {
    _sessionGuardTimer?.cancel();
    try {
      await _speech.cancel();
    } catch (_) {}
    listening = false;
    _starting = false;
    _stopping = false;
    _latestText = "";
    _finalDispatched = false;
    if (onStatus != null) onStatus!("notListening");
  }

  Future<bool> recover() async {
    await cancel();
    _available = false;
    await init();
    return _available;
  }

  void _emitFinalResult() {
    if (_finalDispatched) return;
    _finalDispatched = true;
    if (onResult != null) onResult!(_latestText.trim(), true);
  }

  void _handleStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'listening') {
      listening = true;
      if (onStatus != null) onStatus!("listening");
      return;
    }
    if (normalized == 'done' || normalized == 'notlistening') {
      final wasListening = listening;
      listening = false;
      _starting = false;
      _stopping = false;
      _sessionGuardTimer?.cancel();
      if (wasListening) {
        if (onStatus != null) onStatus!("done");
        _emitFinalResult();
      } else {
        if (onStatus != null) onStatus!("notListening");
      }
    }
  }

  void _handleError(SpeechRecognitionError error) {
    listening = false;
    _starting = false;
    _stopping = false;
    _sessionGuardTimer?.cancel();
    if (onError != null) onError!("android_stt_error: ${error.errorMsg}");
    if (onStatus != null) onStatus!("notListening");
    _emitFinalResult();
  }
}
