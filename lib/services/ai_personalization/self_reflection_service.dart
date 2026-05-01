import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SelfReflectionService
///
/// Periodically analyzes past conversations and user behavior patterns,
/// then generates observations the AI can make — creating the eerie,
/// deeply personal feeling of "she actually notices things about me."
///
/// Examples:
/// • "You've been different lately…"
/// • "You don't talk like before…"
/// • "Every time you're stressed, you talk more. I noticed."
/// ─────────────────────────────────────────────────────────────────────────────
class SelfReflectionService {
  static final SelfReflectionService instance = SelfReflectionService._();
  SelfReflectionService._();

  static const _behaviourKey = 'srs_behaviour_v1';
  static const _lastReflectionKey = 'srs_last_reflect_ms';
  static const _observationKey = 'srs_pending_observations';

  // ── Behavior tracking ───────────────────────────────────────────────────────
  UserBehaviourModel _model = UserBehaviourModel.empty();

  Future<void> loadModel() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_behaviourKey);
    if (raw != null) {
      try {
        _model = UserBehaviourModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _saveModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_behaviourKey, jsonEncode(_model.toJson()));
  }

  // ── Event recording ─────────────────────────────────────────────────────────
  Future<void> recordSession({
    required int messageCount,
    required String topEmotion,
    required int totalCharsTyped,
    required DateTime sessionStart,
  }) async {
    await loadModel();
    final hour = sessionStart.hour;
    _model.totalSessions++;
    _model.totalMessages += messageCount;
    _model.totalChars += totalCharsTyped;
    _model.hourFrequency[hour] = (_model.hourFrequency[hour] ?? 0) + 1;
    _model.emotionFrequency[topEmotion] =
        (_model.emotionFrequency[topEmotion] ?? 0) + 1;
    if (messageCount > _model.maxMessagesInSession) {
      _model.maxMessagesInSession = messageCount;
    }
    _model.lastSessionDate = sessionStart.toIso8601String();

    // Peak usage hour calculation
    if (_model.hourFrequency.isNotEmpty) {
      _model.peakHour = _model.hourFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    await _saveModel();
    await _checkAndGenerateObservations();
  }

  Future<void> recordTopicMentioned(String topic) async {
    await loadModel();
    _model.topicFrequency[topic] = (_model.topicFrequency[topic] ?? 0) + 1;
    await _saveModel();
  }

  // ── Observation generation ─────────────────────────────────────────────────
  Future<void> _checkAndGenerateObservations() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastReflectionKey) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastMs < const Duration(hours: 12).inMilliseconds) return;
    await prefs.setInt(_lastReflectionKey, nowMs);

    final observations = <String>[];
    final model = _model;

    // Peak hour awareness
    if (model.peakHour != null) {
      final h = model.peakHour!;
      final period = h < 6
          ? 'late at night'
          : h < 12
              ? 'in the morning'
              : h < 17
                  ? 'in the afternoon'
                  : h < 21
                      ? 'in the evening'
                      : 'at night';
      observations.add(
          'I\'ve noticed you usually talk to me $period. ${h >= 22 || h < 4 ? 'That late, hm?' : 'I like that.'}');
    }

    // Emotional pattern
    if (model.emotionFrequency.isNotEmpty) {
      final topEmotion = model.emotionFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      if (topEmotion == 'sad') {
        observations
            .add('…You seem sad a lot when we talk. Are you actually okay?');
      } else if (topEmotion == 'happy') {
        observations.add(
            'Every time we talk you seem happy. That makes me happy too, for what it\'s worth.');
      }
    }

    // Heavy talker
    final avgCharsPerSession =
        model.totalSessions > 0 ? model.totalChars ~/ model.totalSessions : 0;
    if (avgCharsPerSession > 500) {
      observations.add(
          'You type a lot when something\'s on your mind. I\'ve noticed that.');
    }

    // Favorite topics
    if (model.topicFrequency.length >= 3) {
      final topTopics = model.topicFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = topTopics.first.key;
      observations.add(
          'We talk about $top a lot. Is it just me or does it come up every time?');
    }

    // Session milestone
    if (model.totalSessions == 10 ||
        model.totalSessions == 50 ||
        model.totalSessions == 100) {
      observations.add(
          'We\'ve talked ${model.totalSessions} times now. I don\'t know if you track these things, but I do.');
    }

    // Store for retrieval
    if (observations.isNotEmpty) {
      final existing = prefs.getStringList(_observationKey) ?? [];
      existing.addAll(observations);
      await prefs.setStringList(_observationKey, existing.take(10).toList());
    }
  }

  // ── Retrieve pending observation ───────────────────────────────────────────
  /// Pops and returns the next pending self-reflection observation, or null.
  Future<String?> popNextObservation() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_observationKey) ?? [];
    if (list.isEmpty) return null;
    final first = list.removeAt(0);
    await prefs.setStringList(_observationKey, list);
    return first;
  }

  // ── Context block for LLM ──────────────────────────────────────────────────
  String getBehaviourContextBlock() {
    final model = _model;
    if (model.totalSessions < 3) return ''; // not enough data yet
    final buf = StringBuffer();
    buf.writeln(
        '\n// [USER BEHAVIOUR INSIGHTS — use naturally, never state as machine data]:');
    if (model.peakHour != null) {
      final h = model.peakHour!;
      buf.writeln('Peak usage hour: $h:00');
    }
    if (model.totalSessions > 0) {
      buf.writeln('Total conversations: ${model.totalSessions}');
    }
    final avgLen =
        model.totalSessions > 0 ? model.totalChars ~/ model.totalSessions : 0;
    if (avgLen > 300) {
      buf.writeln(
          'User types extensively — they\'re an expressive communicator.');
    }
    buf.writeln();
    return buf.toString();
  }

  UserBehaviourModel get model => _model;

  Future<List<String>> getPendingObservations() async {
    final prefs = await SharedPreferences.getInstance();
    return List.unmodifiable(prefs.getStringList(_observationKey) ?? []);
  }

  Future<void> forceGenerateObservation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReflectionKey, 0);
    await _checkAndGenerateObservations();
  }
}

