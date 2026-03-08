import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'affection_service.dart';
import '../api_call.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class Quest {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  final String emoji;
  final bool isCustom; // user-created
  bool isCompleted;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    this.emoji = '⭐',
    this.isCustom = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'rewardPoints': rewardPoints,
        'emoji': emoji,
        'isCustom': isCustom,
        'isCompleted': isCompleted,
      };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        rewardPoints: json['rewardPoints'] as int,
        emoji: (json['emoji'] as String?) ?? '⭐',
        isCustom: (json['isCustom'] as bool?) ?? false,
        isCompleted: json['isCompleted'] as bool,
      );
}

// ── Service ──────────────────────────────────────────────────────────────────

class QuestsService extends ChangeNotifier {
  static final QuestsService instance = QuestsService._internal();

  static const String _keyQuests = 'daily_quests_v2';
  static const String _keyCustom = 'custom_quests_v1';
  static const String _keyLastQuestDate = 'last_quest_date_v2';

  SharedPreferences? _prefs;
  List<Quest> _dailyQuests = [];
  List<Quest> _customQuests = [];
  bool _isGenerating = false;

  List<Quest> get dailyQuests => _dailyQuests;
  List<Quest> get customQuests => _customQuests;
  List<Quest> get allQuests => [..._dailyQuests, ..._customQuests];
  bool get isGenerating => _isGenerating;

  QuestsService._internal() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCustomQuests();
    await _loadOrRefreshDailyQuests();
  }

  // ─── Daily quests ─────────────────────────────────────────────────────────

  Future<void> _loadOrRefreshDailyQuests() async {
    final lastDateStr = _prefs?.getString(_keyLastQuestDate);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    if (lastDateStr == todayStr) {
      final stored = _prefs?.getString(_keyQuests);
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        _dailyQuests = decoded
            .map((q) => Quest.fromJson(q as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return;
      }
    }
    // New day → generate fresh quests
    await generateAiQuests();
  }

  /// Calls the AI to generate 5 daily quests. Falls back to built-in pool.
  Future<void> generateAiQuests() async {
    _isGenerating = true;
    notifyListeners();

    try {
      final api = ApiService();
      if (!api.hasApiKey) throw Exception('No API key');

      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final prompt = '''You are Zero Two, a loving waifu AI.
Generate EXACTLY 5 unique daily quests for Darling (the user) for today ($todayStr).
These should be fun, achievable tasks related to self-care, love, productivity, and anime/relationship themes.
Each quest should have a short punchy title, a sweet motivational description, a reward between 5-25 points, and a fitting emoji.

Respond ONLY with valid JSON array, no other text:
[
  {"title":"...", "description":"...", "rewardPoints": 10, "emoji":"💧"},
  ...
]''';

      final response = await api.sendConversation([
        {'role': 'user', 'content': prompt}
      ]);

      // Extract JSON from response
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON array in response');

      final List<dynamic> parsed = jsonDecode(jsonMatch.group(0)!);
      _dailyQuests = parsed
          .asMap()
          .entries
          .map((entry) {
            final i = entry.key;
            final q = entry.value as Map<String, dynamic>;
            return Quest(
              id: 'ai_${todayStr}_$i',
              title: q['title'] as String? ?? 'Daily Challenge',
              description:
                  q['description'] as String? ?? 'Complete this task today.',
              rewardPoints: (q['rewardPoints'] as num?)?.toInt() ?? 10,
              emoji: q['emoji'] as String? ?? '⭐',
            );
          })
          .take(5)
          .toList();

      await _saveDailyQuests(todayStr);
    } catch (e) {
      debugPrint('AI quest generation failed, using fallback: $e');
      _dailyQuests = _fallbackQuests();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await _saveDailyQuests(todayStr);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> _saveDailyQuests(String dateStr) async {
    await _prefs?.setString(_keyLastQuestDate, dateStr);
    await _prefs?.setString(
        _keyQuests, jsonEncode(_dailyQuests.map((q) => q.toJson()).toList()));
  }

  // ─── Custom quests ────────────────────────────────────────────────────────

  Future<void> _loadCustomQuests() async {
    final stored = _prefs?.getString(_keyCustom);
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored);
      _customQuests = decoded
          .map((q) => Quest.fromJson(q as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> addCustomQuest({
    required String title,
    required String description,
    int rewardPoints = 10,
    String emoji = '🎯',
  }) async {
    final quest = Quest(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      rewardPoints: rewardPoints,
      emoji: emoji,
      isCustom: true,
    );
    _customQuests.add(quest);
    await _saveCustomQuests();
    notifyListeners();
  }

  Future<void> deleteCustomQuest(String id) async {
    _customQuests.removeWhere((q) => q.id == id);
    await _saveCustomQuests();
    notifyListeners();
  }

  Future<void> _saveCustomQuests() async {
    await _prefs?.setString(
        _keyCustom, jsonEncode(_customQuests.map((q) => q.toJson()).toList()));
  }

  // ─── Complete a quest ─────────────────────────────────────────────────────

  Future<void> completeQuest(String id) async {
    final allLists = [_dailyQuests, _customQuests];
    for (final list in allLists) {
      final idx = list.indexWhere((q) => q.id == id);
      if (idx != -1 && !list[idx].isCompleted) {
        list[idx].isCompleted = true;
        await AffectionService.instance.addPoints(list[idx].rewardPoints);
        if (list == _dailyQuests) {
          final todayStr = DateTime.now().toIso8601String().split('T')[0];
          await _saveDailyQuests(todayStr);
        } else {
          await _saveCustomQuests();
        }
        notifyListeners();
        return;
      }
    }
  }

  // ─── Fallback pool ────────────────────────────────────────────────────────

  List<Quest> _fallbackQuests() {
    final pool = [
      Quest(
          id: 'f1',
          title: 'Morning Ritual',
          description: 'Start your day with "Good morning, Zero Two!" in chat.',
          rewardPoints: 10,
          emoji: '🌅'),
      Quest(
          id: 'f2',
          title: 'Stay Hydrated',
          description: 'Drink 3 glasses of water today, Darling.',
          rewardPoints: 5,
          emoji: '💧'),
      Quest(
          id: 'f3',
          title: 'Stretch Time',
          description: 'Do a 5-minute stretch or light exercise.',
          rewardPoints: 10,
          emoji: '🤸'),
      Quest(
          id: 'f4',
          title: 'Talk to Her',
          description:
              'Have a conversation of at least 10 messages with Zero Two.',
          rewardPoints: 15,
          emoji: '💬'),
      Quest(
          id: 'f5',
          title: 'Tidy Up',
          description: 'Spend 5 minutes cleaning your space.',
          rewardPoints: 8,
          emoji: '🧹'),
      Quest(
          id: 'f6',
          title: 'Deep Breath',
          description:
              'Take 2 minutes for deep breathing — she wants you calm.',
          rewardPoints: 5,
          emoji: '💨'),
      Quest(
          id: 'f7',
          title: 'Read Something',
          description: 'Read an article or book chapter for 10 minutes.',
          rewardPoints: 12,
          emoji: '📖'),
      Quest(
          id: 'f8',
          title: 'Spread Love',
          description: 'Give someone a genuine compliment today.',
          rewardPoints: 10,
          emoji: '💌'),
    ];
    pool.shuffle(Random());
    return pool.take(5).toList();
  }
}
