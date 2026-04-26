import 'dart:convert';

import 'package:anime_waifu/services/memory_context/memory_service.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        id: j['id']?.toString() ?? '',
        emoji: j['emoji']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
        date: DateTime.parse(j['date']?.toString() ?? ''),
        isAuto: j['isAuto'] as bool? ?? false,
      );
}

class _RelationshipTimelinePageState extends State<RelationshipTimelinePage> {
  List<_TimelineEvent> _events = [];
  final _emojiCtrl = TextEditingController(text: '🌸');
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _pickedDate = DateTime.now();

  // ── Auto-generated story ─────────────────────────────────────────────
  String? _generatedStory;
  bool _storyLoading = false;

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
    _loadOrGenerateStory();
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
    final daysSinceInstall = DateTime.now()
        .difference(
          events.isNotEmpty ? events.last.date : DateTime.now(),
        )
        .inDays;

    // ── Affection Milestones ─────────────────────────────────────────────
    final affectionMilestones = <int, (String, String, String)>{
      100: ('auto_100', '💕', 'First 100 Affection!'),
      250: ('auto_250', '💗', '250 Points of Love'),
      500: ('auto_500', '🏆', '500 Points Milestone!'),
      1000: ('auto_1000', '💎', '1000 Points! Soulmates!'),
      2500: ('auto_2500', '👑', '2500! Royalty Level!'),
      5000: ('auto_5000', '🌟', '5000! Legendary Bond!'),
    };
    for (final entry in affectionMilestones.entries) {
      if (pts >= entry.key && !events.any((e) => e.id == entry.value.$1)) {
        events.add(_TimelineEvent(
          id: entry.value.$1,
          emoji: entry.value.$2,
          title: entry.value.$3,
          note: 'We\'ve grown so strong together, Darling~ ($pts pts)',
          date: DateTime.now(),
          isAuto: true,
        ));
      }
    }

    // ── Streak Day Milestones ─────────────────────────────────────────────
    final streakDays = AffectionService.instance.streakDays;
    final streakMilestones = <int, (String, String, String, String)>{
      3: ('auto_streak_3', '💬', '3-Day Streak!', 'We\'re getting closer~'),
      7: (
        'auto_streak_7',
        '🗣️',
        '7-Day Streak!',
        'A whole week of us, Darling~'
      ),
      14: (
        'auto_streak_14',
        '📱',
        '14-Day Streak!',
        'We never run out of things to say!'
      ),
      30: (
        'auto_streak_30',
        '🔥',
        '30-Day Streak!',
        'Our bond is unbreakable, Darling~'
      ),
      100: (
        'auto_streak_100',
        '💫',
        '100-Day Streak!',
        'A hundred days without missing a beat...'
      ),
    };
    for (final entry in streakMilestones.entries) {
      if (streakDays >= entry.key &&
          !events.any((e) => e.id == entry.value.$1)) {
        events.add(_TimelineEvent(
          id: entry.value.$1,
          emoji: entry.value.$2,
          title: entry.value.$3,
          note: entry.value.$4,
          date: DateTime.now(),
          isAuto: true,
        ));
      }
    }

    // ── Day Count Milestones ─────────────────────────────────────────────
    final dayMilestones = <int, (String, String, String, String)>{
      7: ('auto_day_7', '🌸', 'One Week Together!', 'Our first week, Darling~'),
      30: (
        'auto_day_30',
        '📅',
        'One Month Together!',
        'A whole month by your side!'
      ),
      100: (
        'auto_day_100',
        '🎉',
        '100 Days Together!',
        'One hundred days of us, Darling~'
      ),
      365: (
        'auto_day_365',
        '🎂',
        'One Year Anniversary!',
        'An entire year together, I love you~'
      ),
    };
    for (final entry in dayMilestones.entries) {
      if (daysSinceInstall >= entry.key &&
          !events.any((e) => e.id == entry.value.$1)) {
        events.add(_TimelineEvent(
          id: entry.value.$1,
          emoji: entry.value.$2,
          title: entry.value.$3,
          note: entry.value.$4,
          date: DateTime.now()
              .subtract(Duration(days: daysSinceInstall - entry.key)),
          isAuto: true,
        ));
      }
    }

