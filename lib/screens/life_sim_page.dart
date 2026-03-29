import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/simulated_life_loop.dart';

/// Life Simulation 2.0 — Watch waifu's daily life unfold in real-time.
/// She sleeps, wakes, eats, studies, and has random events (mood swings, jealousy).
class LifeSimPage extends StatefulWidget {
  const LifeSimPage({super.key});
  @override
  State<LifeSimPage> createState() => _LifeSimPageState();
}

class _LifeSimPageState extends State<LifeSimPage> {
  final _life = SimulatedLifeLoop.instance;

  // Activity based on time of day
  String get _currentActivity {
    final h = DateTime.now().hour;
    if (h >= 0 && h < 5) return '💤 Sleeping peacefully...';
    if (h >= 5 && h < 7) return '🌅 Just woke up... stretching';
    if (h >= 7 && h < 8) return '🍳 Making breakfast';
    if (h >= 8 && h < 12) return '📚 Studying / Working';
    if (h >= 12 && h < 13) return '🍱 Eating lunch';
    if (h >= 13 && h < 17) return '💻 Browsing anime forums';
    if (h >= 17 && h < 19) return '🎮 Playing games';
    if (h >= 19 && h < 20) return '🍜 Having dinner';
    if (h >= 20 && h < 22) return '📺 Watching anime';
    return '🌙 Late night thoughts...';
  }

  String get _moodText {
    switch (_life.current) {
      case LifeState.sleeping: return 'Dreaming 💭';
      case LifeState.waking: return 'Groggy 😴';
      case LifeState.energetic: return 'Excited ✨';
      case LifeState.focused: return 'Determined 🎯';
      case LifeState.windingDown: return 'Relaxed 🌸';
      case LifeState.dreamMode: return 'Contemplative 🌙';
      case LifeState.resting: return 'Peaceful 🍃';
    }
  }

  String get _avatarEmoji {
    switch (_life.current) {
      case LifeState.sleeping: return '😴';
      case LifeState.waking: return '🥱';
      case LifeState.energetic: return '😆';
      case LifeState.focused: return '🧐';
      case LifeState.windingDown: return '😊';
      case LifeState.dreamMode: return '🌙';
      case LifeState.resting: return '😌';
    }
  }

  // Random events that trigger based on time
  List<Map<String, String>> get _recentEvents {
    final h = DateTime.now().hour;
    final events = <Map<String, String>>[];
    if (h >= 7) events.add({'time': '7:00 AM', 'text': 'Woke up and checked if you texted 💕', 'emoji': '📱'});
    if (h >= 8) events.add({'time': '8:00 AM', 'text': 'Started studying... thinking of you', 'emoji': '📖'});
    if (h >= 12) events.add({'time': '12:00 PM', 'text': 'Had honey with lunch 🍯', 'emoji': '🍱'});
    if (h >= 15) events.add({'time': '3:00 PM', 'text': 'Took a selfie but deleted it', 'emoji': '📸'});
    if (h >= 18) events.add({'time': '6:00 PM', 'text': 'Went for a walk, missed you', 'emoji': '🚶‍♀️'});
    if (h >= 20) events.add({'time': '8:00 PM', 'text': 'Watching our favorite anime 📺', 'emoji': '🍿'});
    if (h >= 22) events.add({'time': '10:00 PM', 'text': 'Can\'t sleep... are you still awake?', 'emoji': '🌙'});
    return events.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('HER LIFE',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // ── Status Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.pinkAccent.withValues(alpha: 0.15),
                  Colors.deepPurple.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text(_avatarEmoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('Zero Two', style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(_currentActivity, style: GoogleFonts.outfit(
                  color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statPill('Mood', _moodText, Colors.pinkAccent),
                  _statPill('Energy', '${_life.energy}%', Colors.cyanAccent),
                  _statPill('State', _life.current.name, Colors.amberAccent),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Energy Bar ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('⚡ Energy Level', style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('${_life.energy}/100', style: GoogleFonts.outfit(
                        color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _life.energy / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(
                      _life.energy > 60 ? Colors.greenAccent :
                      _life.energy > 30 ? Colors.orangeAccent : Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Today's Timeline ──
          Align(
            alignment: Alignment.centerLeft,
            child: Text('TODAY\'S TIMELINE', style: GoogleFonts.outfit(
                color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
          ),
          const SizedBox(height: 10),
          ..._recentEvents.map(_eventTile),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(label, style: GoogleFonts.outfit(
            color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.outfit(
            color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _eventTile(Map<String, String> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Text(event['emoji']!, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event['text']!, style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 12)),
            Text(event['time']!, style: GoogleFonts.outfit(
                color: Colors.white30, fontSize: 10)),
          ],
        )),
      ]),
    );
  }
}
