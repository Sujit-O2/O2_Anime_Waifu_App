import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Time Machine Memory — "What was I doing last Sunday?"
/// Browse past activity, chats, and moments by date.
class TimeMachinePage extends StatefulWidget {
  const TimeMachinePage({super.key});
  @override
  State<TimeMachinePage> createState() => _TimeMachinePageState();
}

class _TimeMachinePageState extends State<TimeMachinePage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() { super.initState(); _loadForDate(_selectedDate); }

  Future<void> _loadForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    // Load from life log
    final logData = prefs.getString('autolifelog_entries');
    List<Map<String, dynamic>> logs = [];
    if (logData != null) {
      logs = (jsonDecode(logData) as List).cast<Map<String, dynamic>>();
    }

    // Load from thought capture
    final thoughtData = prefs.getString('thought_capture');
    List<Map<String, dynamic>> thoughts = [];
    if (thoughtData != null) {
      thoughts = (jsonDecode(thoughtData) as List).cast<Map<String, dynamic>>();
    }

    // Load from goals
    final goalData = prefs.getString('goal_tracker_goals');
    List<Map<String, dynamic>> goals = [];
    if (goalData != null) {
      goals = (jsonDecode(goalData) as List).cast<Map<String, dynamic>>();
    }

    // Filter by selected date
    final events = <Map<String, dynamic>>[];
    for (final log in logs) {
      final t = DateTime.tryParse(log['time'] ?? '');
      if (t != null && t.day == date.day && t.month == date.month && t.year == date.year) {
        events.add({...log, 'source': 'life_log', 'sourceEmoji': '📱'});
      }
    }
    for (final thought in thoughts) {
      final t = DateTime.tryParse(thought['time'] ?? '');
      if (t != null && t.day == date.day && t.month == date.month && t.year == date.year) {
        events.add({...thought, 'source': 'thought', 'sourceEmoji': '💭', 'activity': thought['text'], 'emoji': thought['emoji'] ?? '💭'});
      }
    }
    for (final goal in goals) {
      final t = DateTime.tryParse(goal['created'] ?? '');
      if (t != null && t.day == date.day && t.month == date.month && t.year == date.year) {
        events.add({'source': 'goal', 'sourceEmoji': '🎯', 'activity': 'Goal: ${goal['title']}', 'emoji': '🎯', 'detail': 'Progress: ${goal['progress'] ?? 0}%', 'time': goal['created']});
      }
    }

    // Sort by time
    events.sort((a, b) {
      final ta = DateTime.tryParse(a['time'] ?? '');
      final tb = DateTime.tryParse(b['time'] ?? '');
      if (ta == null || tb == null) return 0;
      return ta.compareTo(tb);
    });

    // If no events, add a placeholder
    if (events.isEmpty) {
      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
      events.add({'source': 'none', 'emoji': '🔍', 'activity': isToday ? 'Start logging your day!' : 'No records found for this date', 'detail': 'Use Life Log & Thought Capture to track activities', 'sourceEmoji': '📭'});
    }

    setState(() => _events = events);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, surface: Color(0xFF1A1A2E))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadForDate(picked);
    }
  }

  void _navigate(int days) {
    final newDate = _selectedDate.add(Duration(days: days));
    if (newDate.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = newDate);
    _loadForDate(newDate);
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final isToday = _selectedDate.day == DateTime.now().day && _selectedDate.month == DateTime.now().month;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.pop(context)),
        title: Text('TIME MACHINE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Date navigator
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.cyanAccent.withValues(alpha: 0.08), Colors.deepPurpleAccent.withValues(alpha: 0.06)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54), onPressed: () => _navigate(-1)),
            Expanded(
              child: GestureDetector(
                onTap: _selectDate,
                child: Column(children: [
                  Text('⏳ ${isToday ? "TODAY" : dayNames[_selectedDate.weekday - 1].toUpperCase()}', style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  Text('${_selectedDate.day} ${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('${_events.where((e) => e['source'] != 'none').length} events', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                ]),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: isToday ? Colors.white12 : Colors.white54),
              onPressed: isToday ? null : () => _navigate(1),
            ),
          ]),
        ),
        const SizedBox(height: 8),

        // Events timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _events.length,
            itemBuilder: (_, i) {
              final e = _events[i];
              final t = DateTime.tryParse(e['time'] ?? '');
              final timeStr = t != null ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}' : '';
              final c = e['source'] == 'thought' ? Colors.purpleAccent : e['source'] == 'goal' ? Colors.amberAccent : Colors.cyanAccent;

              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Timeline
                Column(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.7))),
                  if (i < _events.length - 1) Container(width: 2, height: 44, color: c.withValues(alpha: 0.12)),
                ]),
                const SizedBox(width: 10),
                Expanded(child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.1))),
                  child: Row(children: [
                    Text(e['emoji'] ?? '📱', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e['activity'] ?? '', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      if (e['detail'] != null) Text(e['detail'], style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                    ])),
                    if (timeStr.isNotEmpty) Text(timeStr, style: GoogleFonts.outfit(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                )),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