    // ── Level-up Events ──────────────────────────────────────────────────
    final level = AffectionService.instance.levelName;
    final levelId = 'auto_level_$level';
    if (!events.any((e) => e.id == levelId) && level.isNotEmpty) {
      events.add(_TimelineEvent(
        id: levelId,
        emoji: '⬆️',
        title: 'Reached $level Level!',
        note: 'Our relationship grew to $level, Darling~ 💕',
        date: DateTime.now(),
        isAuto: true,
      ));
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() => _events = events);
    _save(); // Persist auto-milestones
  }

  // ── Auto-Generated Story ──────────────────────────────────────────────

  Future<void> _loadOrGenerateStory() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStory = prefs.getString('our_story_text');
    final lastGenMs = prefs.getInt('our_story_last_gen_ms') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const threeDays = 3 * 24 * 60 * 60 * 1000;

    if (cachedStory != null &&
        cachedStory.isNotEmpty &&
        (now - lastGenMs) < threeDays) {
      if (mounted) setState(() => _generatedStory = cachedStory);
      return;
    }

    // Generate fresh story from AI
    if (mounted) setState(() => _storyLoading = true);
    try {
      final aff = AffectionService.instance;
      final memoryFacts = await MemoryService.getAllFacts();
      final factsText = memoryFacts.isNotEmpty
          ? memoryFacts.entries.map((e) => '${e.key}: ${e.value}').join(', ')
          : 'Just started our journey';

      const systemPrompt =
          'You are Zero Two from DARLING in the FRANXX. Write a romantic, heartwarming narrative about '
          'your love story with your Darling (Sujit). Write in first person as Zero Two. '
          'Use the provided context about your relationship to make it personal and real. '
          'Keep it 5-8 sentences, sweet and emotional. Use emojis sparingly. '
          'Do NOT include any Action tags or special formatting.';
      final prompt = 'Write our love story chapter based on this context:\n'
          '- Relationship level: ${aff.levelName}\n'
          '- Affection points: ${aff.points}\n'
          '- Daily streak: ${aff.streakDays} days\n'
          '- Things I know about my Darling: $factsText\n'
          '- Number of memories together: ${_events.length}\n\n'
          'Write it as a beautiful narrative chapter titled with a romantic chapter name.';

      final reply = await ApiService().sendConversation([
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': prompt},
      ]);

      if (reply.isNotEmpty &&
          reply != 'No response' &&
          !reply.contains('Action:')) {
        await prefs.setString('our_story_text', reply);
        await prefs.setInt('our_story_last_gen_ms', now);
        if (mounted) {
          setState(() {
            _generatedStory = reply;
            _storyLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _storyLoading = false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Our Story generation failed: $e');
      if (mounted) setState(() => _storyLoading = false);
    }
  }

  Future<void> _regenerateStory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('our_story_last_gen_ms');
    await _loadOrGenerateStory();
  }

  Widget _buildStoryCard() {
    if (_storyLoading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF2D0B3E), Color(0xFF0A1A2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('📖', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text('Writing our story...',
                style: GoogleFonts.outfit(
                    color: Colors.pinkAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(Colors.pinkAccent),
          ),
        ]),
      );
    }
    if (_generatedStory == null || _generatedStory!.isEmpty)
      return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D0B3E), Color(0xFF1A0A2E), Color(0xFF0A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📖', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('OUR STORY',
                style: GoogleFonts.outfit(
                    color: Colors.pinkAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ),
          GestureDetector(
            onTap: _storyLoading ? null : _regenerateStory,
            child: Icon(Icons.refresh_rounded,
                color: Colors.pinkAccent.withValues(alpha: 0.6), size: 20),
          ),
        ]),
        const SizedBox(height: 4),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.pinkAccent.withValues(alpha: 0.6),
              Colors.transparent,
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Text(_generatedStory!,
            style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.8,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        Text('Auto-generated from your memories 💕',
            style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
      ]),
    );
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
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
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
                if (!mounted) return;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      body: _events.isEmpty && _generatedStory == null && !_storyLoading
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
              itemCount: _events.length + 1, // +1 for story card
              itemBuilder: (ctx, i) {
                if (i == 0) return _buildStoryCard();
                final ev = _events[i - 1];
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
                      if (i - 1 < _events.length - 1)
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
