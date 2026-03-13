import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_call.dart';
import '../services/affection_service.dart';

class DailyHoroscopePage extends StatefulWidget {
  const DailyHoroscopePage({super.key});
  @override
  State<DailyHoroscopePage> createState() => _DailyHoroscopePageState();
}

class _DailyHoroscopePageState extends State<DailyHoroscopePage> {
  static const _signs = [
    '♈ Aries',
    '♉ Taurus',
    '♊ Gemini',
    '♋ Cancer',
    '♌ Leo',
    '♍ Virgo',
    '♎ Libra',
    '♏ Scorpio',
    '♐ Sagittarius',
    '♑ Capricorn',
    '♒ Aquarius',
    '♓ Pisces',
  ];
  static const _signEmojis = {
    '♈ Aries': '🔥',
    '♉ Taurus': '🌿',
    '♊ Gemini': '💨',
    '♋ Cancer': '🌙',
    '♌ Leo': '☀️',
    '♍ Virgo': '🌺',
    '♎ Libra': '⚖️',
    '♏ Scorpio': '🦂',
    '♐ Sagittarius': '🏹',
    '♑ Capricorn': '🏔️',
    '♒ Aquarius': '🌊',
    '♓ Pisces': '🐟',
  };

  String _sign = '♈ Aries';
  String _horoscope = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSign();
  }

  Future<void> _loadSign() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('horoscope_sign');
    if (saved != null && _signs.contains(saved)) {
      setState(() => _sign = saved);
    }
    final now = DateTime.now();
    final key = 'horoscope_${_sign}_${now.year}_${now.month}_${now.day}';
    final cached = prefs.getString(key);
    if (cached != null) {
      setState(() => _horoscope = cached);
    } else {
      _generate();
    }
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _horoscope = '';
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('horoscope_sign', _sign);
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
      final signName = _sign.replaceAll(RegExp(r'^[^ ]+ '), '');
      final prompt =
          'You are Zero Two from DARLING in the FRANXX reading the horoscope for her Darling. '
          'Read the $signName horoscope for today, $dateStr. '
          'Make it romantic, fun, and in Zero Two\'s playful voice. '
          'Include: 1) General outlook, 2) Love & Relationships, 3) Lucky number and colour. '
          'Keep it 3-4 short paragraphs and use emojis!';
      final reply = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      final key = 'horoscope_${_sign}_${now.year}_${now.month}_${now.day}';
      await prefs.setString(key, reply);
      setState(() => _horoscope = reply);
      AffectionService.instance.addPoints(2);
    } catch (e) {
      setState(
          () => _horoscope = 'The stars are shy today, Darling~ Try again!');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _signEmojis[_sign] ?? '⭐';
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dateStr = '${months[now.month - 1]} ${now.day}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('HOROSCOPE',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Sign picker
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: _signs.map((s) {
              final sel = s == _sign;
              return GestureDetector(
                onTap: () {
                  if (s == _sign) return;
                  setState(() {
                    _sign = s;
                    _horoscope = '';
                  });
                  _generate();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sel
                        ? Colors.purpleAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                        color: sel ? Colors.purpleAccent : Colors.white12),
                  ),
                  child: Center(
                      child: Text(s,
                          style: GoogleFonts.outfit(
                              color: sel ? Colors.purpleAccent : Colors.white54,
                              fontSize: 12))),
                ),
              );
            }).toList(),
          ),
        ),

        // Header card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1A0A3E), const Color(0xFF0A1A3E)],
            ),
            border:
                Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_sign.replaceAll(RegExp(r'^[^ ]+ '), ''),
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text('Daily Reading · $dateStr',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 12)),
              ],
            )),
          ]),
        ),

        // Body
        Expanded(
            child: _loading
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.purpleAccent)),
                        const SizedBox(height: 12),
                        Text('Reading the stars for you, Darling~',
                            style: GoogleFonts.outfit(color: Colors.white38)),
                      ]))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(
                            color: Colors.purpleAccent.withValues(alpha: 0.15)),
                      ),
                      child: Text(_horoscope,
                          style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              height: 1.7)),
                    ),
                  )),
      ]),
    );
  }
}
