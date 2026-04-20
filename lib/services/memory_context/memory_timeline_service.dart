import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// MemoryTimelineService
///
/// A structured, persistent timeline of emotionally significant events.
/// Not just raw chat logs — curated moments that matter.
///
/// Event types:
///   first_message    — very first interaction
///   confession       — she or user said something emotionally real
///   milestone        — relationship stage transition
///   long_gap         — user was absent for 3+ days (emotional significance)
///   mood_change      — a dramatic personality mood shift
///   special_event    — birthday, anniversary, deep talk
///   topic_peak       — a topic that dominated many conversations
///   world_unlock     — new world level or object
///
/// This powers:
/// • "Remember when you said…" callbacks
/// • Context block showing relationship history
/// • Signature moments that reference actual past events
/// ─────────────────────────────────────────────────────────────────────────────
class MemoryTimelineService {
  static final MemoryTimelineService instance = MemoryTimelineService._();
  MemoryTimelineService._();

  static const _timelineKey = 'mtl_events_v1';
  static const _maxEvents = 100;

  final List<TimelineEvent> _events = [];
  bool _loaded = false;

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_timelineKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _events.addAll(list.map(
          (e) => TimelineEvent.fromJson(e as Map<String, dynamic>),
        ));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _events.map((e) => e.toJson()).toList();
    await prefs.setString(_timelineKey, jsonEncode(list));
  }

  // ── Adding events ────────────────────────────────────────────────────────
  Future<bool> addEvent({
    required TimelineEventType type,
    required String title,
    String? detail,
    double emotionalWeight = 0.5,
  }) async {
    await load();

    // Prevent same-type duplicate within 1 hour
    final now = DateTime.now();
    final recent = _events.where((e) =>
        e.type == type && now.difference(e.at).inHours < 1).toList();
    if (recent.isNotEmpty) return false;

    _events.add(TimelineEvent(
      type: type,
      title: title,
      detail: detail,
      at: now,
      emotionalWeight: emotionalWeight,
    ));

    // Sort by time, trim to max
    _events.sort((a, b) => b.at.compareTo(a.at));
    if (_events.length > _maxEvents) {
      _events.removeRange(_maxEvents, _events.length);
    }

    await _save();
    return true;
  }

  // ── Auto-record events ────────────────────────────────────────────────────
  Future<void> recordFirstMessageIfNeeded() async {
    await load();
    final hasFirst = _events.any((e) => e.type == TimelineEventType.firstMessage);
    if (!hasFirst) {
      await addEvent(
        type: TimelineEventType.firstMessage,
        title: 'The very first conversation',
        detail: 'When it all began.',
        emotionalWeight: 1.0,
      );
    }
  }

  Future<void> recordLongGap(int hoursGone) async {
    await addEvent(
      type: TimelineEventType.longGap,
      title: 'You were away for ${hoursGone}h',
      detail: 'A notable absence in the relationship.',
      emotionalWeight: 0.7,
    );
  }

  Future<void> recordMoodShift(String fromMood, String toMood) async {
    await addEvent(
      type: TimelineEventType.moodChange,
      title: 'Mood shifted: $fromMood → $toMood',
      emotionalWeight: 0.4,
    );
  }

  Future<void> recordWorldUnlock(int level, String theme) async {
    await addEvent(
      type: TimelineEventType.worldUnlock,
      title: 'Shared world reached level $level: $theme',
      emotionalWeight: 0.6,
    );
  }

  // ── Context block ─────────────────────────────────────────────────────────
  String getTimelineContextBlock({int maxEvents = 4}) {
    if (_events.isEmpty) return '';
    final buf = StringBuffer();
    buf.writeln('\n// [MEMORY TIMELINE — reference naturally when relevant]:');

    final high = _events
        .where((e) => e.emotionalWeight >= 0.7)
        .take(maxEvents)
        .toList();

    for (final e in high) {
      final age = _ageString(e.at);
      buf.writeln('• ${e.title} ($age)');
      if (e.detail != null) buf.writeln('  Detail: ${e.detail}');
    }
    buf.writeln();
    return buf.toString();
  }

  String _ageString(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30)   return '${(diff.inDays / 30).round()}mo ago';
    if (diff.inDays > 1)    return '${diff.inDays}d ago';
    if (diff.inHours > 1)   return '${diff.inHours}h ago';
    return 'just now';
  }

  // ── Getters ──────────────────────────────────────────────────────────────
  List<TimelineEvent> get events => List.unmodifiable(_events);

  TimelineEvent? get firstEvent =>
      _events.isEmpty ? null : _events.reduce((a, b) => a.at.isBefore(b.at) ? a : b);

  Duration? get totalAge {
    final first = firstEvent;
    if (first == null) return null;
    return DateTime.now().difference(first.at);
  }

  List<TimelineEvent> getEventsByType(TimelineEventType type) =>
      _events.where((e) => e.type == type).toList();
}

// ── Data classes ─────────────────────────────────────────────────────────────
enum TimelineEventType {
  firstMessage,
  confession,
  milestone,
  longGap,
  moodChange,
  specialEvent,
  topicPeak,
  worldUnlock,
}

class TimelineEvent {
  final TimelineEventType type;
  final String title;
  final String? detail;
  final DateTime at;
  final double emotionalWeight; // 0.0 – 1.0

  const TimelineEvent({
    required this.type,
    required this.title,
    this.detail,
    required this.at,
    required this.emotionalWeight,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> j) => TimelineEvent(
    type: TimelineEventType.values.firstWhere(
      (t) => t.name == j['type'],
      orElse: () => TimelineEventType.milestone,
    ),
    title:           j['title'] as String,
    detail:          j['detail'] as String?,
    at:              DateTime.parse(j['at'] as String),
    emotionalWeight: (j['weight'] as num?)?.toDouble() ?? 0.5,
  );

  Map<String, dynamic> toJson() => {
    'type':   type.name,
    'title':  title,
    'detail': detail,
    'at':     at.toIso8601String(),
    'weight': emotionalWeight,
  };
}


