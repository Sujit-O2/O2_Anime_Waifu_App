import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/models/relationship_stage.dart';

/// Tracks affection points, streak days, and relationship level.
/// +2 points per successful chat response. Decay after 48h inactivity.
class AffectionService {
  int _points = 0;
  int _streakDays = 0;
  RelationshipStage _stage = RelationshipStage.stranger;
  DateTime _lastInteraction = DateTime.now();
  static const int _pointsPerMessage = 2;
  static const int _decayHours = 48;

  int get points => _points;
  int get streakDays => _streakDays;
  RelationshipStage get stage => _stage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _points = prefs.getInt('affection_points') ?? 0;
    _streakDays = prefs.getInt('streak_days') ?? 0;
    final lastStr = prefs.getString('last_interaction');
    if (lastStr != null) _lastInteraction = DateTime.parse(lastStr);
    _stage = RelationshipStageExtension.fromPoints(_points);
    _checkDecay();
  }

  void addPoints({int extra = 0}) {
    _points += _pointsPerMessage + extra;
    _lastInteraction = DateTime.now();
    _updateStreak();
    _stage = RelationshipStageExtension.fromPoints(_points);
    _persist();
  }

  void _checkDecay() {
    final hoursSince = DateTime.now().difference(_lastInteraction).inHours;
    if (hoursSince >= _decayHours) {
      final decayAmount = ((hoursSince - _decayHours) ~/ 12) * 5;
      _points = (_points - decayAmount).clamp(0, 999999);
      _stage = RelationshipStageExtension.fromPoints(_points);
      _persist();
    }
  }

  void _updateStreak() {
    final now = DateTime.now();
    final daysSince = now.difference(_lastInteraction).inDays;
    if (daysSince <= 1) {
      if (now.day != _lastInteraction.day) _streakDays++;
    } else {
      _streakDays = 1;
    }
  }

  double get progressToNextStage {
    final currentThreshold = _stage.pointThreshold;
    final stageIndex = RelationshipStage.values.indexOf(_stage);
    if (stageIndex >= RelationshipStage.values.length - 1) return 1.0;
    final nextThreshold =
        RelationshipStage.values[stageIndex + 1].pointThreshold;
    return ((_points - currentThreshold) / (nextThreshold - currentThreshold))
        .clamp(0.0, 1.0);
  }

  String toContextString() =>
      '[Affection] ${_stage.displayName} | Points: $_points | Streak: $_streakDays days';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('affection_points', _points);
    await prefs.setInt('streak_days', _streakDays);
    await prefs.setString(
        'last_interaction', _lastInteraction.toIso8601String());
  }
}
