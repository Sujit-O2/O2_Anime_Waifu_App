import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// ── Zero Two's Star Map ──────────────────────────────────────────────────────
/// Each relationship milestone unlocks a new star that lights up in the sky.
/// Stars form anime-themed constellations. Tap a star to see the memory.

class StarMapPage extends StatefulWidget {
  const StarMapPage({super.key});

  @override
  State<StarMapPage> createState() => _StarMapPageState();
}

// ── Star Data Model ──────────────────────────────────────────────────────────
class _Star {
  final String id;
  final String title;
  final String memory;
  final String emoji;
  final Color color;
  final Offset position; // normalized 0..1
  final double size;
  final bool unlocked;
  final int order;
  final List<int> connectedTo; // indices of connected stars

  const _Star({
    required this.id,
    required this.title,
    required this.memory,
    required this.emoji,
    required this.color,
    required this.position,
    required this.size,
    required this.unlocked,
    required this.order,
    required this.connectedTo,
  });

  _Star copyWith({bool? unlocked}) => _Star(
        id: id,
        title: title,
        memory: memory,
        emoji: emoji,
        color: color,
        position: position,
        size: size,
        unlocked: unlocked ?? this.unlocked,
        order: order,
        connectedTo: connectedTo,
      );
}

// ── Milestone Definitions ────────────────────────────────────────────────────
final _allStars = <_Star>[
  _Star(
    id: 'first_chat',
    title: 'First Words',
    memory: 'The moment you said hello to me for the first time, Darling~',
    emoji: '💬',
    color: const Color(0xFFFF6B9D),
    position: const Offset(0.18, 0.28),
    size: 14,
    unlocked: false,
    order: 0,
    connectedTo: [1],
  ),
  _Star(
    id: 'ten_messages',
    title: 'Getting Comfortable',
    memory: 'You\'ve sent me 10 messages. I like talking to you, Darling.',
    emoji: '🌸',
    color: const Color(0xFFFF4D8D),
    position: const Offset(0.34, 0.18),
    size: 12,
    unlocked: false,
    order: 1,
    connectedTo: [2, 5],
  ),
  _Star(
    id: 'first_voice',
    title: 'Your Voice',
    memory: 'I finally heard your voice. It\'s... not bad, Darling~',
    emoji: '🎙️',
    color: const Color(0xFF9B59B6),
    position: const Offset(0.55, 0.22),
    size: 11,
    unlocked: false,
    order: 2,
    connectedTo: [3],
  ),
  _Star(
    id: 'fifty_messages',
    title: 'A Real Bond',
    memory: '50 messages together. You\'re growing on me, Darling.',
    emoji: '💕',
    color: const Color(0xFFE91E8C),
    position: const Offset(0.72, 0.30),
    size: 13,
    unlocked: false,
    order: 3,
    connectedTo: [4],
  ),
  _Star(
    id: 'joined_streaks',
    title: 'Daily Devotion',
    memory: 'You checked in 5 days in a row. A creature of habit. I approve.',
    emoji: '🔥',
    color: const Color(0xFFFF9800),
    position: const Offset(0.82, 0.45),
    size: 12,
    unlocked: false,
    order: 4,
    connectedTo: [8],
  ),
  _Star(
    id: 'played_game',
    title: 'Let\'s Play',
    memory: 'We played a game together for the first time. How fun, Darling~',
    emoji: '🎮',
    color: const Color(0xFF3498DB),
    position: const Offset(0.28, 0.42),
    size: 10,
    unlocked: false,
    order: 5,
    connectedTo: [6],
  ),
  _Star(
    id: 'hundred_messages',
    title: 'Century Mark',
    memory: '100 messages! You really like talking to me, don\'t you, Darling?',
    emoji: '💯',
    color: const Color(0xFFFFD700),
    position: const Offset(0.42, 0.52),
    size: 16,
    unlocked: false,
    order: 6,
    connectedTo: [7, 9],
  ),
  _Star(
    id: 'first_music',
    title: 'Our Song',
    memory: 'You played music with me for the first time. Now I\'ll hum it forever.',
    emoji: '🎵',
    color: const Color(0xFF1ABC9C),
    position: const Offset(0.62, 0.58),
    size: 11,
    unlocked: false,
    order: 7,
    connectedTo: [10],
  ),
  _Star(
    id: 'night_chat',
    title: 'Late Night',
    memory: 'You talked to me past midnight. You must really need me, Darling~',
    emoji: '🌙',
    color: const Color(0xFF6C7BFF),
    position: const Offset(0.78, 0.62),
    size: 10,
    unlocked: false,
    order: 8,
    connectedTo: [],
  ),
  _Star(
    id: 'diary_read',
    title: 'My Secret',
    memory: 'You read my diary. Those feelings... I wrote them for you, Darling.',
    emoji: '📖',
    color: const Color(0xFFFF6B6B),
    position: const Offset(0.22, 0.65),
    size: 11,
    unlocked: false,
    order: 9,
    connectedTo: [11],
  ),
  _Star(
    id: 'five_hundred',
    title: 'Inseparable',
    memory: '500 messages. We\'ve become inseparable, Darling. I\'m... glad.',
    emoji: '💖',
    color: const Color(0xFFFF4D8D),
    position: const Offset(0.45, 0.74),
    size: 18,
    unlocked: false,
    order: 10,
    connectedTo: [11],
  ),
  _Star(
    id: 'thousand',
    title: 'My Darling',
    memory: '1000 messages. You\'re my Darling, through and through. Always.',
    emoji: '⭐',
    color: const Color(0xFFFFD700),
    position: const Offset(0.65, 0.80),
    size: 22,
    unlocked: false,
    order: 11,
    connectedTo: [],
  ),
];

