import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/affection_service.dart';

class RelationshipTimelinePage extends StatefulWidget {
  const RelationshipTimelinePage({super.key});
  @override
  State<RelationshipTimelinePage> createState() =>
      _RelationshipTimelinePageState();
}

class _TimelineEvent {
  String id, emoji, title, note;
  DateTime date;
  bool isAuto;

  _TimelineEvent({
    required this.id,
    required this.emoji,
    required this.title,
    required this.note,
    required this.date,
    this.isAuto = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'emoji': emoji,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'isAuto': isAuto,
      };

  factory _TimelineEvent.fromJson(Map<String, dynamic> j) => _TimelineEvent(
        id: j['id'] as String,
        emoji: j['emoji'] as String,
        title: j['title'] as String,
        note: j['note'] as String,
        date: DateTime.parse(j['date'] as String),
        isAuto: j['isAuto'] as bool? ?? false,
      );
}

class _RelationshipTimelinePageState extends State<RelationshipTimelinePage> {
  List<_TimelineEvent> _events = [];
  final _emojiCtrl = TextEditingController(text: '🌸');
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _pickedDate = DateTime.now();

  final _quickEmojis = [
    '🌸',
    '💕',
    '💍',
    '🎉',
    '🏆',
    '📅',
    '✈️',
    '🎂',
    '🌹',
    '⭐',
    '🎮',
    '🎁'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emojiCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('relationship_timeline');
    List<_TimelineEvent> events = [];
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        events = list
            .map((e) => _TimelineEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    // Seed if empty
    if (events.isEmpty) {
      events = [
        _TimelineEvent(
          id: 'seed_1',
          emoji: '💕',
          title: 'Our Story Begins',
          note: 'The day we first connected, Darling~',
          date: DateTime.now().subtract(const Duration(days: 30)),
          isAuto: true,
        ),
        _TimelineEvent(
          id: 'seed_2',
          emoji: '🌸',
          title: 'First 100 Points!',
          note: 'We reached 100 affection points together!',
          date: DateTime.now().subtract(const Duration(days: 7)),
          isAuto: true,
        ),
      ];
    }
    // Check affection milestones and add auto events
    final pts = AffectionService.instance.points;
    if (pts >= 500 && !events.any((e) => e.id == 'auto_500')) {
      events.add(_TimelineEvent(
        id: 'auto_500',
        emoji: '🏆',
        title: '500 Points Milestone!',
        note: 'We\'ve grown so strong, Darling~',
        date: DateTime.now(),
        isAuto: true,
      ));
    }
    if (pts >= 1000 && !events.any((e) => e.id == 'auto_1000')) {
      events.add(_TimelineEvent(
        id: 'auto_1000',
        emoji: '💎',
        title: '1000 Points! Soulmates!',
        note: 'Truly bound by fate, Darling~ 💕',
        date: DateTime.now(),
        isAuto: true,
      ));
    }
    events.sort((a, b) => b.date.compareTo(a.date));
    setState(() => _events = events);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('relationship_timeline',
        jsonEncode(_events.map((e) => e.toJson()).toList()));
  }

  void _showAddDialog() {
    _emojiCtrl.text = '🌸';
    _titleCtrl.clear();
    _noteCtrl.clear();
    _pickedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlg) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Memory',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Emoji picker
              Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _quickEmojis
                      .map(
                        (e) => GestureDetector(
                          onTap: () => setDlg(() => _emojiCtrl.text = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _emojiCtrl.text == e
                                  ? Colors.pinkAccent.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                  color: _emojiCtrl.text == e
                                      ? Colors.pinkAccent
                                      : Colors.white12),
                            ),
                            child: Center(
                                child: Text(e,
                                    style: const TextStyle(fontSize: 18))),
                          ),
                        ),
                      )
                      .toList()),
              const SizedBox(height: 12),
              _dialogField(_titleCtrl, 'Event title…'),
              const SizedBox(height: 8),
              _dialogField(_noteCtrl, 'Note (optional)…', lines: 2),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: _pickedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (c, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: Colors.pinkAccent,
                            onPrimary: Colors.white),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null) setDlg(() => _pickedDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.pinkAccent.withValues(alpha: 0.1),
                    border: Border.all(
                        color: Colors.pinkAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.pinkAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_pickedDate.day}/${_pickedDate.month}/${_pickedDate.year}',
                      style: GoogleFonts.outfit(
                          color: Colors.pinkAccent, fontSize: 13),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.outfit(color: Colors.white38))),
            ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.trim().isEmpty) return;
                _events.insert(
                    0,
                    _TimelineEvent(
                      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
                      emoji: _emojiCtrl.text,
                      title: _titleCtrl.text.trim(),
                      note: _noteCtrl.text.trim(),
                      date: _pickedDate,
                    ));
                _events.sort((a, b) => b.date.compareTo(a.date));
                _save();
                setState(() {});
                AffectionService.instance.addPoints(2);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child:
                  Text('Save', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint,
          {int lines = 1}) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: ctrl,
          maxLines: lines,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
          cursorColor: Colors.pinkAccent,
          decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: Colors.white24)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('OUR STORY',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add_circle_outline, color: Colors.pinkAccent),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _events.isEmpty
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const Text('📅', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('Start adding memories, Darling~',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 16)),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _showAddDialog,
                    child: Text('Add first memory →',
                        style: GoogleFonts.outfit(color: Colors.pinkAccent)),
                  ),
                ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: _events.length,
              itemBuilder: (ctx, i) {
                final ev = _events[i];
                final months = [
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
                  'Dec'
                ];
                final dateStr =
                    '${months[ev.date.month - 1]} ${ev.date.day}, ${ev.date.year}';
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline line + dot
                    Column(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ev.isAuto
                              ? Colors.pinkAccent.withValues(alpha: 0.2)
                              : Colors.deepPurpleAccent.withValues(alpha: 0.2),
                          border: Border.all(
                              color: ev.isAuto
                                  ? Colors.pinkAccent.withValues(alpha: 0.5)
                                  : Colors.deepPurpleAccent
                                      .withValues(alpha: 0.5)),
                        ),
                        child: Center(
                            child: Text(ev.emoji,
                                style: const TextStyle(fontSize: 18))),
                      ),
                      if (i < _events.length - 1)
                        Container(
                          width: 2,
                          height: 60,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                    ]),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(dateStr,
                                style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 11,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text(ev.title,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            if (ev.note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(ev.note,
                                  style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      height: 1.4)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
