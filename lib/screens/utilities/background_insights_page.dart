import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Background Insights v2 — AI processes past interactions and generates random insights.
/// "I realized something about you..."
class BackgroundInsightsPage extends StatefulWidget {
  const BackgroundInsightsPage({super.key});
  @override
  State<BackgroundInsightsPage> createState() => _BackgroundInsightsPageState();
}

class _BackgroundInsightsPageState extends State<BackgroundInsightsPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _insights = [];
  bool _generating = false;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _load();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('background_insights');
    if (d != null) setState(() => _insights = (jsonDecode(d) as List).cast<Map<String, dynamic>>());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_insights', jsonEncode(_insights));
  }

  void _generateInsight() async {
    HapticFeedback.mediumImpact();
    setState(() => _generating = true);
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final thoughtCount = (jsonDecode(prefs.getString('thought_capture') ?? '[]') as List).length;
    final brainCount = (jsonDecode(prefs.getString('second_brain_notes') ?? '[]') as List).length;
    final errorCount = (jsonDecode(prefs.getString('error_memory_entries') ?? '[]') as List).length;

    final rng = Random();
    final templates = [
      {'emoji': '🧠', 'title': 'Pattern Detected', 'insight': 'You tend to be most productive in the ${DateTime.now().hour < 12 ? 'morning' : 'evening'} hours. Consider scheduling important tasks during this window.', 'category': 'productivity'},
      {'emoji': '💡', 'title': 'Idea Connection', 'insight': 'You\'ve captured $thoughtCount thoughts so far. I noticed recurring themes around technology. Consider organizing them into a project plan.', 'category': 'creativity'},
      {'emoji': '📈', 'title': 'Growth Insight', 'insight': 'Your Second Brain has $brainCount entries. You\'re building a genuine knowledge base. The top 10% of users have 50+ entries.', 'category': 'growth'},
      {'emoji': '🐛', 'title': 'Debug Pattern', 'insight': 'You\'ve logged $errorCount errors. Common pattern: null reference issues. Consider adopting null-safety practices more aggressively.', 'category': 'technical'},
      {'emoji': '🔮', 'title': 'Behavioral Prediction', 'insight': 'Based on your usage patterns, you\'re likely a ${rng.nextBool() ? 'visual learner' : 'kinesthetic learner'}. I\'ll adapt my explanations accordingly.', 'category': 'personality'},
      {'emoji': '⚡', 'title': 'Efficiency Hack', 'insight': 'You revisit similar topics frequently. Creating templates or snippets for recurring patterns could save you ~2 hours weekly.', 'category': 'productivity'},
      {'emoji': '🎯', 'title': 'Focus Analysis', 'insight': 'Your engagement peaks around ${10 + rng.nextInt(4)}:00. This is your "deep work" zone — protect it from meetings and distractions.', 'category': 'productivity'},
      {'emoji': '💬', 'title': 'Communication Style', 'insight': 'You prefer concise, direct exchanges. I\'ll minimize filler words and get straight to the point in future responses.', 'category': 'personality'},
    ];

    final selected = templates[rng.nextInt(templates.length)];
    setState(() {
      _generating = false;
      _insights.insert(0, {
        ...selected,
        'time': DateTime.now().toIso8601String(),
        'read': false,
      });
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final catColors = {
      'productivity': Colors.greenAccent,
      'creativity': Colors.amberAccent,
      'growth': Colors.cyanAccent,
      'technical': Colors.redAccent,
      'personality': Colors.purpleAccent,
    };

    return FeaturePageV2(
      title: 'AI INSIGHTS',
      subtitle: '${_insights.length} insights generated',
      onBack: () => Navigator.pop(context),
      actions: [
        GestureDetector(
          onTap: _generating ? null : _generateInsight,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _generating ? Colors.white.withValues(alpha: 0.06) : Colors.cyanAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _generating ? Colors.white12 : Colors.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: _generating
                ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
                : const Icon(Icons.auto_awesome_rounded, color: Colors.cyanAccent, size: 20),
          ),
        ),
      ],
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: Column(children: [
          Expanded(
            child: _insights.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🧠', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text('Background AI Thinking', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Your AI processes past interactions\nand generates insights about YOU', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generateInsight,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text('Generate First Insight', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
                        foregroundColor: Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _insights.length,
                        itemBuilder: (_, i) => _buildInsightCard(i, _insights[i], catColors),
                      ),
          ),

          // Waifu Card
          AnimatedEntry(
            index: 10,
            child: WaifuCommentary(
              text: _insights.isEmpty
                  ? '"I\'m always thinking about you in the background, Darling~"'
                  : '"I notice so many things about you~ You\'re fascinating, Darling~"',
              themeColor: Colors.pinkAccent,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildInsightCard(int index, Map<String, dynamic> ins, Map<String, Color> catColors) {
    final c = catColors[ins['category']] ?? Colors.cyanAccent;
    final t = DateTime.tryParse(ins['time'] ?? '');
    final ago = t != null ? DateTime.now().difference(t) : null;
    final timeStr = ago != null
        ? ago.inMinutes < 60 ? '${ago.inMinutes}m ago'
            : ago.inHours < 24 ? '${ago.inHours}h ago'
            : '${ago.inDays}d ago'
        : '';

    return AnimatedEntry(
      index: index,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(ins['emoji'] ?? '🧠', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Text(ins['title'] ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
            Text(timeStr, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
          ]),
          const SizedBox(height: 10),
          Text(ins['insight'] ?? '', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, height: 1.5, fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text((ins['category'] ?? '').toString().toUpperCase(), style: GoogleFonts.outfit(color: c, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ]),
      ),
    );
  }
}


