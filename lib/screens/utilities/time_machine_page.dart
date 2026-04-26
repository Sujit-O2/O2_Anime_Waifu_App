import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class TimeMachinePage extends StatefulWidget {
  const TimeMachinePage({super.key});

  @override
  State<TimeMachinePage> createState() => _TimeMachinePageState();
}

class _TimeMachinePageState extends State<TimeMachinePage> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _events = <Map<String, dynamic>>[];
  bool _loading = true;

  static const List<String> _dayNames = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  bool get _isToday {
    final DateTime now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _commentaryMood {
    if (_events.length >= 5) {
      return 'achievement';
    }
    if (_events.isNotEmpty) {
      return 'motivated';
    }
    return 'relaxed';
  }

  @override
  void initState() {
    super.initState();
    _loadForDate(_selectedDate);
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((Map entry) => entry.map(
                (dynamic key, dynamic value) =>
                    MapEntry(key.toString(), value),
              ))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadForDate(DateTime date) async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> logs =
        _decodeList(prefs.getString('autolifelog_entries'));
    final List<Map<String, dynamic>> thoughts =
        _decodeList(prefs.getString('thought_capture'));
    final List<Map<String, dynamic>> goals =
        _decodeList(prefs.getString('goal_tracker_goals'));

    final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];

    for (final Map<String, dynamic> log in logs) {
      final String timeRaw =
          (log['time'] ?? log['createdAt'] ?? log['timestamp'] ?? '')
              .toString();
      final DateTime? time = DateTime.tryParse(timeRaw);
      if (time != null && _sameDay(time, date)) {
        events.add(<String, dynamic>{
          'source': 'life_log',
          'icon': Icons.phone_android_rounded,
          'color': V2Theme.secondaryColor,
          'activity': (log['activity'] ?? log['title'] ?? 'Life log entry')
              .toString(),
          'detail': (log['detail'] ?? log['context'] ?? '').toString(),
          'time': time,
        });
      }
    }

    for (final Map<String, dynamic> thought in thoughts) {
      final String timeRaw =
          (thought['time'] ?? thought['createdAt'] ?? '').toString();
      final DateTime? time = DateTime.tryParse(timeRaw);
      if (time != null && _sameDay(time, date)) {
        events.add(<String, dynamic>{
          'source': 'thought',
          'icon': Icons.psychology_alt_rounded,
          'color': Colors.purpleAccent,
          'activity':
              (thought['text'] ?? thought['title'] ?? 'Thought captured')
                  .toString(),
          'detail': (thought['emoji'] ?? thought['mood'] ?? '').toString(),
          'time': time,
        });
      }
    }

    for (final Map<String, dynamic> goal in goals) {
      final String timeRaw =
          (goal['created'] ?? goal['createdAt'] ?? '').toString();
      final DateTime? time = DateTime.tryParse(timeRaw);
      if (time != null && _sameDay(time, date)) {
        events.add(<String, dynamic>{
          'source': 'goal',
          'icon': Icons.track_changes_rounded,
          'color': Colors.amberAccent,
          'activity': 'Goal: ${(goal['title'] ?? 'Untitled goal').toString()}',
          'detail': 'Progress ${(goal['progress'] ?? 0).toString()}%',
          'time': time,
        });
      }
    }

    events.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime ta = a['time'] as DateTime;
      final DateTime tb = b['time'] as DateTime;
      return tb.compareTo(ta);
    });

    if (!mounted) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _selectedDate = date;
      _events = events;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadForDate(_selectedDate);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: V2Theme.primaryColor,
              surface: V2Theme.surfaceLight,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      await _loadForDate(picked);
    }
  }

  void _navigate(int days) {
    final DateTime newDate = _selectedDate.add(Duration(days: days));
    if (newDate.isAfter(DateTime.now())) {
      return;
    }
    _loadForDate(newDate);
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: V2Theme.primaryColor,
          backgroundColor: V2Theme.surfaceLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIME MACHINE',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Browse memory timelines by date',
                          style: GoogleFonts.outfit(
                            color: V2Theme.secondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedEntry(
                index: 0,
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isToday
                                  ? 'Today\'s memory stream'
                                  : '${_dayNames[_selectedDate.weekday - 1]} archive',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(_selectedDate),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _events.isEmpty
                                  ? 'No activity is stored for this date yet, but the timeline is ready whenever you log something new.'
                                  : 'Found ${_events.length} memory ${_events.length == 1 ? 'marker' : 'markers'} from your logs, thoughts, and goals.',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ProgressRing(
                        progress: (_events.length / 6).clamp(0, 1).toDouble(),
                        foreground: V2Theme.secondaryColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              color: V2Theme.secondaryColor,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_events.length}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Events',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedEntry(
                index: 1,
                child: WaifuCommentary(mood: _commentaryMood),
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Entries',
                      value: '${_events.length}',
                      icon: Icons.timeline_rounded,
                      color: V2Theme.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Date',
                      value: _isToday ? 'Today' : _dayNames[_selectedDate.weekday - 1],
                      icon: Icons.event_rounded,
                      color: V2Theme.secondaryColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Sources',
                      value: '${_events.map((Map<String, dynamic> event) => event['source']).toSet().length}',
                      icon: Icons.hub_rounded,
                      color: Colors.amberAccent,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      title: 'Mode',
                      value: _events.isEmpty ? 'Quiet' : 'Loaded',
                      icon: Icons.auto_awesome_rounded,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _navigate(-1),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Column(
                          children: [
                            Text(
                              _isToday
                                  ? 'TODAY'
                                  : _dayNames[_selectedDate.weekday - 1].toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: V2Theme.secondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_selectedDate),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to pick another date',
                              style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isToday ? null : () => _navigate(1),
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: _isToday ? Colors.white24 : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      color: V2Theme.primaryColor,
                    ),
                  ),
                )
              else if (_events.isEmpty)
                const GlassCard(
                  margin: EdgeInsets.zero,
                  child: EmptyState(
                    icon: Icons.travel_explore_rounded,
                    title: 'No memories for this date',
                    subtitle:
                        'Life Log, Thought Capture, and Goal Tracker entries will start appearing here once the day has recorded moments to revisit.',
                  ),
                )
              else
                ..._events.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                  final Map<String, dynamic> event = entry.value;
                  final Color color = event['color'] as Color;
                  final DateTime time = event['time'] as DateTime;
                  return AnimatedEntry(
                    index: entry.key + 2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            if (entry.key < _events.length - 1)
                              Container(
                                width: 2,
                                height: 70,
                                color: color.withValues(alpha: 0.18),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: color.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    event['icon'] as IconData,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['activity']?.toString() ?? '',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if ((event['detail']?.toString() ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          event['detail']?.toString() ?? '',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatTime(time),
                                  style: GoogleFonts.outfit(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}



