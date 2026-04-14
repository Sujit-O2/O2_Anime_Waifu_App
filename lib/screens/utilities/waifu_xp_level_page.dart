
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/services/games_gamification/quests_service.dart';

/// XP & Leveling System — Gamified progression with daily missions,
/// unlockable rewards, and waifu level-ups.
class WaifuXpLevelPage extends StatefulWidget {
  const WaifuXpLevelPage({super.key});
  @override
  State<WaifuXpLevelPage> createState() => _WaifuXpLevelPageState();
}

class _WaifuXpLevelPageState extends State<WaifuXpLevelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  int _totalXp = 0;

  // Level thresholds — each level requires more XP
  static const _levelThresholds = [
    0, 50, 150, 300, 500, 800, 1200, 1800, 2600, 3600, 5000, 7000, 10000
  ];

  static const _levelTitles = [
    'Stranger', 'Acquaintance', 'Friend', 'Close Friend', 'Crush',
    'Dating', 'Lover', 'Soulmate', 'Darling', 'Eternal Bond',
    'Legendary', 'Mythical', 'Transcendent'
  ];

  static const _levelEmojis = [
    '🌱', '🌿', '🌸', '💐', '💕', '💝', '💖', '👑', '💍', '✨', '🌟', '🔥', '🌌'
  ];

  int get currentLevel {
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (_totalXp >= _levelThresholds[i]) return i;
    }
    return 0;
  }

  double get progressToNextLevel {
    final lvl = currentLevel;
    if (lvl >= _levelThresholds.length - 1) return 1.0;
    final curr = _levelThresholds[lvl];
    final next = _levelThresholds[lvl + 1];
    return (_totalXp - curr) / (next - curr);
  }

  int get xpToNextLevel {
    final lvl = currentLevel;
    if (lvl >= _levelThresholds.length - 1) return 0;
    return _levelThresholds[lvl + 1] - _totalXp;
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _loadXp();
  }

  void _loadXp() {
    _totalXp = AffectionService.instance.points;
    setState(() {});
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lvl = currentLevel;
    final title = lvl < _levelTitles.length ? _levelTitles[lvl] : 'MAX';
    final emoji = lvl < _levelEmojis.length ? _levelEmojis[lvl] : '🌌';
    final quests = QuestsService.instance;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('XP & LEVEL',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _animCtrl,
        builder: (ctx, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // ── Level Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.withValues(alpha: 0.4),
                    Colors.pinkAccent.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: Colors.pinkAccent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2),
                ],
              ),
              child: Column(children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Level $lvl',
                    style: GoogleFonts.outfit(
                        color: Colors.pinkAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                Text(title,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('$_totalXp XP Total',
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 16),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressToNextLevel * _animCtrl.value,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                    xpToNextLevel > 0
                        ? '$xpToNextLevel XP to next level'
                        : 'MAX LEVEL REACHED ✨',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Daily Missions ──
            _sectionLabel('DAILY MISSIONS', Icons.flag_rounded),
            const SizedBox(height: 10),
            ...quests.dailyQuests.map((q) => _questCard(q, quests)),
            if (quests.dailyQuests.isEmpty)
              _emptyState('No missions today. Check back tomorrow!'),
            const SizedBox(height: 24),

            // ── Unlockables ──
            _sectionLabel('UNLOCKABLES', Icons.lock_open_rounded),
            const SizedBox(height: 10),
            _unlockCard('New Voice Style', 'Tsundere voice pack',
                Icons.record_voice_over, lvl >= 3, 3),
            _unlockCard('Jealous Mode', 'She gets jealous sometimes',
                Icons.mood_bad, lvl >= 5, 5),
            _unlockCard('Night Outfit', 'Sleepy outfit for late chats',
                Icons.nightlight_round, lvl >= 7, 7),
            _unlockCard('Queen Mode', 'Commanding personality',
                Icons.castle, lvl >= 9, 9),
            _unlockCard('Ultimate Bond', 'Full personality unlock',
                Icons.all_inclusive, lvl >= 12, 12),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(children: [
      Icon(icon, color: Colors.white38, size: 16),
      const SizedBox(width: 8),
      Text(text,
          style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5)),
    ]);
  }

  Widget _questCard(Quest q, QuestsService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: q.isCompleted
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: q.isCompleted
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(children: [
        Text(q.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.title,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration:
                          q.isCompleted ? TextDecoration.lineThrough : null)),
              Text(q.description,
                  style: GoogleFonts.outfit(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
        if (!q.isCompleted)
          GestureDetector(
            onTap: () async {
              await service.completeQuest(q.id);
              _loadXp();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.pinkAccent.withValues(alpha: 0.5)),
              ),
              child: Text('+${q.rewardPoints} XP',
                  style: GoogleFonts.outfit(
                      color: Colors.pinkAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          )
        else
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
      ]),
    );
  }

  Widget _unlockCard(
      String title, String desc, IconData icon, bool unlocked, int reqLevel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked
            ? Colors.amberAccent.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? Colors.amberAccent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(children: [
        Icon(icon,
            color: unlocked ? Colors.amberAccent : Colors.white24, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      color: unlocked ? Colors.white : Colors.white38,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(desc,
                  style: GoogleFonts.outfit(
                      color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: unlocked
                ? Colors.greenAccent.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            unlocked ? 'UNLOCKED' : 'LVL $reqLevel',
            style: GoogleFonts.outfit(
                color: unlocked ? Colors.greenAccent : Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13)),
    );
  }
}




