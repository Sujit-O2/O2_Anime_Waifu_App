import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Date Night Planner v2 — AI-powered date planning with vibe/setting/budget
/// selectors, history persistence, copy, staggered animations, and FeaturePageV2.
class DateNightPlannerPage extends StatefulWidget {
  const DateNightPlannerPage({super.key});
  @override
  State<DateNightPlannerPage> createState() => _DateNightPlannerPageState();
}

class _DateNightPlannerPageState extends State<DateNightPlannerPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  static const _vibes = [
    {'label': 'Romantic', 'emoji': '💝', 'color': 0xFFFF4D8D},
    {'label': 'Adventurous', 'emoji': '🏔️', 'color': 0xFF4ECDC4},
    {'label': 'Cosy', 'emoji': '🕯️', 'color': 0xFFFFAB76},
    {'label': 'Playful', 'emoji': '🎮', 'color': 0xFF6C5CE7},
    {'label': 'Foodie', 'emoji': '🍜', 'color': 0xFFFF6B6B},
    {'label': 'Creative', 'emoji': '🎨', 'color': 0xFF45B7D1},
  ];

  static const _settings = [
    {'label': 'Home', 'emoji': '🏠'},
    {'label': 'Restaurant', 'emoji': '🍽️'},
    {'label': 'Outdoors', 'emoji': '🌿'},
    {'label': 'Virtual', 'emoji': '💻'},
    {'label': 'Cinema', 'emoji': '🎬'},
    {'label': 'Surprise me!', 'emoji': '🎲'},
  ];

  static const _budgets = ['Free', 'Under ₹500', '₹500-2000', '₹2000+'];

  int _selectedVibe = 0;
  int _selectedSetting = 0;
  int _selectedBudget = 0;
  String _plan = '';
  bool _loading = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadHistory();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('date_planner_history_v2');
    if (raw != null && mounted) {
      try { setState(() => _history = (jsonDecode(raw) as List).cast<Map<String, dynamic>>()); } catch (_) {}
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_planner_history_v2', jsonEncode(_history.take(10).toList()));
  }

  Future<void> _generatePlan() async {
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _plan = ''; });
    try {
      final vibe = _vibes[_selectedVibe];
      final setting = _settings[_selectedSetting];
      final budget = _budgets[_selectedBudget];
      final prompt = 'You are Zero Two from DARLING in the FRANXX. '
          'Plan a detailed, fun date night with the following preferences:\n'
          '- Vibe: ${vibe['label']} ${vibe['emoji']}\n'
          '- Setting: ${setting['label']} ${setting['emoji']}\n'
          '- Budget: $budget\n'
          'Create a step-by-step date plan with: '
          '1) What to prepare/set up, '
          '2) Activities (at least 3), '
          '3) Food/snacks suggestion, '
          '4) A romantic finale. '
          'Speak as Zero Two planning this WITH me, warm and excited. Use emojis!';
      final reply = await ApiService().sendConversation([{'role': 'user', 'content': prompt}]);
      if (!mounted) return;
      setState(() => _plan = reply);
      AffectionService.instance.addPoints(5);
      _history.insert(0, {
        'vibe': vibe['label'], 'setting': setting['label'], 'budget': budget,
        'preview': reply.length > 120 ? '${reply.substring(0, 120)}...' : reply,
        'time': DateTime.now().toIso8601String(),
      });
      _saveHistory();
    } catch (_) {
      if (!mounted) return;
      setState(() => _plan = 'Something went wrong~ Let me think of something else!');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyPlan() {
    if (_plan.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _plan));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Date plan copied~ 💌', style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: V2Theme.primaryColor.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'DATE NIGHT PLANNER',
      subtitle: '${_history.length} dates planned • +5 XP',
      onBack: () => Navigator.pop(context),
      actions: [
        if (_plan.isNotEmpty)
          GestureDetector(
            onTap: _copyPlan,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: V2Theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: V2Theme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.copy, color: V2Theme.primaryColor, size: 16),
            ),
          ),
      ],
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Intro ──
            AnimatedEntry(
              index: 1,
              child: GlassCard(
                margin: EdgeInsets.zero,
                glow: true,
                child: Row(children: [
                  const Text('💞', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Tell me what kind of date you want, Darling~ I\'ll plan the perfect night for us!', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12))),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // ── Vibe ──
            Text('VIBE', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: _vibes.asMap().entries.map((e) {
              final sel = e.key == _selectedVibe;
              final color = Color(e.value['color'] as int);
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedVibe = e.key); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sel ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: sel ? color.withValues(alpha: 0.6) : Colors.white12),
                  ),
                  child: Text('${e.value['emoji']} ${e.value['label']}',
                    style: GoogleFonts.outfit(color: sel ? color : Colors.white54, fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),

            // ── Setting ──
            Text('SETTING', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: _settings.asMap().entries.map((e) {
              final sel = e.key == _selectedSetting;
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedSetting = e.key); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sel ? Colors.deepPurpleAccent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: sel ? Colors.deepPurpleAccent.withValues(alpha: 0.6) : Colors.white12),
                  ),
                  child: Text('${e.value['emoji']} ${e.value['label']}',
                    style: GoogleFonts.outfit(color: sel ? Colors.deepPurpleAccent : Colors.white54, fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),

            // ── Budget ──
            Text('BUDGET', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: _budgets.asMap().entries.map((e) {
              final sel = e.key == _selectedBudget;
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedBudget = e.key); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sel ? Colors.greenAccent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: sel ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.white12),
                  ),
                  child: Text(e.value, style: GoogleFonts.outfit(color: sel ? Colors.greenAccent : Colors.white54, fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
                ),
              );
            }).toList()),
            const SizedBox(height: 20),

            // ── Generate ──
            GestureDetector(
              onTap: _loading ? null : _generatePlan,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFFFF4D8D), Color(0xFFB44FD6)]),
                  boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.3), blurRadius: 16)],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(_loading ? 'Zero Two is planning~' : 'Plan Our Date Night! 💕',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Result ──
            if (_plan.isNotEmpty) ...[
              AnimatedEntry(
                index: 2,
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('💌', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('Our Date Plan~', style: GoogleFonts.outfit(color: V2Theme.primaryColor, fontSize: 13, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('+5 XP 💕', style: GoogleFonts.outfit(color: V2Theme.primaryColor.withValues(alpha: 0.4), fontSize: 10)),
                    ]),
                    const SizedBox(height: 12),
                    Text(_plan, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.7)),
                  ]),
                ),
              ),
            ],

            // ── History ──
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('PAST PLANS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              ..._history.take(3).toList().asMap().entries.map((entry) {
                final h = entry.value;
                return AnimatedEntry(
                  index: 3 + entry.key,
                  child: GlassCard(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const Text('💕', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${h['vibe']} • ${h['setting']}', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Budget: ${h['budget']}', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
                      ])),
                    ]),
                  ),
                );
              }),
            ],

            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
}




