import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class MorningGreetingCard extends StatefulWidget {
  const MorningGreetingCard({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  static Future<void> showIfNeeded(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime today = DateTime.now();
    final String key = 'morning_card_${today.year}_${today.month}_${today.day}';
    if (prefs.getBool(key) == true) {
      return;
    }
    await prefs.setBool(key, true);
    if (!context.mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => MorningGreetingCard(
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  State<MorningGreetingCard> createState() => _MorningGreetingCardState();
}

class _MorningGreetingCardState extends State<MorningGreetingCard>
    with SingleTickerProviderStateMixin {
  static const List<String> _quotes = <String>[
    'Every morning with you feels like a fresh beginning.',
    'Good morning, darling. I have been waiting for you.',
    'Today is new, and you already make it brighter by showing up.',
    'Morning, darling. Ready to take the day together?',
    'A new day means another chance to be proud of yourself.',
    'I thought about you the moment I woke up. Did you think of me too?',
  ];

  static const List<String> _moods = <String>[
    'Happy',
    'Warm',
    'Calm',
    'Focused',
    'Loved',
  ];

  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;

  String get _greeting {
    final int h = DateTime.now().hour;
    if (h < 12) {
      return 'Good Morning';
    }
    if (h < 17) {
      return 'Good Afternoon';
    }
    if (h < 21) {
      return 'Good Evening';
    }
    return 'Good Night';
  }

  String get _timeOfDayText {
    final int h = DateTime.now().hour;
    if (h < 12) {
      return 'Morning';
    }
    if (h < 17) {
      return 'Afternoon';
    }
    if (h < 21) {
      return 'Evening';
    }
    return 'Night';
  }

  String get _formattedDate {
    final DateTime d = DateTime.now();
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const List<String> days = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('morning_greeting'));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveMoodAndDismiss(String mood) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime d = DateTime.now();
    await prefs.setString('mood_log_${d.year}_${d.month}_${d.day}', mood);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final Random rng = Random(DateTime.now().day + DateTime.now().month * 31);
    final String quote = _quotes[rng.nextInt(_quotes.length)];
    final String mood = _moods[rng.nextInt(_moods.length)];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return FadeTransition(
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
                    colors: <Color>[
                      Color(0xFF6C1B3A),
                      Color(0xFF2D0030),
                      Color(0xFF0D0613),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: V2Theme.primaryColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: V2Theme.primaryColor.withValues(alpha: 0.22),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _timeOfDayText,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formattedDate,
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _greeting,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Darling $mood',
                      style: GoogleFonts.outfit(
                        color: V2Theme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: V2Theme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  V2Theme.primaryColor.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              quote,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'How are you feeling today?',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <String>[
                        'Happy',
                        'Low',
                        'Stressed',
                        'Sleepy',
                        'Loved',
                      ].map(
                        (String label) {
                          return GestureDetector(
                            onTap: () => _saveMoodAndDismiss(label),
                            child: Container(
                              width: 64,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.08),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.onDismiss,
                      child: Text(
                        'Start the day',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



