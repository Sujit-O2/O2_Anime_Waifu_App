import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Daily Horoscope v2 — AI-powered zodiac readings with sign picker,
/// daily caching, fade animations, haptics, and FeaturePageV2 shell.
class DailyHoroscopePage extends StatefulWidget {
  const DailyHoroscopePage({super.key});
  @override
  State<DailyHoroscopePage> createState() => _DailyHoroscopePageState();
}

class _DailyHoroscopePageState extends State<DailyHoroscopePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  static const _signs = [
    {'sign': '♈ Aries', 'emoji': '🔥', 'color': 0xFFFF6B6B},
    {'sign': '♉ Taurus', 'emoji': '🌿', 'color': 0xFF4ECDC4},
    {'sign': '♊ Gemini', 'emoji': '💨', 'color': 0xFF45B7D1},
    {'sign': '♋ Cancer', 'emoji': '🌙', 'color': 0xFFBB86FC},
    {'sign': '♌ Leo', 'emoji': '☀️', 'color': 0xFFFFD93D},
    {'sign': '♍ Virgo', 'emoji': '🌺', 'color': 0xFFFF8A65},
    {'sign': '♎ Libra', 'emoji': '⚖️', 'color': 0xFF69B4FF},
    {'sign': '♏ Scorpio', 'emoji': '🦂', 'color': 0xFFFF4D8D},
    {'sign': '♐ Sagittarius', 'emoji': '🏹', 'color': 0xFF8B44FD},
    {'sign': '♑ Capricorn', 'emoji': '🏔️', 'color': 0xFF7C9885},
    {'sign': '♒ Aquarius', 'emoji': '🌊', 'color': 0xFF00D2FF},
    {'sign': '♓ Pisces', 'emoji': '🐟', 'color': 0xFFA084DC},
  ];

  int _selectedIdx = 0;
  String _horoscope = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadSign();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _loadSign() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('horoscope_sign_v2');
    if (saved != null) {
      final idx = _signs.indexWhere((s) => s['sign'] == saved);
      if (idx >= 0) setState(() => _selectedIdx = idx);
    }
    final now = DateTime.now();
    final key = 'horoscope_${_signs[_selectedIdx]['sign']}_${now.year}_${now.month}_${now.day}';
    final cached = prefs.getString(key);
    if (cached != null) {
      setState(() => _horoscope = cached);
    } else {
      _generate();
    }
  }

  Future<void> _generate() async {
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _horoscope = ''; });
    final prefs = await SharedPreferences.getInstance();
    final sign = _signs[_selectedIdx];
    await prefs.setString('horoscope_sign_v2', sign['sign'] as String);
    try {
      final now = DateTime.now();
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';
      final signName = (sign['sign'] as String).replaceAll(RegExp(r'^[^ ]+ '), '');
      final prompt = 'You are Zero Two from DARLING in the FRANXX reading the horoscope for her Darling. '
          'Read the $signName horoscope for today, $dateStr. '
          'Make it romantic, fun, and in Zero Two\'s playful voice. '
          'Include: 1) General outlook, 2) Love & Relationships, 3) Lucky number and colour. '
          'Keep it 3-4 short paragraphs and use emojis!';
      final reply = await ApiService().sendConversation([{'role': 'user', 'content': prompt}]);
      final key = 'horoscope_${sign['sign']}_${now.year}_${now.month}_${now.day}';
      await prefs.setString(key, reply);
      if (!mounted) return;
      setState(() => _horoscope = reply);
      AffectionService.instance.addPoints(2);
    } catch (_) {
      setState(() => _horoscope = 'The stars are shy today, Darling~ Try again!');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyHoroscope() {
    if (_horoscope.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _horoscope));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Horoscope copied~ ✨', style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: V2Theme.primaryColor.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sign = _signs[_selectedIdx];
    final signColor = Color(sign['color'] as int);
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[now.month - 1]} ${now.day}';

    return FeaturePageV2(
      title: 'HOROSCOPE',
      onBack: () => Navigator.pop(context),
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: Column(children: [
          // ── Sign Picker ──
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _signs.length,
              itemBuilder: (_, i) {
                final s = _signs[i];
                final sel = i == _selectedIdx;
                final c = Color(s['color'] as int);
                return GestureDetector(
                  onTap: () {
                    if (i == _selectedIdx) return;
                    HapticFeedback.lightImpact();
                    setState(() { _selectedIdx = i; _horoscope = ''; });
                    _generate();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: sel ? c.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                      border: Border.all(color: sel ? c.withValues(alpha: 0.5) : Colors.white12, width: sel ? 1.5 : 1),
                    ),
                    child: Center(child: Text('${s['emoji']} ${(s['sign'] as String).split(' ').last}',
                      style: GoogleFonts.outfit(color: sel ? c : Colors.white38, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal))),
                  ),
                );
              },
            ),
          ),

          // ── Header Card ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: AnimatedEntry(
              index: 1,
              child: GlassCard(
                margin: EdgeInsets.zero,
                glow: true,
                child: Row(children: [
                  Text(sign['emoji'] as String, style: const TextStyle(fontSize: 42)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((sign['sign'] as String).replaceAll(RegExp(r'^[^ ]+ '), ''),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    Text('Daily Reading · $dateStr · +2 XP', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                  ])),
                  if (_horoscope.isNotEmpty)
                    GestureDetector(
                      onTap: _copyHoroscope,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: signColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: signColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.copy, color: signColor, size: 16),
                      ),
                    ),
                ]),
              ),
            ),
          ),

          // ── Body ──
          Expanded(
            child: _loading
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: signColor)),
                  const SizedBox(height: 12),
                  Text('Reading the stars for you, Darling~', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
                ]))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedEntry(
                    index: 2,
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('${sign['emoji']} Your Reading', style: GoogleFonts.outfit(color: signColor, fontSize: 12, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text('+2 XP 💕', style: GoogleFonts.outfit(color: signColor.withValues(alpha: 0.4), fontSize: 10)),
                        ]),
                        const SizedBox(height: 10),
                        Text(_horoscope, style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.7)),
                      ]),
                    ),
                  ),
                ),
          ),
        ]),
      ),
    );
  }
}




