import 'package:anime_waifu/android_stt.dart';
import 'package:anime_waifu/stt.dart';

enum SttEngineMode {
  current,
  android,
}

class SelectableSpeechService {
  final SpeechService _currentService = SpeechService();
  final AndroidSpeechService _androidService = AndroidSpeechService();

  SttEngineMode _mode = SttEngineMode.current;

  Function(String)? onStatus;
  Function(String)? onError;
  Function(String, bool)? onResult;

  SelectableSpeechService() {
    _bindCallbacks();
  }

  SttEngineMode get mode => _mode;

  bool get listening {
    return _mode == SttEngineMode.current
        ? _currentService.listening
        : _androidService.listening;
  }

  void configure({
    String? apiKeyOverride,
    String? transcriptionModelOverride,
    String? transcriptionUrlOverride,
    String? transcriptionLanguageOverride,
  }) {
    _currentService.configure(
      apiKeyOverride: apiKeyOverride,
      transcriptionModelOverride: transcriptionModelOverride,
      transcriptionUrlOverride: transcriptionUrlOverride,
      transcriptionLanguageOverride: transcriptionLanguageOverride,
    );
    _androidService.configure(
      apiKeyOverride: apiKeyOverride,
      transcriptionModelOverride: transcriptionModelOverride,
      transcriptionUrlOverride: transcriptionUrlOverride,
      transcriptionLanguageOverride: transcriptionLanguageOverride,
    );
  }

  Future<void> init() async {
    if (_mode == SttEngineMode.current) {
      await _currentService.init();
    } else {
      await _androidService.init();
    }
  }

  Future<void> setMode(SttEngineMode mode) async {
    if (_mode == mode) return;
    if (listening) {
      await cancel();
    }
    _mode = mode;
    await init();
  }

  Future<bool> startListening() async {
    if (_mode == SttEngineMode.current) {
      return _currentService.startListening();
    }
    return _androidService.startListening();
  }

  Future<void> stopListening() async {
    if (_mode == SttEngineMode.current) {
      await _currentService.stopListening();
      return;
    }
    await _androidService.stopListening();
  }

  Future<void> cancel() async {
    if (_mode == SttEngineMode.current) {
      await _currentService.cancel();
      return;
    }
    await _androidService.cancel();
  }

  Future<bool> recover() async {
    if (_mode == SttEngineMode.current) {
      return _currentService.recover();
    }
    return _androidService.recover();
  }

  void _bindCallbacks() {
    _currentService.onStatus = (status) {
      if (_mode == SttEngineMode.current && onStatus != null) {
        onStatus!(status);
      }
    };
    _currentService.onError = (error) {
      if (_mode == SttEngineMode.current && onError != null) {
        onError!(error);
      }
    };
    _currentService.onResult = (text, isFinal) {
      if (_mode == SttEngineMode.current && onResult != null) {
        onResult!(text, isFinal);
      }
    };

    _androidService.onStatus = (status) {
      if (_mode == SttEngineMode.android && onStatus != null) {
        onStatus!(status);
      }
    };
    _androidService.onError = (error) {
      if (_mode == SttEngineMode.android && onError != null) {
        onError!(error);
      }
    };
    _androidService.onResult = (text, isFinal) {
      if (_mode == SttEngineMode.android && onResult != null) {
        onResult!(text, isFinal);
      }
    };
  }
}
