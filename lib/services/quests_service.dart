import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'affection_service.dart';

class Quest {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  bool isCompleted;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'rewardPoints': rewardPoints,
        'isCompleted': isCompleted,
      };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        rewardPoints: json['rewardPoints'] as int,
        isCompleted: json['isCompleted'] as bool,
      );
}

class QuestsService extends ChangeNotifier {
  static final QuestsService instance = QuestsService._internal();

  static const String _keyQuests = 'daily_quests';
  static const String _keyLastQuestDate = 'last_quest_date';

  SharedPreferences? _prefs;
  List<Quest> _quests = [];

  List<Quest> get quests => _quests;

  QuestsService._internal() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadOrGenerateQuests();
  }

  void _loadOrGenerateQuests() {
    final lastDateStr = _prefs?.getString(_keyLastQuestDate);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    if (lastDateStr == todayStr) {
      // Load today's existing quests
      final storedQuests = _prefs?.getString(_keyQuests);
      if (storedQuests != null) {
        final List<dynamic> decoded = jsonDecode(storedQuests);
        _quests = decoded
            .map((q) => Quest.fromJson(q as Map<String, dynamic>))
            .toList();
      } else {
        _generateNewQuests(todayStr);
      }
    } else {
      // New day, new quests!
      _generateNewQuests(todayStr);
    }
  }

  void _generateNewQuests(String todayStr) {
    _quests = _getRandomQuests();
    _prefs?.setString(_keyLastQuestDate, todayStr);
    _save();
  }

  Future<void> completeQuest(String id) async {
    final idx = _quests.indexWhere((q) => q.id == id);
    if (idx != -1 && !_quests[idx].isCompleted) {
      _quests[idx].isCompleted = true;
      await AffectionService.instance.addPoints(_quests[idx].rewardPoints);
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final encoded = jsonEncode(_quests.map((q) => q.toJson()).toList());
    await _prefs?.setString(_keyQuests, encoded);
    notifyListeners();
  }

  List<Quest> _getRandomQuests() {
    final possibleQuests = [
      Quest(
          id: 'water',
          title: 'Hydration Check',
          description: 'Drink 3 glasses of water today.',
          rewardPoints: 5),
      Quest(
          id: 'walk',
          title: 'Stretch those legs',
          description: 'Take a small 10 minute walk.',
          rewardPoints: 10),
      Quest(
          id: 'talk',
          title: 'Daily Check-in',
          description: 'Say "Good Morning" or "Good Night" to me.',
          rewardPoints: 5),
      Quest(
          id: 'read',
          title: 'Bookworm',
          description: 'Read a book or article for 15 minutes.',
          rewardPoints: 15),
      Quest(
          id: 'compliment',
          title: 'Spread Positivity',
          description: 'Give someone a genuine compliment today.',
          rewardPoints: 10),
      Quest(
          id: 'breathe',
          title: 'Take a Breath',
          description: 'Do 2 minutes of deep breathing exercises.',
          rewardPoints: 5),
      Quest(
          id: 'clean',
          title: 'Tidy Space, Tidy Mind',
          description: 'Spend 5 minutes organizing your room.',
          rewardPoints: 10),
      Quest(
          id: 'sleep',
          title: 'Beauty Rest',
          description: 'Go to bed before midnight tonight.',
          rewardPoints: 15),
    ];
    possibleQuests.shuffle(Random());
    return possibleQuests.take(3).toList(); // 3 daily quests
  }
}
