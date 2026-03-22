import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'affection_service.dart';
import 'firestore_service.dart';
import '../api_call.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class Quest {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  final String emoji;
  final bool isCustom;
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
        isCompleted: (json['isCompleted'] as bool?) ?? false,
      );
}

// ── Service ────────────────────────────────────────────────────────────────────

class QuestsService extends ChangeNotifier {
  static final QuestsService instance = QuestsService._internal();

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
    await _loadCustomQuests();
    await _loadOrRefreshDailyQuests();
  }

  // ─── Daily quests ─────────────────────────────────────────────────────────

  Future<void> _loadOrRefreshDailyQuests() async {
    final data = await FirestoreService().loadQuests();
    final lastDateStr = data['lastQuestDate'] as String?;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    if (lastDateStr == todayStr) {
      final stored = data['dailyQuests'] as String?;
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        _dailyQuests = decoded
            .map((q) => Quest.fromJson(q as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return;
      }
    }
    await generateAiQuests();
  }

  Future<void> generateAiQuests() async {
    _isGenerating = true;
    notifyListeners();
    try {
      final api = ApiService();
      if (!api.hasApiKey) throw Exception('No API key');
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final prompt =
          '''You are Zero Two, a loving waifu AI.\nGenerate EXACTLY 5 unique daily quests for Darling (the user) for today ($todayStr).\nThese should be fun, achievable tasks related to self-care, love, productivity, and anime/relationship themes.\nEach quest should have a short punchy title, a sweet motivational description, a reward between 5-25 points, and a fitting emoji.\n\nRespond ONLY with valid JSON array, no other text:\n[\n  {"title":"...", "description":"...", "rewardPoints": 10, "emoji":"💧"},\n  ...\n]''';
      final response = await api.sendConversation([
        {'role': 'user', 'content': prompt}
      ]);
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON in response');
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
      debugPrint('AI quest generation failed: $e');
      _dailyQuests = _fallbackQuests();
      await _saveDailyQuests(DateTime.now().toIso8601String().split('T')[0]);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> _saveDailyQuests(String dateStr) async {
    await FirestoreService()
        .saveDailyQuests(_dailyQuests.map((q) => q.toJson()).toList(), dateStr);
  }

  // ─── Custom quests ────────────────────────────────────────────────────────

  Future<void> _loadCustomQuests() async {
    final data = await FirestoreService().loadQuests();
    final stored = data['customQuests'] as String?;
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
    // Achievement: created first custom quest
    await FirestoreService().unlockAchievement('first_custom_quest');
    notifyListeners();
  }

  Future<void> deleteCustomQuest(String id) async {
    _customQuests.removeWhere((q) => q.id == id);
    await _saveCustomQuests();
    notifyListeners();
  }

  Future<void> _saveCustomQuests() async {
    await FirestoreService()
        .saveCustomQuests(_customQuests.map((q) => q.toJson()).toList());
  }

  // ─── Complete quest ───────────────────────────────────────────────────────

  Future<void> completeQuest(String id) async {
    for (final list in [_dailyQuests, _customQuests]) {
      final idx = list.indexWhere((q) => q.id == id);
      if (idx != -1 && !list[idx].isCompleted) {
        list[idx].isCompleted = true;
        await AffectionService.instance.addPoints(list[idx].rewardPoints);
        if (list == _dailyQuests) {
          await _saveDailyQuests(
              DateTime.now().toIso8601String().split('T')[0]);
          // Achievement for completing all daily quests
          if (_dailyQuests.every((q) => q.isCompleted)) {
            await FirestoreService().unlockAchievement('all_daily_quests');
          }
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
          description: 'Say "Good morning, Zero Two!" in chat.',
          rewardPoints: 10,
          emoji: '🌅'),
      Quest(
          id: 'f2',
          title: 'Stay Hydrated',
          description: 'Drink 3 glasses of water today.',
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
          description: 'Have at least 10 messages with Zero Two.',
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
          description: 'Take 2 minutes for deep breathing.',
          rewardPoints: 5,
          emoji: '💨'),
      Quest(
          id: 'f7',
          title: 'Read Something',
          description: 'Read an article or book for 10 minutes.',
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