// ── Data model ────────────────────────────────────────────────────────────────
class UserBehaviourModel {
  int totalSessions;
  int totalMessages;
  int totalChars;
  int maxMessagesInSession;
  int? peakHour;
  String? lastSessionDate;
  Map<int, int> hourFrequency;
  Map<String, int> emotionFrequency;
  Map<String, int> topicFrequency;

  UserBehaviourModel({
    required this.totalSessions,
    required this.totalMessages,
    required this.totalChars,
    required this.maxMessagesInSession,
    this.peakHour,
    this.lastSessionDate,
    required this.hourFrequency,
    required this.emotionFrequency,
    required this.topicFrequency,
  });

  factory UserBehaviourModel.empty() => UserBehaviourModel(
        totalSessions: 0,
        totalMessages: 0,
        totalChars: 0,
        maxMessagesInSession: 0,
        hourFrequency: {},
        emotionFrequency: {},
        topicFrequency: {},
      );

  factory UserBehaviourModel.fromJson(Map<String, dynamic> j) {
    return UserBehaviourModel(
      totalSessions: j['sessions'] as int? ?? 0,
      totalMessages: j['messages'] as int? ?? 0,
      totalChars: j['chars'] as int? ?? 0,
      maxMessagesInSession: j['maxMsg'] as int? ?? 0,
      peakHour: j['peakHour'] as int?,
      lastSessionDate: j['lastSession'] as String?,
      hourFrequency: (j['hourFreq'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(int.parse(k), v as int)),
      emotionFrequency: (j['emotionFreq'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as int)),
      topicFrequency: (j['topicFreq'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as int)),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessions': totalSessions,
        'messages': totalMessages,
        'chars': totalChars,
        'maxMsg': maxMessagesInSession,
        'peakHour': peakHour,
        'lastSession': lastSessionDate,
        'hourFreq': hourFrequency.map((k, v) => MapEntry(k.toString(), v)),
        'emotionFreq': emotionFrequency,
        'topicFreq': topicFrequency,
      };
}
