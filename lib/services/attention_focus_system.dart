import 'package:o2_waifu/models/master_snapshot.dart';

/// Phase 2: Scores last 8 replies (speed + length) -> HIGH/MED/LOW attention.
/// Calibrates AI response length and tone.
class ReplyMetrics {
  final int responseTimeMs;
  final int messageLength;
  final DateTime timestamp;

  ReplyMetrics({
    required this.responseTimeMs,
    required this.messageLength,
    required this.timestamp,
  });
}

class AttentionFocusSystem {
  final List<ReplyMetrics> _recentReplies = [];
  static const int _windowSize = 8;
  AttentionLevel _currentLevel = AttentionLevel.medium;

  AttentionLevel get currentLevel => _currentLevel;

  void recordReply(int responseTimeMs, int messageLength) {
    _recentReplies.add(ReplyMetrics(
      responseTimeMs: responseTimeMs,
      messageLength: messageLength,
      timestamp: DateTime.now(),
    ));

    if (_recentReplies.length > _windowSize) {
      _recentReplies.removeAt(0);
    }

    _recalculate();
  }

  void _recalculate() {
    if (_recentReplies.isEmpty) {
      _currentLevel = AttentionLevel.medium;
      return;
    }

    // Calculate attention score based on:
    // - Fast responses = higher attention
    // - Longer messages = higher attention
    double score = 0;

    for (final reply in _recentReplies) {
      // Speed score: < 5s = 1.0, > 30s = 0.0
      final speedScore =
          (1.0 - (reply.responseTimeMs / 30000.0)).clamp(0.0, 1.0);

      // Length score: > 50 chars = 1.0, < 5 chars = 0.0
      final lengthScore =
          ((reply.messageLength - 5) / 45.0).clamp(0.0, 1.0);

      score += (speedScore * 0.6) + (lengthScore * 0.4);
    }

    score /= _recentReplies.length;

    if (score > 0.65) {
      _currentLevel = AttentionLevel.high;
    } else if (score > 0.35) {
      _currentLevel = AttentionLevel.medium;
    } else {
      _currentLevel = AttentionLevel.low;
    }
  }

  int get suggestedResponseLength {
    switch (_currentLevel) {
      case AttentionLevel.high:
        return 200; // Match their energy
      case AttentionLevel.medium:
        return 120;
      case AttentionLevel.low:
        return 60; // Keep it short
    }
  }

  String toContextString() =>
      '[Attention] ${_currentLevel.name.toUpperCase()} | Suggested response: ~$suggestedResponseLength chars';
}
