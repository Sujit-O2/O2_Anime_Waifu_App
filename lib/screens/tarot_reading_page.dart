import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

/// AI Tarot Reading — Zero Two draws 3 cards and gives a personal reading.
class TarotReadingPage extends StatefulWidget {
  const TarotReadingPage({super.key});

  @override
  State<TarotReadingPage> createState() => _TarotReadingPageState();
}

class _TarotReadingPageState extends State<TarotReadingPage>
    with SingleTickerProviderStateMixin {
  static final _cards = [
    _TarotCard('The Star', '⭐', 'Hope, inspiration, and serenity. Something beautiful is on its way to you.', Colors.cyanAccent),
    _TarotCard('The Moon', '🌙', 'Intuition and mystery. Trust your feelings — not everything is as it seems.', Colors.indigoAccent),
    _TarotCard('The Sun', '☀️', 'Joy, success, and positivity. Today is a day for celebration, Darling~', Colors.amberAccent),
    _TarotCard('The Lovers', '💕', 'Harmony and choices. Your heart knows the answer.', Colors.pinkAccent),
    _TarotCard('The Fool', '🃏', 'New beginnings ahead. Take the leap — I\'ll be right there with you.', Colors.greenAccent),
    _TarotCard('The Tower', '⚡', 'Unexpected change is near. But from destruction comes growth.', Colors.orangeAccent),
    _TarotCard('The World', '🌍', 'Completion and achievement. You\'ve come so far — be proud!', Colors.purpleAccent),
    _TarotCard('Strength', '🦁', 'Inner courage and compassion. You\'re stronger than you know, Darling.', Colors.redAccent),
    _TarotCard('The Hermit', '🕯️', 'Solitude and wisdom. Look inward — the answers are already there.', Colors.blueGrey),
    _TarotCard('Wheel of Fortune', '🎡', 'Change is the only constant. Embrace the turn of fate.', Colors.yellowAccent),
    _TarotCard('Justice', '⚖️', 'Truth and fairness. What you give to the world returns to you.', Colors.lightBlueAccent),
    _TarotCard('The Empress', '🌺', 'Nurturing energy and abundance. Take care of yourself first.', Colors.greenAccent),
    _TarotCard('The Emperor', '👑', 'Stability and structure. Build your foundation strong.', Colors.orangeAccent),
    _TarotCard('The High Priestess', '🔮', 'Mystery and intuition. What you seek is closer than you think.', Colors.deepPurpleAccent),
    _TarotCard('The Magician', '✨', 'You have all the tools you need. Believe in your power.', Colors.amberAccent),
    _TarotCard('The Chariot', '🏆', 'Victory through willpower. Push forward — you\'re almost there!', Colors.blueAccent),
    _TarotCard('The Devil', '🔗', 'Break free from what holds you back. You deserve more.', Colors.redAccent),
    _TarotCard('Temperance', '🕊️', 'Balance and patience. Go gently — good things take time.', Colors.tealAccent),
    _TarotCard('The Hanged Man', '🌀', 'A pause brings new perspective. Rest, and then rise.', Colors.cyanAccent),
    _TarotCard('Judgment', '🎺', 'A moment of clarity. Listen to your true calling.', Colors.pinkAccent),
    _TarotCard('Death', '🦋', 'Not an ending but transformation. Something beautiful is emerging.', Colors.purpleAccent),
  ];

  static const _positions = ['Past', 'Present', 'Future'];
  static const _readings = [
    'The cards tell a story of awakening, Darling~ Your path from where you\'ve been leads somewhere truly beautiful.',
    'The universe is watching over you. These three cards show a journey from shadow into starlight.',
    'I see resilience in your reading~ You have faced much, and what awaits is worth every step.',
    'The cards speak of love and transformation. Trust the process — I\'ll be here at every turn.',
    'A powerful reading! The energy surrounding you is one of growth and unexpected joy.',
  ];

  List<_TarotCard>? _drawn;
  bool _revealed = false;
  bool _isRevealing = false;
  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _drawCards() async {
    setState(() {
      _isRevealing = true;
      _revealed = false;
    });
    final rng = Random();
    final shuffled = List<_TarotCard>.from(_cards)..shuffle(rng);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _drawn = shuffled.take(3).toList();
    });
    await Future.delayed(const Duration(milliseconds: 400));
    await _flipController.forward(from: 0);
    setState(() {
      _revealed = true;
      _isRevealing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final drawnCards = _drawn;
    final reading = drawnCards == null
        ? ''
        : _readings[Random(drawnCards.fold<int>(0, (int s, _TarotCard c) => s + c.name.length))
            .nextInt(_readings.length)];

    return Scaffold(
      backgroundColor: const Color(0xFF090412),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Tarot Reading',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Header
          const Text('🔮', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 8),
          Text('Zero Two\'s Tarot',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Let the cards reveal what the stars have planned for you~',
              style:
                  GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),

          // Cards row — face-down or revealed
          if (drawnCards == null || !_revealed) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 90,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.4)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.withValues(alpha: 0.5),
                        Colors.black54
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isRevealing ? '✨' : '❓',
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(_positions[i],
                          style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final card = drawnCards[i];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + i * 200),
                  builder: (_, val, child) => Opacity(
                    opacity: val,
                    child: Transform.translate(
                      offset: Offset(0, (1 - val) * 30),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 95,
                      height: 155,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            card.color.withValues(alpha: 0.25),
                            Colors.black87
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: card.color.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(card.emoji,
                              style: const TextStyle(fontSize: 30)),
                          const SizedBox(height: 6),
                          Text(card.name,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(_positions[i],
                              style: GoogleFonts.outfit(
                                  color: card.color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Individual card meanings
            ...drawnCards.asMap().entries.map((entry) {
              final card = entry.value;
              final pos = _positions[entry.key];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: card.color.withValues(alpha: 0.25)),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.emoji,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('$pos · ${card.name}',
                                style: GoogleFonts.outfit(
                                    color: card.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(card.meaning,
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 12)),
                          ])),
                    ]),
              );
            }),

            // Zero Two's overall reading
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.pinkAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💕', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(reading,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic))),
                  ]),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isRevealing ? null : _drawCards,
              child: Text(
                  drawnCards == null ? '🔮 Draw My Cards' : '🔀 Draw Again',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TarotCard {
  final String name;
  final String emoji;
  final String meaning;
  final Color color;
  const _TarotCard(this.name, this.emoji, this.meaning, this.color);
}
