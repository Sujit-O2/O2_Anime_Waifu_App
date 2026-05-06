import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class AutoLifeManagerPage extends StatefulWidget {
  const AutoLifeManagerPage({super.key});
  @override
  State<AutoLifeManagerPage> createState() => _AutoLifeManagerPageState();
}

class _AutoLifeManagerPageState extends State<AutoLifeManagerPage> {
  static const _accent = Color(0xFFFFD700);
  static const _bg = Color(0xFF0C0A00);

  bool _managerActive = false;
  List<Map<String, dynamic>> _schedule = [];
  final List<Map<String, dynamic>> _adjustments = [];
  int _completedToday = 0;
  Timer? _adjustTimer;
  final Random _rng = Random();

  static final _defaultSchedule = [
    {'time': '07:00', 'task': 'Morning routine + hydration', 'type': 'health', 'done': false, 'priority': 'high'},
    {'time': '08:00', 'task': 'Review today\'s goals', 'type': 'productivity', 'done': false, 'priority': 'high'},
    {'time': '09:00', 'task': 'Deep work block #1', 'type': 'work', 'done': false, 'priority': 'critical'},
    {'time': '11:00', 'task': 'Short break + stretch', 'type': 'health', 'done': false, 'priority': 'medium'},
    {'time': '12:00', 'task': 'Lunch + no screens', 'type': 'health', 'done': false, 'priority': 'medium'},
    {'time': '14:00', 'task': 'Emails & communication', 'type': 'work', 'done': false, 'priority': 'low'},
    {'time': '15:00', 'task': 'Learning / skill building', 'type': 'growth', 'done': false, 'priority': 'high'},
    {'time': '17:00', 'task': 'Exercise (30 min)', 'type': 'health', 'done': false, 'priority': 'high'},
    {'time': '19:00', 'task': 'Dinner + family time', 'type': 'personal', 'done': false, 'priority': 'medium'},
    {'time': '21:00', 'task': 'Deep work block #2', 'type': 'work', 'done': false, 'priority': 'critical'},
    {'time': '23:00', 'task': 'Wind down + journal', 'type': 'health', 'done': false, 'priority': 'medium'},
    {'time': '23:30', 'task': 'Sleep', 'type': 'health', 'done': false, 'priority': 'critical'},
  ];

  static const _typeColors = {
    'health': Color(0xFF4CAF50),
    'productivity': Color(0xFF79C0FF),
    'work': Color(0xFFFFAB40),
    'growth': Color(0xFFB388FF),
    'personal': Color(0xFFFF4FA8),
  };

