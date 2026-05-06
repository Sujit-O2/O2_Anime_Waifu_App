import 'dart:async' show unawaited;
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class AchievementRoomPage extends StatefulWidget {
  const AchievementRoomPage({super.key});

  @override
  State<AchievementRoomPage> createState() => _AchievementRoomPageState();
}

class _AchievementRoomPageState extends State<AchievementRoomPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  Map<String, int> _stats = <String, int>{};
  bool _loading = true;

  static final List<_Ach> _achievements = <_Ach>[
    const _Ach(
      'first_message',
      '💬',
      'First Words',
      'Send your very first message to Zero Two',
      'Chat',
      _Rarity.common,
      10,
      stat: 'msg_count',
      goal: 1,
    ),
    const _Ach(
      'chat_10',
      '💬',
      'Getting to Know Her',
      'Send 10 messages',
      'Chat',
      _Rarity.common,
      15,
      stat: 'msg_count',
      goal: 10,
    ),
    const _Ach(
      'chat_100',
      '🗨️',
      'Chatterbox',
      'Send 100 messages to Zero Two',
      'Chat',
      _Rarity.rare,
      50,
      stat: 'msg_count',
      goal: 100,
    ),
    const _Ach(
      'chat_500',
      '📢',
      'Never Stop Talking',
      'Send 500 messages',
      'Chat',
      _Rarity.epic,
      100,
      stat: 'msg_count',
      goal: 500,
    ),
    const _Ach(
      'chat_1000',
      '🎤',
      'Zero Two\'s Favorite',
      'Send 1000 messages. She really loves hearing from you.',
      'Chat',
      _Rarity.legendary,
      250,
      stat: 'msg_count',
      goal: 1000,
    ),
    const _Ach(
      'affection_50',
      '💕',
      'Sweet Darling',
      'Reach 50 affection points',
      'Affection',
      _Rarity.common,
      20,
      stat: 'affection',
      goal: 50,
    ),
    const _Ach(
      'affection_200',
      '💖',
      'Beloved',
      'Reach 200 affection points',
      'Affection',
      _Rarity.rare,
      60,
      stat: 'affection',
      goal: 200,
    ),
    const _Ach(
      'affection_500',
      '💗',
      'Devotion',
      'Reach 500 affection points',
      'Affection',
      _Rarity.epic,
      120,
      stat: 'affection',
      goal: 500,
    ),
    const _Ach(
      'affection_1000',
      '❣️',
      'Soulmate',
      'Reach 1000 affection points and lock in the bond.',
      'Affection',
      _Rarity.legendary,
      300,
      stat: 'affection',
      goal: 1000,
    ),
    const _Ach(
      'first_reaction',
      '❤️',
      'Heart Giver',
      'React with a heart to a Zero Two message for the first time',
      'Affection',
      _Rarity.common,
      25,
      stat: 'heart_reactions',
      goal: 1,
    ),
    const _Ach(
      'first_song',
      '🎵',
      'Music Begins',
      'Play a song for the first time',
      'Music',
      _Rarity.common,
      10,
      stat: 'songs_played',
      goal: 1,
    ),
    const _Ach(
      'songs_10',
      '🎶',
      'Music Lover',
      'Play 10 songs',
      'Music',
      _Rarity.rare,
      40,
      stat: 'songs_played',
      goal: 10,
    ),
    const _Ach(
      'songs_50',
      '🎸',
      'DJ Darling',
      'Play 50 songs total',
      'Music',
      _Rarity.epic,
      90,
      stat: 'songs_played',
      goal: 50,
    ),
    const _Ach(
      'first_mood',
      '😊',
      'Feelings First',
      'Log your very first mood',
      'Mood',
      _Rarity.common,
      15,
      stat: 'mood_logs',
      goal: 1,
    ),
    const _Ach(
      'mood_7',
      '📊',
      'Week Check-In',
      'Log your mood 7 days in a row',
      'Mood',
      _Rarity.rare,
      50,
      stat: 'mood_logs',
      goal: 7,
    ),
    const _Ach(
      'mood_30',
      '🌈',
      'Emotional Diary',
      'Log your mood 30 times',
      'Mood',
      _Rarity.epic,
      100,
      stat: 'mood_logs',
      goal: 30,
    ),
    const _Ach(
      'first_challenge',
      '🎯',
      'Mission Accepted',
      'Complete your first daily challenge',
      'Special',
      _Rarity.common,
      20,
      stat: 'challenges_done',
      goal: 1,
    ),
    const _Ach(
      'challenge_7',
      '🏆',
      'Challenge Streak',
      'Complete 7 daily challenges',
      'Special',
      _Rarity.rare,
      70,
      stat: 'challenges_done',
      goal: 7,
    ),
    const _Ach(
      'tarot_reader',
      '🔮',
      'Card Reader',
      'Draw the tarot cards at least once',
      'Special',
      _Rarity.common,
      20,
      stat: 'tarot_draws',
      goal: 1,
    ),
    const _Ach(
      'night_owl',
      '🌙',
      'Night Owl',
      'Chat with Zero Two after midnight',
      'Special',
      _Rarity.rare,
      45,
      stat: 'night_chats',
      goal: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('achievement_room'));
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadStats();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _stats = <String, int>{
        'msg_count': prefs.getInt('flutter.total_message_count') ??
            prefs.getInt('total_message_count') ??
            0,
        'affection': prefs.getInt('flutter.affection_points') ??
            prefs.getInt('affection_points') ??
            0,
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
    for (final key in prefs.getKeys()) {
      if (key.startsWith('mood_log_')) {
        count++;
      }
    }
    return count;
  }

  int _countChallenges(SharedPreferences prefs) {
    int count = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('challenge_') && key.endsWith('_done')) {
        count++;
      }
    }
    return count;
  }

  bool _isUnlocked(_Ach achievement) {
    return (_stats[achievement.stat] ?? 0) >= achievement.goal;
  }

  int _currentVal(_Ach achievement) => _stats[achievement.stat] ?? 0;

  int get _totalXp => _achievements
      .where(_isUnlocked)
      .fold<int>(0, (sum, achievement) => sum + achievement.xp);

  int get _unlocked => _achievements.where(_isUnlocked).length;

  double get _completionValue =>
      _achievements.isEmpty ? 0 : _unlocked / _achievements.length;

  Future<void> _refresh() => _loadStats();

  @override
  Widget build(BuildContext context) {
    final categories = <String>[
      'Chat',
      'Affection',
      'Music',
      'Mood',
      'Special'
    ];
    final completion = (_completionValue * 100).round();

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: const Color(0xFF0B0914),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: V2Theme.primaryColor),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: V2Theme.primaryColor,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white70,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ACHIEVEMENT ROOM',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                    Text(
                                      'Milestones, rarity, and progression',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: GlassCard(
                            margin: EdgeInsets.zero,
                            glow: true,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Vault progress',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$_unlocked / ${_achievements.length} unlocked',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Total XP: $_totalXp and $completion% completion across every tracked category.',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white60,
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ProgressRing(
                                  progress: _completionValue,
                                  foreground: V2Theme.primaryColor,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.workspace_premium_rounded,
                                        color: V2Theme.primaryColor,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$completion%',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Complete',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),

                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  title: 'Unlocked',
                                  value: '$_unlocked',
                                  icon: Icons.lock_open_rounded,
                                  color: V2Theme.primaryColor,
                                ),
                              ),
                              Expanded(
                                child: StatCard(
                                  title: 'Locked',
                                  value: '${_achievements.length - _unlocked}',
                                  icon: Icons.lock_outline_rounded,
                                  color: V2Theme.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  title: 'XP',
                                  value: '$_totalXp',
                                  icon: Icons.auto_awesome_rounded,
                                  color: Colors.amberAccent,
                                ),
                              ),
                              Expanded(
                                child: StatCard(
                                  title: 'Categories',
                                  value: '${categories.length}',
                                  icon: Icons.grid_view_rounded,
                                  color: Colors.lightGreenAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final category in categories) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: _catColor(category)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _catIcon(category),
                                    color: _catColor(category),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  category,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_achievements.where((a) => a.category == category && _isUnlocked(a)).length}/${_achievements.where((a) => a.category == category).length}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate(
                              _achievements
                                  .where((a) => a.category == category)
                                  .map((a) => AnimatedEntry(
                                        index: _achievements.indexOf(a),
                                        child: _buildAchCard(a),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAchCard(_Ach achievement) {
    final unlocked = _isUnlocked(achievement);
    final current = _currentVal(achievement).clamp(0, achievement.goal);
    final progress = current / achievement.goal;
    final rarityColor = _rarityColor(achievement.rarity);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: unlocked
                ? rarityColor.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: unlocked
                  ? rarityColor.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.08),
              width: unlocked ? 1.4 : 1,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.16),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unlocked
                        ? rarityColor.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                  child: Center(
                    child: Text(
                      unlocked ? achievement.emoji : '🔒',
                      style: TextStyle(fontSize: unlocked ? 26 : 20),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.title,
                              style: GoogleFonts.outfit(
                                color: unlocked ? Colors.white : Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _rarityBadge(achievement.rarity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            unlocked ? rarityColor : Colors.white38,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unlocked
                            ? 'Completed'
                            : '$current / ${achievement.goal}',
                        style: GoogleFonts.outfit(
                          color: unlocked ? rarityColor : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text(
                      '+${achievement.xp}',
                      style: GoogleFonts.outfit(
                        color: unlocked ? rarityColor : Colors.white24,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'XP',
                      style: GoogleFonts.outfit(
                        color: Colors.white24,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rarityBadge(_Rarity rarity) {
    final label = _rarityLabel(rarity);
    final color = _rarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _rarityColor(_Rarity rarity) {
    switch (rarity) {
      case _Rarity.common:
        return Colors.white70;
      case _Rarity.rare:
        return Colors.blueAccent;
      case _Rarity.epic:
        return Colors.purpleAccent;
      case _Rarity.legendary:
        return Colors.amberAccent;
    }
  }

  String _rarityLabel(_Rarity rarity) {
    switch (rarity) {
      case _Rarity.common:
        return 'COMMON';
      case _Rarity.rare:
        return 'RARE';
      case _Rarity.epic:
        return 'EPIC';
      case _Rarity.legendary:
        return 'LEGENDARY';
    }
  }

  IconData _catIcon(String category) {
    switch (category) {
      case 'Chat':
        return Icons.chat_bubble_outline_rounded;
      case 'Affection':
        return Icons.favorite_border_rounded;
      case 'Music':
        return Icons.music_note_rounded;
      case 'Mood':
        return Icons.mood_rounded;
      case 'Special':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.workspace_premium_outlined;
    }
  }

  Color _catColor(String category) {
    switch (category) {
      case 'Chat':
        return V2Theme.secondaryColor;
      case 'Affection':
        return V2Theme.primaryColor;
      case 'Music':
        return Colors.amberAccent;
      case 'Mood':
        return Colors.lightGreenAccent;
      case 'Special':
        return Colors.purpleAccent;
      default:
        return Colors.white70;
    }
  }
}

enum _Rarity { common, rare, epic, legendary }

class _Ach {
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

  final String id;
  final String emoji;
  final String title;
  final String description;
  final String category;
  final _Rarity rarity;
  final int xp;
  final String stat;
  final int goal;
}



