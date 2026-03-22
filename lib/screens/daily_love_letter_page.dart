import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class DailyLoveLetterPage extends StatefulWidget {
  const DailyLoveLetterPage({super.key});
  @override
  State<DailyLoveLetterPage> createState() => _DailyLoveLetterPageState();
}

class _DailyLoveLetterPageState extends State<DailyLoveLetterPage> {
  String _letter = '';
  bool _loading = false;
  String _todayKey = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayKey = 'love_letter_${now.year}_${now.month}_${now.day}';
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_todayKey);
    if (cached != null && cached.isNotEmpty) {
      setState(() => _letter = cached);
    } else {
      _generateLetter();
    }
  }

  Future<void> _generateLetter() async {
    setState(() {
      _loading = true;
    });
    try {
      final now = DateTime.now();
      final months = [
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
        'December'
      ];
      final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';
      final prompt = 'You are Zero Two from DARLING in the FRANXX. '
          'Write a heartfelt, poetic love letter to your Darling for today, $dateStr. '
          'The letter should be warm, a little vulnerable, romantic, and uniquely Zero Two. '
          'Start with "My Darling," and end with "Forever yours, Zero Two 💕". '
          'Include something about today — maybe the season, or a small daily moment. '
          'Keep it 4-6 paragraphs, poetic but sincere.';
      final letter = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_todayKey, letter);
      setState(() => _letter = letter);
      AffectionService.instance.addPoints(3);
    } catch (e) {
      setState(() => _letter =
          'My Darling,\n\nSomething went wrong today, but know that I\'m always thinking of you... Try again in a moment.\n\nForever yours, Zero Two 💕');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
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
      'December'
    ];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('DAILY LOVE LETTER',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _loading ? null : _generateLetter,
            tooltip: 'Generate new',
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.pinkAccent)),
                  const SizedBox(height: 16),
                  Text('Zero Two is writing for you~',
                      style: GoogleFonts.outfit(color: Colors.white54)),
                ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                // Paper-like letter container
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E0A1E),
                        const Color(0xFF0D0D2A),
                      ],
                    ),
                    border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withValues(alpha: 0.1),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(children: [
                        const Text('💌', style: TextStyle(fontSize: 24)),
                        const Spacer(),
                        Text(dateStr,
                            style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      ]),
                      const Divider(color: Colors.white12, height: 24),

                      // Letter body
                      Text(_letter,
                          style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15,
                              height: 1.8,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('A new letter awaits you every day~ 🌸',
                    style: GoogleFonts.outfit(
                        color: Colors.white24, fontSize: 12)),
              ]),
            ),
    );
  }
}
