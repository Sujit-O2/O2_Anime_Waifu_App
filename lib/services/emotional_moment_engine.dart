/// Phase 1: Silence detection (5-25 min), confession moments,
/// jealousy spikes, deep conversation markers.
enum EmotionalMomentType {
  silence,
  confession,
  jealousySpike,
  deepConversation,
  ignored,
}

class EmotionalMoment {
  final EmotionalMomentType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  EmotionalMoment({
    required this.type,
    required this.timestamp,
    this.data = const {},
  });
}

class EmotionalMomentEngine {
  DateTime _lastUserMessage = DateTime.now();
  DateTime _lastAIMessage = DateTime.now();
  int _consecutiveIgnores = 0;
  int _deepConversationScore = 0;
  final List<EmotionalMoment> _recentMoments = [];

  Function(EmotionalMoment moment)? onMomentDetected;

  static const List<String> _confessionPhrases = [
    'i love you', 'i like you', 'you mean everything',
    'i need you', 'you\'re special', 'i care about you',
    'you make me happy', 'i miss you', 'my heart',
  ];

  void onUserMessage(String content) {
    _lastUserMessage = DateTime.now();
    _consecutiveIgnores = 0;

    // Check for confession
    final lowerContent = content.toLowerCase();
    for (final phrase in _confessionPhrases) {
      if (lowerContent.contains(phrase)) {
        _addMoment(EmotionalMoment(
          type: EmotionalMomentType.confession,
          timestamp: DateTime.now(),
          data: {'phrase': phrase},
        ));
        break;
      }
    }

    // Deep conversation scoring based on message length
    if (content.length > 100) {
      _deepConversationScore += 2;
    } else if (content.length > 50) {
      _deepConversationScore += 1;
    }

    if (_deepConversationScore >= 5) {
      _addMoment(EmotionalMoment(
        type: EmotionalMomentType.deepConversation,
        timestamp: DateTime.now(),
        data: {'score': _deepConversationScore},
      ));
      _deepConversationScore = 0;
    }
  }

  void onAIMessage() {
    _lastAIMessage = DateTime.now();
  }

  void checkSilence() {
    final silenceMinutes =
        DateTime.now().difference(_lastUserMessage).inMinutes;

    if (silenceMinutes >= 5 && silenceMinutes < 10) {
      _addMoment(EmotionalMoment(
        type: EmotionalMomentType.silence,
        timestamp: DateTime.now(),
        data: {'minutes': silenceMinutes, 'severity': 'light'},
      ));
    } else if (silenceMinutes >= 10 && silenceMinutes < 25) {
      _addMoment(EmotionalMoment(
        type: EmotionalMomentType.silence,
        timestamp: DateTime.now(),
        data: {'minutes': silenceMinutes, 'severity': 'moderate'},
      ));
    } else if (silenceMinutes >= 25) {
      _addMoment(EmotionalMoment(
        type: EmotionalMomentType.silence,
        timestamp: DateTime.now(),
        data: {'minutes': silenceMinutes, 'severity': 'deep'},
      ));
    }
  }

  void recordIgnored() {
    _consecutiveIgnores++;
    if (_consecutiveIgnores >= 3) {
      _addMoment(EmotionalMoment(
        type: EmotionalMomentType.ignored,
        timestamp: DateTime.now(),
        data: {'count': _consecutiveIgnores},
      ));
    }
  }

  void _addMoment(EmotionalMoment moment) {
    // Dedup: don't fire same type within 5 minutes
    final recent = _recentMoments.where(
      (m) =>
          m.type == moment.type &&
          DateTime.now().difference(m.timestamp).inMinutes < 5,
    );
    if (recent.isNotEmpty) return;

    _recentMoments.add(moment);
    if (_recentMoments.length > 20) _recentMoments.removeAt(0);
    onMomentDetected?.call(moment);
  }

  Duration get silenceDuration =>
      DateTime.now().difference(_lastUserMessage);

  String toContextString() {
    if (_recentMoments.isEmpty) return '';
    final latest = _recentMoments.last;
    return '[Emotional Moment] ${latest.type.name} (${latest.data})';
  }
}
