import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementRoomPage extends StatefulWidget {
  const AchievementRoomPage({super.key});

  @override
  State<AchievementRoomPage> createState() => _AchievementRoomPageState();
}

class _AchievementRoomPageState extends State<AchievementRoomPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  Map<String, int> _stats = {};
  bool _loading = true;

  // All achievements definition
  static final _achievements = [
    // 💬 Chat
    _Ach('first_message', '💬', 'First Words', 'Send your very first message to Zero Two', 'Chat', _Rarity.common, 10, stat: 'msg_count', goal: 1),
    _Ach('chat_10', '💬', 'Getting to Know Her', 'Send 10 messages', 'Chat', _Rarity.common, 15, stat: 'msg_count', goal: 10),
    _Ach('chat_100', '🗨️', 'Chatterbox', 'Send 100 messages to Zero Two', 'Chat', _Rarity.rare, 50, stat: 'msg_count', goal: 100),
    _Ach('chat_500', '📢', 'Never Stop Talking', 'Send 500 messages', 'Chat', _Rarity.epic, 100, stat: 'msg_count', goal: 500),
    _Ach('chat_1000', '🎤', 'Zero Two\'s Favorite', 'Send 1000 messages — she loves you~', 'Chat', _Rarity.legendary, 250, stat: 'msg_count', goal: 1000),

    // 💕 Affection
    _Ach('affection_50', '💕', 'Sweet Darling', 'Reach 50 affection points', 'Affection', _Rarity.common, 20, stat: 'affection', goal: 50),
    _Ach('affection_200', '💖', 'Beloved', 'Reach 200 affection points', 'Affection', _Rarity.rare, 60, stat: 'affection', goal: 200),
    _Ach('affection_500', '💗', 'Devotion', 'Reach 500 affection points', 'Affection', _Rarity.epic, 120, stat: 'affection', goal: 500),
    _Ach('affection_1000', '❣️', 'Soulmate', 'Reach 1000 affection points — you\'re hers~', 'Affection', _Rarity.legendary, 300, stat: 'affection', goal: 1000),
    _Ach('first_reaction', '❤️', 'Heart Giver', 'React with ❤️ to a Zero Two message for the first time', 'Affection', _Rarity.common, 25, stat: 'heart_reactions', goal: 1),

    // 🎵 Music
    _Ach('first_song', '🎵', 'Music Begins', 'Play a song for the first time', 'Music', _Rarity.common, 10, stat: 'songs_played', goal: 1),
    _Ach('songs_10', '🎶', 'Music Lover', 'Play 10 songs', 'Music', _Rarity.rare, 40, stat: 'songs_played', goal: 10),
    _Ach('songs_50', '🎸', 'DJ Darling', 'Play 50 songs total', 'Music', _Rarity.epic, 90, stat: 'songs_played', goal: 50),

    // 😄 Mood & Challenges
    _Ach('first_mood', '😊', 'Feelings First', 'Log your very first mood', 'Mood', _Rarity.common, 15, stat: 'mood_logs', goal: 1),
    _Ach('mood_7', '📊', 'Week Check-In', 'Log your mood 7 days in a row', 'Mood', _Rarity.rare, 50, stat: 'mood_logs', goal: 7),
    _Ach('mood_30', '🌈', 'Emotional Diary', 'Log your mood 30 times', 'Mood', _Rarity.epic, 100, stat: 'mood_logs', goal: 30),
    _Ach('first_challenge', '🎯', 'Mission Accepted', 'Complete your first Daily Challenge', 'Special', _Rarity.common, 20, stat: 'challenges_done', goal: 1),
    _Ach('challenge_7', '🏅', 'Challenge Streak', 'Complete 7 Daily Challenges', 'Special', _Rarity.rare, 70, stat: 'challenges_done', goal: 7),

    // ✨ Special
    _Ach('tarot_reader', '🔮', 'Card Reader', 'Draw the tarot cards at least once', 'Special', _Rarity.common, 20, stat: 'tarot_draws', goal: 1),
    _Ach('night_owl', '🌙', 'Night Owl', 'Chat with Zero Two after midnight (local time)', 'Special', _Rarity.rare, 45, stat: 'night_chats', goal: 1),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _loadStats();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stats = {
        'msg_count': prefs.getInt('flutter.total_message_count') ?? prefs.getInt('total_message_count') ?? 0,
        'affection': prefs.getInt('flutter.affection_points') ?? prefs.getInt('affection_points') ?? 0,
        'heart_reactions': prefs.getInt('heart_reactions_given') ?? 0,
        'songs_played': prefs.getInt('songs_played_count') ?? 0,
        'mood_logs': _countMoodLogs(prefs),
        'challenges_done': _countChallenges(prefs),
        'tarot_draws': prefs.getInt('tarot_draws') ?? 0,
        'night_chats': prefs.getInt('night_chats') ?? 0,
      };
      _loading = false;
    });
  }

  int _countMoodLogs(SharedPreferences prefs) {
    int count = 0;
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('mood_log_')) count++;
    }
    return count;
  }

  int _countChallenges(SharedPreferences prefs) {
    int count = 0;
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.endsWith('_done') && key.startsWith('challenge_')) count++;
    }
    return count;
  }

  bool _isUnlocked(_Ach a) {
    final val = _stats[a.stat] ?? 0;
    return val >= a.goal;
  }

  int _currentVal(_Ach a) => _stats[a.stat] ?? 0;

  int get _totalXp => _achievements
      .where(_isUnlocked)
      .fold<int>(0, (sum, a) => sum + a.xp);

  int get _unlocked => _achievements.where(_isUnlocked).length;

  @override
  Widget build(BuildContext context) {
    final categories = ['Chat', 'Affection', 'Music', 'Mood', 'Special'];
    final completion = (_unlocked / _achievements.length * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0514),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Achievement Room',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : CustomScrollView(slivers: [
              // Header stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(children: [
                    // Trophy icon + title
                    const Text('🏆', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 6),
                    Text('$_unlocked / ${_achievements.length} Unlocked',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Total XP: $_totalXp  ·  $completion% Complete',
                        style: GoogleFonts.outfit(
                            color: Colors.pinkAccent, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    // Overall progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _unlocked / _achievements.length,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      completion == 100
                          ? '💕 Zero Two is completely yours~'
                          : 'Keep going, Darling~ She\'s watching you!',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11,
                          fontStyle: FontStyle.italic),
                    ),
                  ]),
                ),
              ),

              // Category sections
              for (final cat in categories) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(children: [
                      Text(_catEmoji(cat),
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(cat,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(
                        '${_achievements.where((a) => a.category == cat && _isUnlocked(a)).length}/${_achievements.where((a) => a.category == cat).length}',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _achievements
                          .where((a) => a.category == cat)
                          .map((a) => _buildAchCard(a))
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ]),
    );
  }

  Widget _buildAchCard(_Ach a) {
    final unlocked = _isUnlocked(a);
    final current = _currentVal(a).clamp(0, a.goal);
    final progress = current / a.goal;
    final rarityColor = _rarityColor(a.rarity);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: unlocked
                ? rarityColor.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: unlocked
                  ? rarityColor.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
              width: unlocked ? 1.4 : 1,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Emoji badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? rarityColor.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                ),
                child: Center(
                  child: Text(
                    unlocked ? a.emoji : '🔒',
                    style: TextStyle(fontSize: unlocked ? 26 : 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text(a.title,
                        style: GoogleFonts.outfit(
                            color: unlocked ? Colors.white : Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    _rarityBadge(a.rarity),
                  ]),
                  const SizedBox(height: 2),
                  Text(a.description,
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(
                          unlocked ? rarityColor : Colors.white38),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    unlocked
                        ? '✓ Completed'
                        : '$current / ${a.goal}',
                    style: GoogleFonts.outfit(
                        color: unlocked ? rarityColor : Colors.white30,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              // XP badge
              Column(children: [
                Text('+${a.xp}',
                    style: GoogleFonts.outfit(
                        color: unlocked ? rarityColor : Colors.white.withValues(alpha: 0.12),
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                Text('XP',
                    style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.15), fontSize: 9)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _rarityBadge(_Rarity r) {
    final label = _rarityLabel(r);
    final color = _rarityColor(r);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.outfit(
              color: color, fontSize: 8, fontWeight: FontWeight.w700)),
    );
  }

  Color _rarityColor(_Rarity r) {
    switch (r) {
      case _Rarity.common:    return Colors.white60;
      case _Rarity.rare:      return Colors.blueAccent;
      case _Rarity.epic:      return Colors.purpleAccent;
      case _Rarity.legendary: return Colors.amberAccent;
    }
  }

  String _rarityLabel(_Rarity r) {
    switch (r) {
      case _Rarity.common:    return 'COMMON';
      case _Rarity.rare:      return 'RARE';
      case _Rarity.epic:      return 'EPIC';
      case _Rarity.legendary: return 'LEGENDARY';
    }
  }

  String _catEmoji(String cat) {
    switch (cat) {
      case 'Chat':      return '💬';
      case 'Affection': return '💕';
      case 'Music':     return '🎵';
      case 'Mood':      return '😊';
      case 'Special':   return '✨';
      default:          return '🏆';
    }
  }
}

enum _Rarity { common, rare, epic, legendary }

class _Ach {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final String category;
  final _Rarity rarity;
  final int xp;
  final String stat;
  final int goal;

  const _Ach(
    this.id,
    this.emoji,
    this.title,
    this.description,
    this.category,
    this.rarity,
    this.xp, {
    required this.stat,
    required this.goal,
  });
}
