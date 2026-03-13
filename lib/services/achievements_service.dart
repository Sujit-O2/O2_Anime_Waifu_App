import 'package:flutter/material.dart';
import 'firestore_service.dart';

/// Achievement definitions — all badge IDs that can be unlocked.
class AchievementDef {
  final String id;
  final String title;
  final String emoji;
  final String description;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
  });
}

/// Service for loading and displaying earned achievement badges.
/// Unlocking is done via FirestoreService.unlockAchievement().
class AchievementsService extends ChangeNotifier {
  static final AchievementsService instance = AchievementsService._internal();

  List<String> _unlocked = [];
  List<String> get unlocked => _unlocked;

  AchievementsService._internal() {
    load();
  }

  Future<void> load() async {
    _unlocked = await FirestoreService().loadAchievements();
    notifyListeners();
  }

  bool isUnlocked(String id) => _unlocked.contains(id);

  /// Unlock an achievement and notify listeners
  Future<bool> unlock(String id) async {
    final wasNew = await FirestoreService().unlockAchievement(id);
    if (wasNew) {
      _unlocked.add(id);
      notifyListeners();
    }
    return wasNew;
  }

  // ── All defined achievements ───────────────────────────────────────────────

  static const List<AchievementDef> all = [
    AchievementDef(
        id: 'first_message',
        title: 'First Words',
        emoji: '💬',
        description: 'Send your first message to Zero Two'),
    AchievementDef(
        id: 'chat_100',
        title: '100 Chats',
        emoji: '🏆',
        description: 'Send 100 messages total'),
    AchievementDef(
        id: 'first_100_pts',
        title: 'Getting Closer',
        emoji: '💕',
        description: 'Reach 100 affection points'),
    AchievementDef(
        id: '500_pts',
        title: 'Sweet Bond',
        emoji: '💖',
        description: 'Reach 500 affection points'),
    AchievementDef(
        id: '1000_pts',
        title: 'Unbreakable',
        emoji: '💞',
        description: 'Reach 1,000 affection points'),
    AchievementDef(
        id: '7_day_streak',
        title: 'Weekly Loyal',
        emoji: '🔥',
        description: 'Chat 7 days in a row'),
    AchievementDef(
        id: '30_day_streak',
        title: 'Monthly Devotion',
        emoji: '♾️',
        description: 'Chat 30 days in a row'),
    AchievementDef(
        id: 'first_memory_saved',
        title: 'Never Forgotten',
        emoji: '🧠',
        description: 'First memory fact saved'),
    AchievementDef(
        id: 'first_custom_quest',
        title: 'Quest Creator',
        emoji: '🎯',
        description: 'Create your first custom quest'),
    AchievementDef(
        id: 'all_daily_quests',
        title: 'Perfect Day',
        emoji: '✅',
        description: 'Complete all daily quests in one day'),
    AchievementDef(
        id: 'first_secret_note',
        title: 'Secret Keeper',
        emoji: '🔒',
        description: 'Write your first secret note'),
    AchievementDef(
        id: 'mood_7_entries',
        title: 'Mood Tracker',
        emoji: '😊',
        description: 'Log your mood 7 times'),
    AchievementDef(
        id: 'anniversary_1',
        title: 'One Month Together',
        emoji: '🎂',
        description: 'Use the app for 30 days'),
  ];

  static AchievementDef? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Widget to display achievement badges on the achievements page
class AchievementBadge extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;

  const AchievementBadge(
      {super.key, required this.def, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.35,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: unlocked
              ? LinearGradient(colors: [
                  Colors.pinkAccent.withValues(alpha: 0.2),
                  Colors.deepPurple.withValues(alpha: 0.15),
                ])
              : null,
          color: unlocked ? null : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: unlocked
                ? Colors.pinkAccent.withValues(alpha: 0.5)
                : Colors.white12,
            width: unlocked ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(def.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              def.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: unlocked ? Colors.white : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              def.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: unlocked ? Colors.white54 : Colors.white24,
                fontSize: 9,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
