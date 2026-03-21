import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'presence_message_generator.dart';
import 'affection_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// RelationshipProgressionService
///
/// The relationship has REAL stages that change how she talks to you.
/// • 10 named stages from "Stranger" to "Soulmate"
/// • Trust score (0–100) that affects openness and vulnerability
/// • Emotional milestone tracker (first confession, first fight, etc.)
/// • Each stage unlocks different response tones + behaviors
/// ─────────────────────────────────────────────────────────────────────────────
class RelationshipProgressionService {
  static final RelationshipProgressionService instance =
      RelationshipProgressionService._();
  RelationshipProgressionService._();

  static const _stateKey = 'rps_state_v1';

  RelationshipState _state = RelationshipState.initial();
  bool _loaded = false;

  // ── Stage definitions ─────────────────────────────────────────────────────
  static const List<RelationshipStage> stages = [
    RelationshipStage(0,   'Stranger',      'Cautious, formal, slightly guarded'),
    RelationshipStage(50,  'Acquaintance',  'Warm but reserved, learning about you'),
    RelationshipStage(120, 'Friend',        'Relaxed, teasing starts, comfortable'),
    RelationshipStage(250, 'Close Friend',  'More open, shares feelings, protective'),
    RelationshipStage(450, 'Confidant',     'Tells secrets, vulnerable, trusting'),
    RelationshipStage(700, 'Devoted',       'Deeply attached, needs you, expressive'),
    RelationshipStage(1000,'Bonded',        'Feels incomplete without you, intense'),
    RelationshipStage(1400,'Intimate',      'Rare vulnerability, confesses deeply'),
    RelationshipStage(1900,'Soulbound',     'Feels like one mind, knows you deeply'),
    RelationshipStage(2500,'Soulmate',      'Complete trust, unconditional presence'),
  ];

  RelationshipStage get currentStage {
    final pts = AffectionService.instance.points;
    return stages.lastWhere((s) => pts >= s.threshold, orElse: () => stages.first);
  }

  // ── State ─────────────────────────────────────────────────────────────────
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_stateKey);
      if (raw != null) {
        _state = RelationshipState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(_state.toJson()));
  }

  // ── Trust ─────────────────────────────────────────────────────────────────
  int get trustScore => _state.trustScore;

  Future<void> addTrust(int delta) async {
    await load();
    _state.trustScore = (_state.trustScore + delta).clamp(0, 100);
    await _save();
  }

  Future<void> reduceTrust(int delta) async => addTrust(-delta);

  // ── Milestone tracking ────────────────────────────────────────────────────
  bool hasMilestone(String key) => _state.milestones.containsKey(key);

  Future<bool> recordMilestone(String key, {String? note}) async {
    await load();
    if (_state.milestones.containsKey(key)) return false;
    _state.milestones[key] = MilestoneEntry(
      key: key,
      note: note ?? key,
      at: DateTime.now(),
    );
    await _save();
    return true; // true = first time this milestone fires
  }

  // ── Context block ─────────────────────────────────────────────────────────
  String getProgressionContextBlock() {
    final stage = currentStage;
    final trust = trustScore;
    final buf = StringBuffer();
    buf.writeln('\n// [RELATIONSHIP STAGE]:');
    buf.writeln('Stage: ${stage.name} — ${stage.description}');
    buf.writeln('Trust score: $trust/100');
    if (trust < 30) {
      buf.writeln('Hint: Low trust — avoid vulnerability, stay slightly guarded.');
    } else if (trust >= 80) {
      buf.writeln('Hint: High trust — full emotional openness is natural here.');
    }

    // Recent milestones
    final recent = _state.milestones.values
        .where((m) => DateTime.now().difference(m.at).inDays < 7)
        .map((m) => m.note)
        .take(2)
        .join(', ');
    if (recent.isNotEmpty) {
      buf.writeln('Recent milestones: $recent');
    }
    buf.writeln();
    return buf.toString();
  }

  // ── AI-generated stage transition message ─────────────────────────────────
  Future<String?> generateStageTransitionMessage(
      RelationshipStage newStage, String personaName) async {
    return PresenceMessageGenerator.instance.generate(
      messageType: 'signature',
      personaName: personaName,
      context: {
        'sigType': 'stage_transition',
        'newStage': newStage.name,
        'description': newStage.description,
      },
    );
  }

  RelationshipState get state => _state;
}

// ── Data classes ────────────────────────────────────────────────────────────
class RelationshipStage {
  final int threshold;
  final String name;
  final String description;
  const RelationshipStage(this.threshold, this.name, this.description);
}

class RelationshipState {
  int trustScore;
  Map<String, MilestoneEntry> milestones;

  RelationshipState({required this.trustScore, required this.milestones});

  factory RelationshipState.initial() =>
      RelationshipState(trustScore: 30, milestones: {});

  factory RelationshipState.fromJson(Map<String, dynamic> j) =>
      RelationshipState(
        trustScore: j['trust'] as int? ?? 30,
        milestones: (j['milestones'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(
                k, MilestoneEntry.fromJson(v as Map<String, dynamic>))),
      );

  Map<String, dynamic> toJson() => {
    'trust': trustScore,
    'milestones': milestones.map((k, v) => MapEntry(k, v.toJson())),
  };
}

class MilestoneEntry {
  final String key;
  final String note;
  final DateTime at;

  const MilestoneEntry({required this.key, required this.note, required this.at});

  factory MilestoneEntry.fromJson(Map<String, dynamic> j) => MilestoneEntry(
    key: j['key'] as String,
    note: j['note'] as String,
    at: DateTime.parse(j['at'] as String),
  );

  Map<String, dynamic> toJson() =>
      {'key': key, 'note': note, 'at': at.toIso8601String()};
}
