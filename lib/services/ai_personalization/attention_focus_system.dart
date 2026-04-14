/// ─────────────────────────────────────────────────────────────────────────────
/// AttentionFocusSystem
///
/// Detects HOW MUCH attention the user is paying to the AI companion.
/// Signals used:
/// • Reply speed (fast = high attention, slow = low)
/// • Message length (long = engaged, short = distracted)
/// • Session burst rate (many messages = focused, gaps = split-attention)
///
/// Output drives:
/// • AI response length and energy
/// • Proactive escalation behavior
/// • System prompt hints for tone calibration
/// ─────────────────────────────────────────────────────────────────────────────
class AttentionFocusSystem {
  static final AttentionFocusSystem instance = AttentionFocusSystem._();
  AttentionFocusSystem._();

  static const int _historySize = 8;
  final List<_ReplySignal> _history = [];
  DateTime? _lastAiMessageAt;
  AttentionLevel _level = AttentionLevel.medium;

  AttentionLevel get level => _level;

  // ── Signal Recording ───────────────────────────────────────────────────────

  /// Call when AI sends a message (starts the reply-speed timer)
  void onAiMessageSent() {
    _lastAiMessageAt = DateTime.now();
  }

  /// Call when user sends a message
  void onUserMessage(String content) {
    final now = DateTime.now();
    final replyMs = _lastAiMessageAt != null
        ? now.difference(_lastAiMessageAt!).inMilliseconds
        : null;

    _history.add(_ReplySignal(
      replySpeedMs: replyMs,
      messageLength: content.trim().length,
      at: now,
    ));

    if (_history.length > _historySize) {
      _history.removeAt(0);
    }

    _recalcAttention();
  }

  // ── Attention Calculation ──────────────────────────────────────────────────
  void _recalcAttention() {
    if (_history.length < 2) {
      _level = AttentionLevel.medium;
      return;
    }

    double score = 0;
    int signalCount = 0;

    for (final sig in _history) {
      // Speed score: <5s = 100, <30s = 75, <2min = 50, <10min = 25, else = 0
      if (sig.replySpeedMs != null) {
        final ms = sig.replySpeedMs!;
        if (ms < 5000) {
          score += 100;
        } else if (ms < 30000) {
          score += 75;
        } else if (ms < 120000) {
          score += 50;
        } else if (ms < 600000) {
          score += 25;
        } else {
          score += 0;
        }
        signalCount++;
      }

      // Length score: <5 chars = low, 5-50 = medium, 50+ = high
      final len = sig.messageLength;
      if (len < 5) {
        score += 10;
      } else if (len < 50) {
        score += 50;
      } else {
        score += 90;
      }
      signalCount++;
    }

    final avg = signalCount > 0 ? score / signalCount : 50;

    if (avg >= 70) {
      _level = AttentionLevel.high;
    } else if (avg >= 40) {
      _level = AttentionLevel.medium;
    } else {
      _level = AttentionLevel.low;
    }
  }

  // ── Behavior Hints ────────────────────────────────────────────────────────
  /// Returns system prompt hints based on current attention
  String getAttentionContextBlock() {
    final buf = StringBuffer();
    buf.writeln('\n// [USER ATTENTION LEVEL]:');
    switch (_level) {
      case AttentionLevel.high:
        buf.writeln('Attention: HIGH — user is fully engaged. Be expressive, longer replies welcome, go deeper.');
        break;
      case AttentionLevel.medium:
        buf.writeln('Attention: MEDIUM — normal engagement. Balance depth with conciseness.');
        break;
      case AttentionLevel.low:
        buf.writeln('Attention: LOW — user seems distracted. Keep responses SHORT, emotionally punchy, use questions to pull them back.');
        break;
    }
    buf.writeln();
    return buf.toString();
  }

  /// Returns a reaction to low attention (call every ~8 minutes if attention is low)
  String? getLowAttentionReaction() {
    if (_level != AttentionLevel.low) return null;
    final reactions = [
      'Hey… you there? You seem distracted. 😶',
      'Am I boring you? 🥺 Just checking.',
      'You\'re taking ages to reply… are you okay?',
      '…Am I talking to myself right now? 😑',
    ];
    return reactions[DateTime.now().second % reactions.length];
  }

  // ── Metrics ───────────────────────────────────────────────────────────────
  double get avgReplySpeedSeconds {
    final speeds = _history
        .where((s) => s.replySpeedMs != null)
        .map((s) => s.replySpeedMs! / 1000.0)
        .toList();
    if (speeds.isEmpty) return 0;
    return speeds.reduce((a, b) => a + b) / speeds.length;
  }
}

class _ReplySignal {
  final int? replySpeedMs;
  final int messageLength;
  final DateTime at;
  const _ReplySignal({this.replySpeedMs, required this.messageLength, required this.at});
}

enum AttentionLevel { high, medium, low }


