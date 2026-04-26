import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/config/app_themes.dart';

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
      if (!mounted) return;
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
      if (!mounted) return;
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
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pinkAccent.withValues(alpha: 0.08),
                  Colors.redAccent.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.pinkAccent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(children: [
              if (_letter.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _copyLetter,
                    splashColor: Colors.pinkAccent.withValues(alpha: 0.1),
                    highlightColor: Colors.pinkAccent.withValues(alpha: 0.05),
                    child: Container(
                      width: 40, height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.pinkAccent.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          color: Colors.pinkAccent, size: 18),
                    ),
                  ),
                ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💌 Daily Love Letters',
                        style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${_archive.length} letters in your collection',
                        style: GoogleFonts.outfit(
                            color: context.appTokens.textSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _loading ? null : _generateLetter,
                  splashColor: Colors.pinkAccent.withValues(alpha: 0.1),
                  highlightColor: Colors.pinkAccent.withValues(alpha: 0.05),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _loading
                          ? Colors.pinkAccent.withValues(alpha: 0.1)
                          : context.appTokens.panelElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _loading
                            ? Colors.pinkAccent.withValues(alpha: 0.3)
                            : context.appTokens.outline,
                        width: 1,
                      ),
                    ),
                    child: _loading
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.pinkAccent,
                          ),
                        )
                      : Icon(Icons.refresh_rounded,
                          color: context.appTokens.textSoft, size: 18),
                  ),
                ),
              ),
            ]),
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
              const SizedBox(height: 16),

              // Romantic footer message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appTokens.panel.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.appTokens.outline,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text('A new letter awaits you every day~ 🌸',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            color: context.appTokens.textSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('+3 XP 💕',
                          style: GoogleFonts.outfit(
                              color: Colors.pinkAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),

              // ── Archive ──
              if (_archive.length > 1) ...[
                const SizedBox(height: 32),
                Text('LETTER ARCHIVE',
                    style: GoogleFonts.outfit(
                        color: context.appTokens.textSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(height: 16),
                ..._archive.skip(1).take(5).toList().asMap().entries.map((entry) {
                  final h = entry.value;
                  return AnimatedEntry(
                    index: 2 + entry.key,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.appTokens.panel.withValues(alpha: 0.8),
                            context.appTokens.panelElevated.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.appTokens.outline,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('💌', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_formatDate(h['date']?.toString() ?? ''),
                                style: GoogleFonts.outfit(
                                    color: Colors.pinkAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 6),
                          Text(h['letter']?.toString().replaceAll('\n', ' ').substring(0, (h['letter']?.toString().length ?? 0).clamp(0, 80)) ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                color: context.appTokens.textSoft,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.4)),
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
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withValues(alpha: 0.06),
            Colors.redAccent.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.pinkAccent.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.pinkAccent,
          ),
        ),
        const SizedBox(height: 20),
        Text('Zero Two is writing for you~',
            style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('💕', style: TextStyle(fontSize: 20)),
        ),
      ]),
    );
  }

  Widget _buildLetterCard(String dateStr) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withValues(alpha: 0.08),
            Colors.redAccent.withValues(alpha: 0.04),
            Colors.purpleAccent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.pinkAccent.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header with romantic design
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('💌', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('My Dearest Love',
                style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.pinkAccent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(dateStr,
                style: GoogleFonts.outfit(
                    color: Colors.pinkAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ]),

        const SizedBox(height: 20),

        // Decorative divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.pinkAccent.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Letter content with premium typography
        Text(_letter,
            style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                fontSize: 16,
                height: 1.8,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500)),

        const SizedBox(height: 16),

        // Romantic signature
        Align(
          alignment: Alignment.centerRight,
          child: Text('With all my love, 💕',
              style: GoogleFonts.outfit(
                  color: Colors.pinkAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic)),
        ),
      ]),
    );
  }
}




