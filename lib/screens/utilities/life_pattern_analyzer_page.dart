import 'dart:async' show unawaited;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class LifePatternAnalyzerPage extends StatefulWidget {
  const LifePatternAnalyzerPage({super.key});
  @override
  State<LifePatternAnalyzerPage> createState() => _LifePatternAnalyzerPageState();
}

class _LifePatternAnalyzerPageState extends State<LifePatternAnalyzerPage> {
  static const _accent = Color(0xFF7C4DFF);
  static const _bg = Color(0xFF08060F);

  bool _analyzed = false;
  bool _analyzing = false;
  final Random _rng = Random();

  // Simulated pattern data
  late Map<String, dynamic> _patterns;

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('life_pattern'));
    _generatePatterns();
  }

  void _generatePatterns() {
    _patterns = {
      'peak_productivity': '10:00 PM – 12:00 AM',
      'worst_focus': '2:00 PM – 4:00 PM',
      'avg_sleep': '5.8 hours',
      'sleep_debt': '8.4 hours/week',
      'screen_time': '6h 42min/day',
      'scroll_waste': '2h 10min/day',
      'mood_peak': 'Tuesday & Wednesday',
      'mood_low': 'Sunday evening',
      'most_used_app': 'YouTube (1h 45min)',
      'productive_streak': '3 days max',
      'insights': [
        '🌙 You\'re a night owl — peak focus at 10PM',
        '📱 You waste 2h 10min daily on mindless scrolling',
        '😴 You\'re sleep-deprived by 8.4h every week',
        '📈 Tuesday is your most productive day',
        '⚠️ Post-lunch slump hits you hard (2-4PM)',
        '🎯 Your longest focus streak is only 3 days',
      ],
      'recommendations': [
        '🌙 Schedule deep work for 10PM–12AM',
        '📵 Use app timer: 30min max on YouTube',
        '😴 Sleep by 1AM to get 7h before 8AM',
        '🗓️ Plan important tasks for Tuesday',
        '☕ Take a walk at 2PM instead of scrolling',
        '🔥 Build a 7-day focus streak this week',
      ],
      'hourly': List.generate(24, (h) {
        if (h >= 22 || h <= 1) return 0.85 + _rng.nextDouble() * 0.15;
        if (h >= 10 && h <= 12) return 0.65 + _rng.nextDouble() * 0.2;
        if (h >= 14 && h <= 16) return 0.2 + _rng.nextDouble() * 0.2;
        if (h >= 2 && h <= 7) return 0.1 + _rng.nextDouble() * 0.1;
        return 0.4 + _rng.nextDouble() * 0.3;
      }),
    };
  }

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() { _analyzing = false; _analyzed = true; });
    final p = await SharedPreferences.getInstance();
    await p.setBool('lpa_analyzed', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('🗺️ Life Patterns', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (!_analyzed && !_analyzing) _scanCard(),
          if (_analyzing) _loadingCard(),
          if (_analyzed) ...[
            _summaryCard(),
            const SizedBox(height: 16),
            _productivityChart(),
            const SizedBox(height: 16),
            _statsGrid(),
            const SizedBox(height: 16),
            _insightsCard(),
            const SizedBox(height: 16),
            _recommendationsCard(),
          ],
        ]),
      ),
    );
  }

  Widget _scanCard() => _card(
    child: Column(children: [
      const Icon(Icons.analytics, color: _accent, size: 60),
      const SizedBox(height: 16),
      Text('Analyze Your Life Patterns', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('AI will analyze your sleep, usage, mood, and productivity patterns to reveal hidden insights about your life.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _analyze,
          icon: const Icon(Icons.search),
          label: Text('🔍 Analyze My Patterns', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]),
  );

  Widget _loadingCard() => _card(
    child: Column(children: [
      const CircularProgressIndicator(color: _accent),
      const SizedBox(height: 16),
      Text('Analyzing patterns...', style: GoogleFonts.orbitron(color: _accent, fontSize: 13)),
      const SizedBox(height: 8),
      const Text('Scanning 30 days of usage, sleep, and mood data', style: TextStyle(color: Colors.white38, fontSize: 12)),
    ]),
  );

  Widget _summaryCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label('PATTERN ANALYSIS'),
        TextButton(onPressed: () { setState(() { _analyzed = false; _generatePatterns(); }); _analyze(); },
            child: const Text('Refresh', style: TextStyle(color: _accent, fontSize: 12))),
      ]),
      const SizedBox(height: 4),
      const Text('Based on last 30 days of activity', style: TextStyle(color: Colors.white38, fontSize: 11)),
    ]),
  );

  Widget _productivityChart() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('PRODUCTIVITY BY HOUR'),
      const SizedBox(height: 12),
      SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(24, (h) {
            final val = (_patterns['hourly'] as List)[h] as double;
            final color = val > 0.7 ? _accent : val > 0.4 ? Colors.orange : Colors.red.withAlpha(150);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Tooltip(
                  message: '$h:00 — ${(val * 100).toInt()}%',
                  child: Container(
                    height: 80 * val,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 6),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('12AM', style: TextStyle(color: Colors.white24, fontSize: 9)),
        Text('6AM', style: TextStyle(color: Colors.white24, fontSize: 9)),
        Text('12PM', style: TextStyle(color: Colors.white24, fontSize: 9)),
        Text('6PM', style: TextStyle(color: Colors.white24, fontSize: 9)),
        Text('12AM', style: TextStyle(color: Colors.white24, fontSize: 9)),
      ]),
      const SizedBox(height: 8),
      Text('Peak: ${_patterns['peak_productivity']}', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _statsGrid() => GridView.count(
    crossAxisCount: 2, shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
    children: [
      _statTile('Avg Sleep', _patterns['avg_sleep'] as String, Icons.bedtime, Colors.blue),
      _statTile('Screen Time', _patterns['screen_time'] as String, Icons.phone_android, Colors.orange),
      _statTile('Scroll Waste', _patterns['scroll_waste'] as String, Icons.swipe, Colors.red),
      _statTile('Best Day', _patterns['mood_peak'] as String, Icons.star, Colors.yellow),
    ],
  );

  Widget _statTile(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0E0A18), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withAlpha(60)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ])),
    ]),
  );

  Widget _insightsCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('KEY INSIGHTS'),
      const SizedBox(height: 10),
      ...(_patterns['insights'] as List<String>).map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
      )),
    ]),
  );

  Widget _recommendationsCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('RECOMMENDATIONS'),
      const SizedBox(height: 10),
      ...(_patterns['recommendations'] as List<String>).map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Icon(Icons.arrow_right, color: _accent, size: 16),
          const SizedBox(width: 4),
          Expanded(child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ]),
      )),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0E0A18), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
