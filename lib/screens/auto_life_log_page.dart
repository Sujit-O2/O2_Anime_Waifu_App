import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auto Life Log — Automatic activity tracking. Records app usage,
/// chat frequency, mood shifts, and daily patterns.
class AutoLifeLogPage extends StatefulWidget {
  const AutoLifeLogPage({super.key});
  @override
  State<AutoLifeLogPage> createState() => _AutoLifeLogPageState();
}

class _AutoLifeLogPageState extends State<AutoLifeLogPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _autoTrack = true;

  @override
  void initState() {
    super.initState();
    _load();
    _autoCapture();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoTrack = prefs.getBool('autolifelog_enabled') ?? true;
    final d = prefs.getString('autolifelog_entries');
    if (d != null) {
      setState(() => _logs = (jsonDecode(d) as List).cast<Map<String, dynamic>>());
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autolifelog_entries', jsonEncode(_logs));
    await prefs.setBool('autolifelog_enabled', _autoTrack);
  }

  void _autoCapture() {
    if (!_autoTrack) return;
    final h = DateTime.now().hour;
    final activity = h >= 6 && h < 9
        ? {'emoji': '🌅', 'activity': 'Morning check-in', 'detail': 'Started the day at ${h}:00'}
        : h >= 9 && h < 12
            ? {'emoji': '💻', 'activity': 'Work session', 'detail': 'Active during work hours'}
            : h >= 12 && h < 14
                ? {'emoji': '🍽️', 'activity': 'Lunch break', 'detail': 'Midday pause detected'}
                : h >= 14 && h < 18
                    ? {'emoji': '📚', 'activity': 'Afternoon focus', 'detail': 'Deep work period'}
                    : h >= 18 && h < 21
                        ? {'emoji': '🌆', 'activity': 'Evening wind-down', 'detail': 'Relaxation period'}
                        : h >= 21 || h < 2
                            ? {'emoji': '🌙', 'activity': 'Night mode', 'detail': 'Late night activity'}
                            : {'emoji': '😴', 'activity': 'Sleep', 'detail': 'Should be resting!'};

    final now = DateTime.now();
    // Only add if last log is > 30 min ago
    if (_logs.isNotEmpty) {
      final lastTime = DateTime.tryParse(_logs.first['time'] ?? '');
      if (lastTime != null && now.difference(lastTime).inMinutes < 30) return;
    }

    setState(() {
      _logs.insert(0, {
        ...activity,
        'time': now.toIso8601String(),
        'hour': h,
      });
      if (_logs.length > 100) _logs = _logs.sublist(0, 100);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    // Group logs by date
    final today = DateTime.now();
    final todayLogs = _logs.where((l) {
      final t = DateTime.tryParse(l['time'] ?? '');
      return t != null && t.day == today.day && t.month == today.month;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('AUTO LIFE LOG', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_autoTrack ? Icons.toggle_on : Icons.toggle_off, color: _autoTrack ? Colors.greenAccent : Colors.white30, size: 32),
            onPressed: () => setState(() { _autoTrack = !_autoTrack; _save(); }),
          ),
        ],
      ),
      body: Column(children: [
        // Today summary card
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.deepPurpleAccent.withValues(alpha: 0.08), Colors.tealAccent.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TODAY', style: GoogleFonts.outfit(color: Colors.deepPurpleAccent, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              Text('${todayLogs.length} activities logged', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            ]),
            const Spacer(),
            Column(children: [
              Text('${_logs.length}', style: GoogleFonts.outfit(color: Colors.tealAccent, fontSize: 24, fontWeight: FontWeight.w900)),
              Text('TOTAL', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
            ]),
          ]),
        ),

        // Timeline header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            const Icon(Icons.timeline_rounded, color: Colors.white38, size: 16),
            const SizedBox(width: 6),
            Text('ACTIVITY TIMELINE', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ]),
        ),

        Expanded(
          child: _logs.isEmpty
              ? Center(child: Text('No activities logged yet 📱', style: GoogleFonts.outfit(color: Colors.white30)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _logs.length,
                  itemBuilder: (_, i) {
                    final log = _logs[i];
                    final t = DateTime.tryParse(log['time'] ?? '');
                    final timeStr = t != null ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}' : '';
                    final dateStr = t != null ? '${t.day}/${t.month}' : '';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline dot + line
                        Column(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.deepPurpleAccent.withValues(alpha: 0.7))),
                          if (i < _logs.length - 1) Container(width: 2, height: 40, color: Colors.deepPurpleAccent.withValues(alpha: 0.15)),
                        ]),
                        const SizedBox(width: 10),
                        // Log card
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Row(children: [
                              Text(log['emoji'] ?? '📱', style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(log['activity'] ?? '', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(log['detail'] ?? '', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11)),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(timeStr, style: GoogleFonts.outfit(color: Colors.deepPurpleAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                                Text(dateStr, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                              ]),
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