  static const _priorityColors = {
    'critical': Color(0xFFFF5252),
    'high': Color(0xFFFFAB40),
    'medium': Color(0xFF79C0FF),
    'low': Color(0xFF4CAF50),
  };

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('auto_life_manager'));
    _load();
  }

  @override
  void dispose() {
    _adjustTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('alm_schedule');
    final active = p.getBool('alm_active') ?? false;
    setState(() {
      _managerActive = active;
      if (raw != null) {
        _schedule = List<Map<String, dynamic>>.from(jsonDecode(raw));
      } else {
        _schedule = _defaultSchedule.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      _completedToday = _schedule.where((t) => t['done'] == true).length;
    });
    if (active) _startRealTimeAdjustments();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('alm_schedule', jsonEncode(_schedule));
    await p.setBool('alm_active', _managerActive);
  }

  void _toggleManager() {
    setState(() => _managerActive = !_managerActive);
    if (_managerActive) {
      _startRealTimeAdjustments();
    } else {
      _adjustTimer?.cancel();
    }
    _save();
  }

  void _startRealTimeAdjustments() {
    _adjustTimer?.cancel();
    _adjustTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      _generateAdjustment();
    });
  }

  void _generateAdjustment() {
    final adjustments = [
      '⚡ You\'re behind on deep work. Extending block by 30 min.',
      '😴 Sleep debt detected. Moving bedtime to 11:00 PM tonight.',
      '📈 High productivity streak! Adding bonus learning block at 4PM.',
      '☕ Caffeine crash predicted at 3PM. Scheduling walk instead.',
      '🎯 Goal completion at 60%. Reprioritizing afternoon tasks.',
    ];
    setState(() {
      _adjustments.insert(0, {
        'msg': adjustments[_rng.nextInt(adjustments.length)],
        'time': DateTime.now().toString().substring(11, 16),
      });
      if (_adjustments.length > 5) _adjustments.removeLast();
    });
  }

  void _toggleTask(int i) {
    setState(() {
      _schedule[i]['done'] = !(_schedule[i]['done'] as bool);
      _completedToday = _schedule.where((t) => t['done'] == true).length;
    });
    _save();
  }

  void _resetDay() {
    setState(() {
      for (final t in _schedule) { t['done'] = false; }
      _completedToday = 0;
      _adjustments.clear();
    });
    _save();
  }

  String get _currentTask {
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    for (final t in _schedule) {
      if (t['done'] == true) continue;
      final parts = (t['time'] as String).split(':');
      final taskMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (taskMin <= nowMin + 60) return t['task'] as String;
    }
    return 'All tasks complete! 🎉';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _schedule.isEmpty ? 0.0 : _completedToday / _schedule.length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('💡 Auto Life Manager', style: GoogleFonts.orbitron(color: _accent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _accent),
        actions: [
          Switch(value: _managerActive, onChanged: (_) => _toggleManager(), activeColor: _accent),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _dashCard(progress),
          const SizedBox(height: 16),
          if (_managerActive && _adjustments.isNotEmpty) ...[_adjustmentsCard(), const SizedBox(height: 16)],
          _scheduleCard(),
        ]),
      ),
    );
  }

  Widget _dashCard(double progress) => _card(
    child: Column(children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TODAY\'S PROGRESS', style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$_completedToday / ${_schedule.length} tasks', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress, minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
        ])),
        const SizedBox(width: 16),
        Column(children: [
          Text('${(progress * 100).toInt()}%', style: GoogleFonts.orbitron(color: _accent, fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('done', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _accent.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: _accent.withAlpha(60))),
        child: Row(children: [
          const Icon(Icons.play_arrow, color: _accent, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text('Now: $_currentTask', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold))),
        ]),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton.icon(
          onPressed: _resetDay,
          icon: const Icon(Icons.refresh, size: 14),
          label: const Text('Reset Day', style: TextStyle(fontSize: 11)),
          style: TextButton.styleFrom(foregroundColor: Colors.white38),
        ),
      ]),
    ]),
  );

  Widget _adjustmentsCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _accent.withAlpha(15), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(80)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.auto_fix_high, color: _accent, size: 14),
        const SizedBox(width: 6),
        Text('REAL-TIME ADJUSTMENTS', style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      ..._adjustments.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Text(a['time'] as String, style: const TextStyle(color: Colors.white24, fontSize: 10)),
          const SizedBox(width: 8),
          Expanded(child: Text(a['msg'] as String, style: const TextStyle(color: Colors.white, fontSize: 12))),
        ]),
      )),
    ]),
  );

  Widget _scheduleCard() => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('TODAY\'S SCHEDULE'),
      const SizedBox(height: 12),
      ...List.generate(_schedule.length, (i) {
        final t = _schedule[i];
        final done = t['done'] as bool;
        final typeColor = _typeColors[t['type']] ?? Colors.white38;
        final priorityColor = _priorityColors[t['priority']] ?? Colors.white38;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _toggleTask(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: done ? Colors.white10 : typeColor.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: done ? Colors.white12 : typeColor.withAlpha(80)),
              ),
              child: Row(children: [
                Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? Colors.greenAccent : typeColor, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t['task'] as String,
                      style: TextStyle(
                          color: done ? Colors.white38 : Colors.white,
                          fontSize: 13,
                          decoration: done ? TextDecoration.lineThrough : null)),
                  Text(t['time'] as String, style: TextStyle(color: typeColor.withAlpha(180), fontSize: 11)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: priorityColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                  child: Text(t['priority'] as String, style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ),
        );
      }),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF120E00), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withAlpha(40)),
    ),
    child: child,
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.orbitron(color: _accent, fontSize: 11, fontWeight: FontWeight.bold));
}
