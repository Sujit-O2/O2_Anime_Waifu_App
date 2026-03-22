import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/models/memory_event.dart';

/// Phase 3: 8 event types with emotional weight scores.
/// Auto-records first message, confessions, long gaps, mood shifts,
/// world unlocks. Top events injected into every LLM prompt.
class MemoryTimelineService {
  final List<MemoryEvent> _events = [];
  static const int _maxEvents = 100;
  static const int _topEventsForPrompt = 5;

  List<MemoryEvent> get events => List.unmodifiable(_events);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('memory_timeline');
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      _events.clear();
      _events.addAll(
        decoded.map((e) => MemoryEvent.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  void recordEvent({
    required MemoryEventType type,
    required String description,
    double emotionalWeight = 1.0,
    Map<String, dynamic>? metadata,
  }) {
    _events.add(MemoryEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      description: description,
      timestamp: DateTime.now(),
      emotionalWeight: emotionalWeight,
      metadata: metadata,
    ));

    if (_events.length > _maxEvents) {
      // Remove lowest weight events first
      _events.sort((a, b) => a.emotionalWeight.compareTo(b.emotionalWeight));
      _events.removeAt(0);
    }

    _persist();
  }

  List<MemoryEvent> getTopEvents() {
    final sorted = List<MemoryEvent>.from(_events)
      ..sort((a, b) => b.emotionalWeight.compareTo(a.emotionalWeight));
    return sorted.take(_topEventsForPrompt).toList();
  }

  String toContextString() {
    final top = getTopEvents();
    if (top.isEmpty) return '';
    return '[Memory Timeline]\n${top.map((e) => e.toContextString()).join('\n')}';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'memory_timeline',
      jsonEncode(_events.map((e) => e.toJson()).toList()),
    );
  }
}
