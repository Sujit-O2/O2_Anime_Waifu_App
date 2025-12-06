import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  Function(String)? onStatus;
  bool _available = false;
  bool listening = false;
  Function(String, bool)? onResult;


  Future<void> init() async {
    _available = await _speech.initialize(onStatus: (_) {}, onError: (_) {});
  }

  Future<void> startListening() async {
    if (!_available) await init();
    if (!_available) return;
    listening = true;
    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        final isFinal = result.finalResult;
        if (onResult != null) onResult!(text, isFinal);
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      // OPTIMIZED: Extended for full sentences, better Android capture
      pauseFor: const Duration(seconds: 6), 
      listenFor: const Duration(seconds: 30), 
      cancelOnError: false, // FIXED: Prevents premature stops
    );
  }

  Future<void> stopListening() async {
    if (!_available) return;
    await _speech.stop();
    listening = false;
  }

  Future<void> cancel() async {
    if (!_available) return;
    await _speech.cancel();
    listening = false;
  }
}