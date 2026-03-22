import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/models/relationship_stage.dart';

/// Phase 3: 10 named stages Stranger->Soulmate (0-2500pt thresholds).
/// Trust score 0-100. Milestone tracker.
class RelationshipMilestone {
  final String name;
  final DateTime achievedAt;
  final RelationshipStage stage;

  RelationshipMilestone({
    required this.name,
    required this.achievedAt,
    required this.stage,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'achievedAt': achievedAt.toIso8601String(),
        'stage': stage.name,
      };

  factory RelationshipMilestone.fromJson(Map<String, dynamic> json) =>
      RelationshipMilestone(
        name: json['name'] as String,
        achievedAt: DateTime.parse(json['achievedAt'] as String),
        stage: RelationshipStage.values.firstWhere(
          (e) => e.name == json['stage'],
          orElse: () => RelationshipStage.stranger,
        ),
      );
}

class RelationshipProgressionService {
  int _points = 0;
  double _trustScore = 50.0;
  RelationshipStage _stage = RelationshipStage.stranger;
  final List<RelationshipMilestone> _milestones = [];

  int get points => _points;
  double get trustScore => _trustScore;
  RelationshipStage get stage => _stage;
  List<RelationshipMilestone> get milestones =>
      List.unmodifiable(_milestones);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _points = prefs.getInt('relationship_points') ?? 0;
    _trustScore = prefs.getDouble('trust_score') ?? 50.0;
    _stage = RelationshipStageExtension.fromPoints(_points);

    final milestoneStr = prefs.getString('milestones');
    if (milestoneStr != null) {
      final List<dynamic> decoded =
          jsonDecode(milestoneStr) as List<dynamic>;
      _milestones.clear();
      _milestones.addAll(decoded.map(
          (e) => RelationshipMilestone.fromJson(e as Map<String, dynamic>)));
    }
  }

  void addPoints(int amount) {
    final oldStage = _stage;
    _points += amount;
    _stage = RelationshipStageExtension.fromPoints(_points);

    if (_stage != oldStage) {
      _milestones.add(RelationshipMilestone(
        name: 'Reached ${_stage.displayName}',
        achievedAt: DateTime.now(),
        stage: _stage,
      ));
    }
    _persist();
  }

  void adjustTrust(double amount) {
    _trustScore = (_trustScore + amount).clamp(0.0, 100.0);
    _persist();
  }

  String toContextString() {
    return '[Relationship] ${_stage.displayName} (${_points}pts) | Trust: ${_trustScore.toStringAsFixed(1)}/100\n'
        '[Stage Hint] ${_stage.behaviorHint}';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('relationship_points', _points);
    await prefs.setDouble('trust_score', _trustScore);
    await prefs.setString(
      'milestones',
      jsonEncode(_milestones.map((m) => m.toJson()).toList()),
    );
  }
}
