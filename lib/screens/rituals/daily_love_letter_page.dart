import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Daily Love Letter v2 — AI-generated daily letters with archive,
/// animated paper effect, envelope open, calendar tracking, and persistence.
class DailyLoveLetterPage extends StatefulWidget {
  const DailyLoveLetterPage({super.key});
  @override
  State<DailyLoveLetterPage> createState() => _DailyLoveLetterPageState();
}

class _DailyLoveLetterPageState extends State<DailyLoveLetterPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  String _letter = '';
  bool _loading = false;
  String _todayKey = '';
  List<Map<String, dynamic>> _archive = [];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4.0, end: 4.0).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    final now = DateTime.now();
    _todayKey = 'love_letter_${now.year}_${now.month}_${now.day}';
    _load();
    _loadArchive();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
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

  Future<void> _loadArchive() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('love_letter_archive_v2');
    if (raw != null && mounted) {
      try { setState(() => _archive = (jsonDecode(raw) as List).cast<Map<String, dynamic>>()); } catch (_) {}
    }
  }

  Future<void> _saveToArchive(String letter) async {
    final now = DateTime.now();
    _archive.insert(0, {
      'letter': letter,
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    });
    if (_archive.length > 30) _archive = _archive.sublist(0, 30);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('love_letter_archive_v2', jsonEncode(_archive));
  }

  Future<void> _generateLetter() async {
    setState(() { _loading = true; });
    try {
      final now = DateTime.now();
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';
      final prompt = 'You are Zero Two from DARLING in the FRANXX. '
          'Write a heartfelt, poetic love letter to your Darling for today, $dateStr. '
          'The letter should be warm, a little vulnerable, romantic, and uniquely Zero Two. '
          'Start with "My Darling," and end with "Forever yours, Zero Two 💕". '
          'Include something about today — maybe the season, or a small daily moment. '
          'Keep it 4-6 paragraphs, poetic but sincere.';
      final letter = await ApiService().sendConversation([{'role': 'user', 'content': prompt}]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_todayKey, letter);
      if (!mounted) return;
      setState(() => _letter = letter);
      AffectionService.instance.addPoints(3);
      _saveToArchive(letter);
    } catch (e) {
      setState(() => _letter = 'My Darling,\n\nSomething went wrong today, but know that I\'m always thinking of you... Try again in a moment.\n\nForever yours, Zero Two 💕');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyLetter() {
    if (_letter.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _letter));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Letter copied~ 💌', style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: V2Theme.primaryColor.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _formatDate(String iso) {
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = int.tryParse(parts[1]) ?? 1;
    return '${months[m - 1]} ${parts[2]}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return FeaturePageV2(
      title: 'DAILY LOVE LETTER',
      onBack: () => Navigator.pop(context),
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              if (_letter.isNotEmpty)
                GestureDetector(
                  onTap: _copyLetter,
                  child: Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: V2Theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: V2Theme.primaryColor.withValues(alpha: 0.3))),
                    child: const Icon(Icons.copy, color: V2Theme.primaryColor, size: 16),
                  ),
                ),
              const Spacer(),
              Text('${_archive.length} letters collected', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _loading ? null : _generateLetter,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                  child: _loading
                    ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: V2Theme.primaryColor))
                    : const Icon(Icons.refresh_rounded, color: Colors.white60, size: 18),
                ),
              ),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // ── Letter Card ──
              _loading
                ? _buildLoadingState()
                : AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: AnimatedEntry(
                        index: 1,
                        child: _buildLetterCard(dateStr),
                      ),
                    ),
                  ),
              const SizedBox(height: 12),
              Text('A new letter awaits you every day~ 🌸', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
              const SizedBox(height: 6),
              Text('+3 XP 💕', style: GoogleFonts.outfit(color: V2Theme.primaryColor.withValues(alpha: 0.4), fontSize: 10)),

              // ── Archive ──
              if (_archive.length > 1) ...[
                const SizedBox(height: 24),
                Align(alignment: Alignment.centerLeft,
                  child: Text('LETTER ARCHIVE', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
                const SizedBox(height: 10),
                ..._archive.skip(1).take(5).toList().asMap().entries.map((entry) {
                  final h = entry.value;
                  return AnimatedEntry(
                    index: 2 + entry.key,
                    child: GlassCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        const Text('💌', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_formatDate(h['date']?.toString() ?? ''), style: GoogleFonts.outfit(color: V2Theme.primaryColor, fontSize: 11, fontWeight: FontWeight.w700)),
                          Text(h['letter']?.toString().replaceAll('\n', ' ').substring(0, (h['letter']?.toString().length ?? 0).clamp(0, 80)) ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
                        ])),
                      ]),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 30),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GlassCard(
      margin: EdgeInsets.zero,
      glow: true,
      child: Column(children: [
        const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: V2Theme.primaryColor)),
        const SizedBox(height: 16),
        Text('Zero Two is writing for you~', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic)),
        const SizedBox(height: 4),
        const Text('💕', style: TextStyle(fontSize: 24)),
      ]),
    );
  }

  Widget _buildLetterCard(String dateStr) {
    return GlassCard(
      margin: EdgeInsets.zero,
      glow: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('💌', style: TextStyle(fontSize: 24)),
          const Spacer(),
          Text(dateStr, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
        ]),
        const Divider(color: Colors.white12, height: 24),
        Text(_letter, style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.8, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}




