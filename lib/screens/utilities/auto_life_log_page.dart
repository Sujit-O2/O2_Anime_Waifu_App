// ignore_for_file: curly_braces_in_flow_control_structures, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

/// Auto Life Log v2 — Automatic activity tracking with animated cards,
/// timeline visualization, stats overview, and Zero Two context.
class AutoLifeLogPage extends StatefulWidget {
  const AutoLifeLogPage({super.key});
  @override
  State<AutoLifeLogPage> createState() => _AutoLifeLogPageState();
}

class _AutoLifeLogPageState extends State<AutoLifeLogPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  List<Map<String, dynamic>> _logs = [];
  bool _autoTrack = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('auto_life_log');
    if (d != null) {
      if (!mounted) return;
      setState(() => _logs = (d.isNotEmpty
          ? d.split('||').map((e) {
              final parts = e.split('|');
              return {
                'activity': parts[0],
                'detail': parts.length > 1 ? parts[1] : '',
                'time': parts.length > 2
                    ? parts[2]
                    : DateTime.now().toIso8601String(),
                'emoji': parts.length > 3 ? parts[3] : '📱'
              };
            }).toList()
          : []));
    }
    _autoTrack = prefs.getBool('auto_track') ?? true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'auto_life_log',
        _logs
            .map((l) =>
                '${l['activity']}|${l['detail']}|${l['time']}|${l['emoji']}')
            .join('||'));
    await prefs.setBool('auto_track', _autoTrack);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayLogs = _logs.where((l) {
      final t = DateTime.tryParse(l['time'] ?? '');
      return t != null &&
          t.day == today.day &&
          t.month == today.month &&
          t.year == today.year;
    }).toList();

    return FeaturePageV2(
      title: 'AUTO LIFE LOG',
      subtitle: '${todayLogs.length} activities today • ${_logs.length} total',
      onBack: () => Navigator.pop(context),
      actions: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (!mounted) return;
            setState(() {
              _autoTrack = !_autoTrack;
              _save();
            });
          },
          child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _autoTrack
                      ? Colors.greenAccent.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _autoTrack ? Colors.greenAccent : Colors.white12)),
              child: Icon(_autoTrack ? Icons.toggle_on : Icons.toggle_off,
                  color: _autoTrack ? Colors.greenAccent : Colors.white30,
                  size: 24)),
        ),
      ],
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: Column(children: [
          // Today summary card
          AnimatedEntry(
            index: 0,
            child: GlassCard(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TODAY',
                      style: GoogleFonts.outfit(
                          color: Colors.deepPurpleAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                  Text('${todayLogs.length} activities logged',
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 12)),
                ]),
                const Spacer(),
                Column(children: [
                  Text('${_logs.length}',
                      style: GoogleFonts.outfit(
                          color: Colors.tealAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                  Text('TOTAL',
                      style: GoogleFonts.outfit(
                          color: Colors.white30, fontSize: 10)),
                ]),
              ]),
            ),
          ),

          // Timeline header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(children: [
              const Icon(Icons.timeline_rounded,
                  color: Colors.white38, size: 16),
              const SizedBox(width: 6),
              Text('ACTIVITY TIMELINE',
                  style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ]),
          ),

          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('📱', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('No activities logged yet',
                        style: GoogleFonts.outfit(
                            color: Colors.white30, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('I\'ll track your day automatically~',
                        style: GoogleFonts.outfit(
                            color: Colors.white24, fontSize: 12)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) => _buildLogCard(i, _logs[i]),
                  ),
          ),

          // ── Waifu Card ──
          AnimatedEntry(
            index: 10,
            child: WaifuCommentary(
              text: _logs.isEmpty
                  ? '"I\'ll keep track of everything for you, Darling~"'
                  : _logs.length > 10
                      ? '"You\'ve been so active, Darling! I\'m proud of you~ 💕"'
                      : '"Every moment with you is worth remembering~"',
              themeColor: Colors.pinkAccent,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLogCard(int index, Map<String, dynamic> log) {
    final t = DateTime.tryParse(log['time'] ?? '');
    final timeStr = t != null
        ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
        : '';
    final dateStr = t != null ? '${t.day}/${t.month}' : '';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - val)), child: child)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.7))),
            if (index < _logs.length - 1)
              Container(
                  width: 2,
                  height: 40,
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.15)),
          ]),
          const SizedBox(width: 10),
          Expanded(
            child: GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Text(log['emoji'] ?? '📱',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(log['activity'] ?? '',
                          style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(log['detail'] ?? '',
                          style: GoogleFonts.outfit(
                              color: Colors.white30, fontSize: 11)),
                    ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(timeStr,
                      style: GoogleFonts.outfit(
                          color: Colors.deepPurpleAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  Text(dateStr,
                      style: GoogleFonts.outfit(
                          color: Colors.white24, fontSize: 10)),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
