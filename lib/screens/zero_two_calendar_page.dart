import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A yearly calendar view showing scheduled messages, special dates, and events.
class ZeroTwoCalendarPage extends StatefulWidget {
  const ZeroTwoCalendarPage({super.key});

  @override
  State<ZeroTwoCalendarPage> createState() => _ZeroTwoCalendarPageState();
}

class _ZeroTwoCalendarPageState extends State<ZeroTwoCalendarPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  List<_CalendarEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('calendar_events') ?? '[]';
    final decoded = jsonDecode(raw) as List<dynamic>;
    setState(() {
      _events = decoded
          .map((e) => _CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'calendar_events', jsonEncode(_events.map((e) => e.toJson()).toList()));
  }

  List<_CalendarEvent> _eventsForDay(DateTime day) {
    return _events
        .where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day)
        .toList();
  }

  void _addEvent() {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0D2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Event for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: titleCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Event title...',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.pinkAccent),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _events.add(_CalendarEvent(
                    date: _selectedDay,
                    title: titleCtrl.text.trim(),
                    emoji: '💕',
                  ));
                });
                final nav = Navigator.of(context);
                await _saveEvents();
                nav.pop();
              }
            },
            child: Text('Add', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;
    final now = DateTime.now();
    final monthEvents = _events
        .where((e) => e.date.year == _selectedMonth.year && e.date.month == _selectedMonth.month)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0613),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        onPressed: _addEvent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Zero Two Calendar',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          // Today button
          TextButton(
            onPressed: () => setState(() {
              _selectedMonth = DateTime(now.year, now.month);
              _selectedDay = now;
            }),
            child: Text('Today',
                style: GoogleFonts.outfit(
                    color: Colors.pinkAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
              onPressed: () => setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              }),
            ),
            Expanded(
              child: Text(
                '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              onPressed: () => setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              }),
            ),
          ]),
        ),
        // Day of week headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(d,
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (_, idx) {
              if (idx < firstWeekday) return const SizedBox();
              final day = idx - firstWeekday + 1;
              final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              final isSelected = date.year == _selectedDay.year && date.month == _selectedDay.month && date.day == _selectedDay.day;
              final hasEvents = _eventsForDay(date).isNotEmpty;

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.pinkAccent
                        : isToday
                            ? Colors.pinkAccent.withValues(alpha: 0.2)
                            : Colors.transparent,
                    border: isToday && !isSelected
                        ? Border.all(color: Colors.pinkAccent.withValues(alpha: 0.6))
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text('$day',
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                          )),
                      if (hasEvents)
                        Positioned(
                          bottom: 3,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.pinkAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(color: Colors.white12),
        // Events for selected day
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                '${_selectedDay.day} ${_monthName(_selectedDay.month)} ${_selectedDay.year}',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ..._eventsForDay(_selectedDay).map((e) => _EventTile(
                    event: e,
                    onDelete: () async {
                      setState(() => _events.remove(e));
                      await _saveEvents();
                    },
                  )),
              if (_eventsForDay(_selectedDay).isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text('No events — tap + to add one 💕',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                      textAlign: TextAlign.center),
                ),
              if (monthEvents.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('This Month (${monthEvents.length})',
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...monthEvents.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${e.emoji} ${e.date.day}/${e.date.month} — ${e.title}',
                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  String _monthName(int month) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
}

class _EventTile extends StatelessWidget {
  final _CalendarEvent event;
  final VoidCallback onDelete;
  const _EventTile({required this.event, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Text(event.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(event.title,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 18),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

class _CalendarEvent {
  final DateTime date;
  final String title;
  final String emoji;

  const _CalendarEvent({required this.date, required this.title, required this.emoji});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'title': title,
        'emoji': emoji,
      };

  factory _CalendarEvent.fromJson(Map<String, dynamic> j) => _CalendarEvent(
        date: DateTime.parse(j['date'] as String),
        title: j['title'] as String,
        emoji: j['emoji'] as String? ?? '💕',
      );
}
