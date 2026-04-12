import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:anime_waifu/utils/api_call.dart';

/// Voice Emotion Detector — Detects stress, happiness, tiredness from voice.
/// Transcribes voice natively, then uses Cloud API for sentiment (0MB!).
class VoiceEmotionDetectorPage extends StatefulWidget {
  const VoiceEmotionDetectorPage({super.key});
  @override
  State<VoiceEmotionDetectorPage> createState() => _VoiceEmotionDetectorPageState();
}

class _VoiceEmotionDetectorPageState extends State<VoiceEmotionDetectorPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _modelsLoaded = false;
  String _status = 'Tap to start listening';
  String _transcription = '';
  String _emotion = '';
  double _confidence = 0;
  final List<Map<String, dynamic>> _history = [];

  final _emotionMap = {
    'POSITIVE': {'emoji': '😄', 'label': 'Happy', 'color': Colors.greenAccent, 'response': 'You sound happy! That makes me happy too~ 💕'},
    'NEGATIVE': {'emoji': '😢', 'label': 'Sad/Stressed', 'color': Colors.redAccent, 'response': 'Hey... you okay? I\'m here for you 🥺'},
    'NEUTRAL': {'emoji': '😐', 'label': 'Neutral', 'color': Colors.cyanAccent, 'response': 'Hmm, hard to read you right now~'},
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _initModels();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initModels() async {
    setState(() => _status = 'Initializing cloud sentiment engine...');
    bool available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'notListening' && _isListening) {
           setState(() => _isListening = false);
        }
      },
      onError: (e) {
        setState(() {
          _isListening = false;
          _status = 'Mic error: ${e.errorMsg}';
        });
      }
    );
    setState(() {
      _modelsLoaded = available;
      _status = available ? 'Engine ready! Tap mic to analyze' : 'Microphone permission denied / not available';
    });
  }

  Future<void> _listen() async {
    if (!_modelsLoaded) return;
    
    if (_isListening) {
       _speech.stop();
       setState(() {
         _isListening = false;
         _status = 'Stopped listening';
       });
       return;
    }
    
    setState(() {
      _isListening = true;
      _status = '🎤 Listening... Speak now';
      _emotion = '';
      _transcription = '';
    });
    
    _speech.listen(onResult: (val) async {
      if (val.finalResult) {
        final text = val.recognizedWords;
        setState(() {
           _status = '🧠 Analyzing emotion via API...';
           _isListening = false;
           _transcription = text;
        });
        
        // Use efficient cloud API for sentiment instead of 300MB ONNX
        final api = ApiService();
        final aiResult = await api.sendConversation([
          {'role': 'system', 'content': 'You are a precise emotion detector. Analyze this text and output ONLY valid JSON without markdown: {"sentiment": "POSITIVE|NEGATIVE|NEUTRAL", "confidence": 0.0-1.0}'},
          {'role': 'user', 'content': text}
        ]);
        
        String sent = 'NEUTRAL';
        double conf = 0.5;
        try {
           final clean = aiResult.replaceAll('```json', '').replaceAll('```', '').trim();
           final decoded = jsonDecode(clean);
           sent = decoded['sentiment']?.toString().toUpperCase() ?? 'NEUTRAL';
           if (sent != 'POSITIVE' && sent != 'NEGATIVE') sent = 'NEUTRAL';
           conf = (decoded['confidence'] ?? 0.5).toDouble();
        } catch(e) { 
           debugPrint('Sentiment parse error: $e');
        }
        
        setState(() {
            _emotion = sent;
            _confidence = conf;
            _status = 'Analysis complete';
            _history.insert(0, {
               'text': _transcription,
               'emotion': _emotion,
               'confidence': _confidence,
               'time': DateTime.now().toIso8601String(),
            });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final emotionData = _emotionMap[_emotion] ?? _emotionMap['NEUTRAL']!;
    final c = (emotionData['color'] as Color?) ?? Colors.cyanAccent;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('EMOTION DETECTOR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Column(children: [
        const SizedBox(height: 16),

        // Big emotion display
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final scale = _isListening ? 1.0 + _pulseCtrl.value * 0.1 : 1.0;
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: _listen,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      c.withValues(alpha: _isListening ? 0.3 : 0.15),
                      c.withValues(alpha: 0.02),
                    ]),
                    border: Border.all(color: c.withValues(alpha: _isListening ? 0.6 : 0.3), width: 2),
                  ),
                  child: Center(
                    child: _isListening
                        ? const Icon(Icons.mic_rounded, color: Colors.white, size: 48)
                        : Text(_emotion.isEmpty ? '🎤' : emotionData['emoji']?.toString() ?? '', style: const TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Status text
        Text(_status, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),

        // Emotion result
        if (_emotion.isNotEmpty) ...[
          Text(emotionData['label']?.toString() ?? '', style: GoogleFonts.outfit(color: c, fontSize: 22, fontWeight: FontWeight.w900)),
          Text('${(_confidence * 100).toStringAsFixed(0)}% confidence', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),

          // Waifu response
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Text('💕', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(child: Text(emotionData['response']?.toString() ?? '', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic))),
            ]),
          ),

          // Transcription
          if (_transcription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TRANSCRIPTION', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text('"$_transcription"', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
              ]),
            ),
          ],
        ],

        const SizedBox(height: 16),
        // History
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Icon(Icons.history_rounded, color: Colors.white24, size: 14),
            const SizedBox(width: 4),
            Text('HISTORY', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ]),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _history.isEmpty
              ? Center(child: Text('Tap the mic to start', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final h = _history[i];
                    final eData = _emotionMap[h['emotion']] ?? _emotionMap['NEUTRAL']!;
                    final ec = (eData['color'] as Color?) ?? Colors.cyanAccent;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: ec.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Text(eData['emoji']?.toString() ?? '', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(h['text'], style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis)),
                        Text('${(h['confidence'] * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: ec, fontSize: 10, fontWeight: FontWeight.w700)),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}