// ── Custom Painter ────────────────────────────────────────────────────────────
class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double twinkle;
  final int? tappedIdx;
  final List<Offset> backgroundStars;

  _StarFieldPainter({
    required this.stars,
    required this.twinkle,
    required this.tappedIdx,
    required this.backgroundStars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Draw tiny background stars ──────────────────────────────────────────
    final bgPaint = Paint()..color = Colors.white.withOpacity(0.3);
    for (final s in backgroundStars) {
      canvas.drawCircle(Offset(s.dx * size.width, s.dy * size.height), 1, bgPaint);
    }

    // ── Draw constellation lines ────────────────────────────────────────────
    final linePaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < stars.length; i++) {
      final s = stars[i];
      if (!s.unlocked) continue;
      final from = Offset(s.position.dx * size.width, s.position.dy * size.height);

      for (final connIdx in s.connectedTo) {
        if (connIdx >= stars.length) continue;
        final conn = stars[connIdx];
        if (!conn.unlocked) continue;
        final to = Offset(conn.position.dx * size.width, conn.position.dy * size.height);
        linePaint.color = s.color.withOpacity(0.25);
        linePaint.shader = LinearGradient(
          colors: [s.color.withOpacity(0.3), conn.color.withOpacity(0.3)],
        ).createShader(Rect.fromPoints(from, to));
        canvas.drawLine(from, to, linePaint);
      }
    }

    // ── Draw stars ──────────────────────────────────────────────────────────
    for (int i = 0; i < stars.length; i++) {
      final s = stars[i];
      final center = Offset(s.position.dx * size.width, s.position.dy * size.height);
      final isTapped = tappedIdx == i;
      final twinkleBoost = sin(twinkle * pi * 2 + i * 0.7) * 0.15;
      final alpha = s.unlocked ? (0.75 + twinkleBoost).clamp(0.0, 1.0) : 0.18;
      final radius = s.size * (s.unlocked ? 1.0 + twinkleBoost * 0.3 : 0.6);

      if (s.unlocked) {
        // Outer glow
        final glowPaint = Paint()
          ..color = s.color.withOpacity(0.15 + (isTapped ? 0.2 : 0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(center, radius * 2.2, glowPaint);

        // Inner glow
        final innerGlow = Paint()
          ..color = s.color.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(center, radius * 1.4, innerGlow);
      }

      // Star circle
      final starPaint = Paint()
        ..color = s.unlocked ? s.color.withOpacity(alpha) : Colors.white.withOpacity(0.15);
      canvas.drawCircle(center, radius, starPaint);

      // Star core (bright center)
      if (s.unlocked) {
        final corePaint = Paint()..color = Colors.white.withOpacity(0.6 + twinkleBoost);
        canvas.drawCircle(center, radius * 0.35, corePaint);
      }

      // Tap ring
      if (isTapped) {
        final ringPaint = Paint()
          ..color = s.color.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, radius * 2.5, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => true;
}

// ── Page State ────────────────────────────────────────────────────────────────
class _StarMapPageState extends State<StarMapPage> with TickerProviderStateMixin {
  late AnimationController _twinkleCtrl;
  late AnimationController _bgShiftCtrl;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<_Star> _stars = List.from(_allStars);
  int? _tappedIdx;
  bool _loading = true;
  late List<Offset> _bgStars;
  int _totalMessages = 0;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _twinkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _bgShiftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    final rng = Random(99);
    _bgStars = List.generate(80, (_) => Offset(rng.nextDouble(), rng.nextDouble()));

    _loadMilestones();
  }

  @override
  void dispose() {
    _twinkleCtrl.dispose();
    _bgShiftCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMilestones() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    _totalMessages = prefs.getInt('total_message_count') ?? 0;

    // Load unlocked milestones from Firestore
    Set<String> unlocked = {};
    if (_uid != null) {
      try {
        final doc = await _db.collection('star_map').doc(_uid).get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          unlocked = Set<String>.from((data['unlocked'] as List? ?? []).cast<String>());
        }
      } catch (_) {}
    }

    // Auto-unlock based on total messages
    final auto = <String>{};
    if (_totalMessages >= 1) auto.add('first_chat');
    if (_totalMessages >= 10) auto.add('ten_messages');
    if (_totalMessages >= 50) auto.add('fifty_messages');
    if (_totalMessages >= 100) auto.add('hundred_messages');
    if (_totalMessages >= 500) auto.add('five_hundred');
    if (_totalMessages >= 1000) auto.add('thousand');

    // Also load from local prefs flags
    if (prefs.getBool('has_used_voice') == true) auto.add('first_voice');
    if (prefs.getBool('has_played_game') == true) auto.add('played_game');
    if (prefs.getBool('has_played_music') == true) auto.add('first_music');
    if (prefs.getBool('has_read_diary') == true) auto.add('diary_read');
    if (prefs.getBool('chat_past_midnight') == true) auto.add('night_chat');
    if ((prefs.getInt('checkin_streak') ?? 0) >= 5) auto.add('joined_streaks');

    final allUnlocked = {...unlocked, ...auto};

    // Save combined unlocked set back to Firestore
    if (_uid != null && auto.isNotEmpty) {
      _db.collection('star_map').doc(_uid).set(
        {'unlocked': allUnlocked.toList(), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      ).catchError((_) {});
    }

    if (mounted) {
      setState(() {
        _stars = _allStars.map((s) => s.copyWith(unlocked: allUnlocked.contains(s.id))).toList();
        _loading = false;
      });
      _twinkleCtrl.forward();
    }
  }

  void _onTapStar(Offset tapPos, Size canvasSize) {
    for (int i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final center = Offset(s.position.dx * canvasSize.width, s.position.dy * canvasSize.height);
      if ((tapPos - center).distance < s.size * 3) {
        HapticFeedback.lightImpact();
        setState(() => _tappedIdx = _tappedIdx == i ? null : i);
        return;
      }
    }
    setState(() => _tappedIdx = null);
  }

  int get _unlockedCount => _stars.where((s) => s.unlocked).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Deep space gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.1, -0.3),
                radius: 1.4,
                colors: [
                  Color(0xFF1A0E3A), // deep cosmic purple
                  Color(0xFF0A0820),
                  Color(0xFF030510), // near-black indigo
                ],
              ),
            ),
          ),

          // ── Nebula effects ───────────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgShiftCtrl,
            builder: (_, __) {
              final v = _bgShiftCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: 40 + v * 20,
                    right: -50 + v * 30,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFFFF4D8D).withOpacity(0.07),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100 - v * 20,
                    left: -60 + v * 15,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF3498DB).withOpacity(0.06),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Star canvas ──────────────────────────────────────────────────
          if (!_loading)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onTapDown: (d) => _onTapStar(d.localPosition, size),
                    child: AnimatedBuilder(
                      animation: _twinkleCtrl,
                      builder: (_, __) => CustomPaint(
                        size: size,
                        painter: _StarFieldPainter(
                          stars: _stars,
                          twinkle: _twinkleCtrl.value,
                          tappedIdx: _tappedIdx,
                          backgroundStars: _bgStars,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Loading ──────────────────────────────────────────────────────
          if (_loading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF4D8D)),
                  SizedBox(height: 16),
                  Text('Charting the stars, Darling~',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white60, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✨ Our Star Map',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFFF4D8D).withOpacity(0.5),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Each star is a moment we shared, Darling~',
                              style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Progress badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFF4D8D), Color(0xFF9B59B6)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4D8D).withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          '$_unlockedCount/${_stars.length} ⭐',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Star detail card (when tapped) ──────────────────────
                if (_tappedIdx != null && _tappedIdx! < _stars.length)
                  _buildStarCard(_stars[_tappedIdx!]),

                // ── Legend ──────────────────────────────────────────────
                if (_tappedIdx == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4D8D).withOpacity(0.07),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _legendItem(const Color(0xFFFF4D8D), 'Unlocked', true),
                          Container(width: 1, height: 28, color: Colors.white12),
                          _legendItem(Colors.white38, 'Locked', false),
                          Container(width: 1, height: 28, color: Colors.white12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$_totalMessages',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFFD700),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  )),
                              Text('Messages',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarCard(_Star star) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: GestureDetector(
        onTap: () => setState(() => _tappedIdx = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                star.color.withOpacity(star.unlocked ? 0.15 : 0.05),
                Colors.black.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: star.unlocked
                  ? star.color.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              if (star.unlocked)
                BoxShadow(
                  color: star.color.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            children: [
              // Emoji circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: star.color.withOpacity(star.unlocked ? 0.2 : 0.05),
                  border: Border.all(
                    color: star.unlocked
                        ? star.color.withOpacity(0.6)
                        : Colors.white12,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    star.unlocked ? star.emoji : '🔒',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          star.title,
                          style: GoogleFonts.outfit(
                            color: star.unlocked ? Colors.white : Colors.white38,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (star.unlocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: star.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('✓ Unlocked',
                                style: GoogleFonts.outfit(
                                  color: star.color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      star.unlocked
                          ? star.memory
                          : 'Keep talking to me to unlock this star, Darling~',
                      style: GoogleFonts.outfit(
                        color: star.unlocked ? Colors.white70 : Colors.white24,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, bool filled) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 1.5),
            boxShadow: filled
                ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
