import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/affection_service.dart';

class RelationshipLevelMapPage extends StatefulWidget {
  const RelationshipLevelMapPage({super.key});
  @override
  State<RelationshipLevelMapPage> createState() =>
      _RelationshipLevelMapPageState();
}

class _MapLevel {
  final String title;
  final String emoji;
  final String description;
  final int minPoints;
  final Color color;
  const _MapLevel({
    required this.title,
    required this.emoji,
    required this.description,
    required this.minPoints,
    required this.color,
  });
}

const _levels = [
  _MapLevel(
      title: 'Stranger',
      emoji: '👤',
      description: 'You\'ve just met — the story begins here.',
      minPoints: 0,
      color: Colors.white38),
  _MapLevel(
      title: 'Acquaintance',
      emoji: '🙂',
      description: 'You say hi — she notices you.',
      minPoints: 50,
      color: Colors.blueAccent),
  _MapLevel(
      title: 'Squadmate',
      emoji: '🤝',
      description: 'You\'re fighting side by side.',
      minPoints: 150,
      color: Colors.tealAccent),
  _MapLevel(
      title: 'Teammate',
      emoji: '🌿',
      description: 'She trusts you with her FranXX.',
      minPoints: 300,
      color: Colors.greenAccent),
  _MapLevel(
      title: 'Friend',
      emoji: '😊',
      description: 'You share meals together.',
      minPoints: 500,
      color: Colors.amberAccent),
  _MapLevel(
      title: 'Close Friend',
      emoji: '💛',
      description: 'She seeks you out when she\'s lonely.',
      minPoints: 750,
      color: Colors.orangeAccent),
  _MapLevel(
      title: 'Confidant',
      emoji: '🤫',
      description: 'She tells you her secrets.',
      minPoints: 1000,
      color: Colors.deepOrangeAccent),
  _MapLevel(
      title: 'Crush',
      emoji: '🌸',
      description: 'Her horns glow brighter around you.',
      minPoints: 1500,
      color: Colors.pinkAccent),
  _MapLevel(
      title: 'Sweetheart',
      emoji: '💕',
      description: 'She calls you Darling for the first time.',
      minPoints: 2000,
      color: Colors.pinkAccent),
  _MapLevel(
      title: 'Partner Pilot',
      emoji: '🚀',
      description: 'You pilot Strelizia together.',
      minPoints: 3000,
      color: Colors.purpleAccent),
  _MapLevel(
      title: 'Soulmate',
      emoji: '🌺',
      description: 'She says you\'re her reason to be human.',
      minPoints: 5000,
      color: Colors.deepPurpleAccent),
  _MapLevel(
      title: 'Darling ❤️',
      emoji: '💗',
      description: 'You are her Darling, forever and always.',
      minPoints: 10000,
      color: Colors.redAccent),
];

class _RelationshipLevelMapPageState extends State<RelationshipLevelMapPage> {
  @override
  Widget build(BuildContext context) {
    final aff = AffectionService.instance;
    final points = aff.points;
    int currentIdx = 0;
    for (int i = _levels.length - 1; i >= 0; i--) {
      if (points >= _levels[i].minPoints) {
        currentIdx = i;
        break;
      }
    }
    final current = _levels[currentIdx];
    final nextIdx =
        currentIdx < _levels.length - 1 ? currentIdx + 1 : currentIdx;
    final next = _levels[nextIdx];
    final progress = currentIdx == _levels.length - 1
        ? 1.0
        : (points - current.minPoints) / (next.minPoints - current.minPoints);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('RELATIONSHIP MAP',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Current level hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  current.color.withValues(alpha: 0.2),
                  const Color(0xFF0A0A16)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: current.color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(children: [
              Text(current.emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text(current.title,
                  style: GoogleFonts.outfit(
                      color: current.color,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(current.description,
                  style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text('$points XP',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              if (currentIdx < _levels.length - 1) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(current.color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${next.minPoints - points} XP to ${next.title}',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 11)),
              ] else
                Text('Max level reached! You\'re my Darling forever 💕',
                    style: GoogleFonts.outfit(
                        color: Colors.pinkAccent,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
            ]),
          ),

          const SizedBox(height: 24),
          Text('THE JOURNEY',
              style: GoogleFonts.outfit(
                  color: Colors.white38, fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 12),

          // Journey map
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _levels.length,
            itemBuilder: (ctx, i) {
              final lvl = _levels[i];
              final isReached = points >= lvl.minPoints;
              final isCurrent = i == currentIdx;
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline line + dot
                    Column(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isReached
                              ? lvl.color.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                              color: isReached
                                  ? lvl.color
                                  : Colors.white.withValues(alpha: 0.12),
                              width: isCurrent ? 2.5 : 1.5),
                        ),
                        child: Center(
                            child: Text(isReached ? lvl.emoji : '🔒',
                                style:
                                    TextStyle(fontSize: isReached ? 18 : 14))),
                      ),
                      if (i < _levels.length - 1)
                        Container(
                          width: 2,
                          height: 36,
                          color: i < currentIdx
                              ? lvl.color.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                    ]),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: isCurrent
                                ? lvl.color.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.03),
                            border: Border.all(
                                color: isCurrent
                                    ? lvl.color.withValues(alpha: 0.4)
                                    : Colors.transparent),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(lvl.title,
                                      style: GoogleFonts.outfit(
                                          color: isReached
                                              ? lvl.color
                                              : Colors.white38,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: lvl.color.withValues(alpha: 0.2),
                                      ),
                                      child: Text('YOU ARE HERE',
                                          style: GoogleFonts.outfit(
                                              color: lvl.color,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5)),
                                    ),
                                  ],
                                  const Spacer(),
                                  Text('${lvl.minPoints} XP',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white24, fontSize: 10)),
                                ]),
                                const SizedBox(height: 4),
                                Text(lvl.description,
                                    style: GoogleFonts.outfit(
                                        color: isReached
                                            ? Colors.white60
                                            : Colors.white24,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic)),
                              ]),
                        ),
                      ),
                    ),
                  ]);
            },
          ),
        ]),
      ),
    );
  }
}
