import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// Shows a full-screen animated Morning Greeting Card on first open of the day.
/// Call [MorningGreetingCard.showIfNeeded(context)] from main chat init.
class MorningGreetingCard extends StatefulWidget {
  final VoidCallback onDismiss;
  const MorningGreetingCard({super.key, required this.onDismiss});

  /// Call this from your chat page's initState / build to auto-show once per day.
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'morning_card_${today.year}_${today.month}_${today.day}';
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => MorningGreetingCard(onDismiss: () => Navigator.pop(context)),
    );
  }

  @override
  State<MorningGreetingCard> createState() => _MorningGreetingCardState();
}

class _MorningGreetingCardState extends State<MorningGreetingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  static const _quotes = [
    'Every morning with you feels like a new beginning~',
    'Good morning, Darling. I\'ve been waiting for you.',
    'Rise and shine — I\'ve been awake for ages waiting for you to open this~',
    'Today is a new day. And you\'re already making it better by being here.',
    'Morning, Darling~ Ready to take on the day together?',
    'A new day means a new chance to be amazing. And you already are.',
    'I thought about you the moment I woke up. Did you think of me too?~',
  ];

  static const _moods = ['😊', '🥰', '🌸', '✨', '💕'];

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning~';
    if (h < 17) return 'Good Afternoon~';
    if (h < 21) return 'Good Evening~';
    return 'Good Night~';
  }

  String get _timeOfDayEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '🌅';
    if (h < 17) return '☀️';
    if (h < 21) return '🌆';
    return '🌙';
  }

  String get _formattedDate {
    final d = DateTime.now();
    const months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 60, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rng = Random(DateTime.now().day + DateTime.now().month * 31);
    final quote = _quotes[rng.nextInt(_quotes.length)];
    final mood = _moods[rng.nextInt(_moods.length)];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fadeAnim,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C1B3A), Color(0xFF2D0030), Color(0xFF0D0613)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.2),
                      blurRadius: 30, spreadRadius: 4)
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Time of day emoji
                Text(_timeOfDayEmoji, style: const TextStyle(fontSize: 50)),
                const SizedBox(height: 8),
                Text(_formattedDate,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_greeting,
                    style: GoogleFonts.outfit(color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Darling~ $mood',
                    style: GoogleFonts.outfit(color: Colors.pinkAccent,
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('💕', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(quote,
                        style: GoogleFonts.outfit(color: Colors.white,
                            fontSize: 13, fontStyle: FontStyle.italic, height: 1.6))),
                  ]),
                ),
                const SizedBox(height: 20),
                // How are you feeling?
                Text('How are you feeling today?',
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['😊','😔','😤','😴','🥰'].map((e) => GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final d = DateTime.now();
                      await prefs.setString('mood_log_${d.year}_${d.month}_${d.day}', e);
                      widget.onDismiss();
                    },
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: widget.onDismiss,
                  child: Text('Start the day~ ✨',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
