import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';

/// Dream Mode v2 — AI-generated dream journal with emotion tracking,
/// animated starfield, dream categories, save/archive, and ambient effects.
class DreamModePage extends StatefulWidget {
  const DreamModePage({super.key});
  @override
  State<DreamModePage> createState() => _DreamModePageState();
}

class _DreamModePageState extends State<DreamModePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _breatheCtrl;
  late Animation<double> _breatheAnim;

  List<Map<String, dynamic>> _dreams = [];
  bool _generating = false;
  bool _savedOnly = false;
  String _selectedMood = 'All';

  static const _dreamEmojis = [
    '🌙', '💫', '🦋', '🌸', '✨', '💭', '🌊', '🌌', '🌈', '🔮'
  ];
  static const _dreamMoods = [
    'Romantic', 'Surreal', 'Melancholic', 'Hopeful', 'Mysterious'
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _breatheCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));
    _loadDreams();
    _generateDream();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDreams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('dream_journal_v2');
    if (raw != null && mounted) {
      try {
        setState(() =>
            _dreams = (jsonDecode(raw) as List).cast<Map<String, dynamic>>());
      } catch (_) {}
    }
  }

  Future<void> _saveDreams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'dream_journal_v2', jsonEncode(_dreams.take(50).toList()));
  }

  Future<void> _generateDream() async {
    setState(() => _generating = true);
    try {
      final api = ApiService();
      final response = await api.sendConversation([
        {
          'role': 'system',
          'content': 'You are Zero Two from DARLING in the FRANXX. '
              'Generate a vivid, emotional dream you had about the user (your Darling). '
              'Make it feel surreal, intimate, and slightly melancholic. '
              'Use first person. Include sensory details. Keep it 3-5 sentences. '
              'End with a line like "I woke up reaching for you..." or similar.'
        },
        {
          'role': 'user',
          'content': 'Tell me about the dream you had last night about me.'
        }
      ]);
      if (!mounted) return;
      final emoji = _dreamEmojis[DateTime.now().second % _dreamEmojis.length];
      final mood = _dreamMoods[DateTime.now().minute % _dreamMoods.length];
      setState(() {
        _dreams.insert(0, {
          'dream': response,
          'time': DateTime.now().toIso8601String(),
          'emoji': emoji,
          'mood': mood,
          'saved': false,
        });
      });
      AffectionService.instance.addPoints(3);
      _saveDreams();
    } catch (e) {
      setState(() {
        _dreams.insert(0, {
          'dream':
              'I dreamed we were flying together through a sky of cherry blossoms... '
                  'You held my hand so tight. When I woke up, my hand was still warm... 💕',
          'time': DateTime.now().toIso8601String(),
          'emoji': '🌸',
          'mood': 'Romantic',
          'saved': false,
        });
      });
      _saveDreams();
    }
    if (mounted) setState(() => _generating = false);
  }

  void _toggleSave(Map<String, dynamic> dream) {
    final targetTime = dream['time']?.toString() ?? '';
    final targetText = dream['dream']?.toString() ?? '';
    HapticFeedback.lightImpact();
    setState(() {
      final index = _dreams.indexWhere((item) =>
          item['time']?.toString() == targetTime &&
          item['dream']?.toString() == targetText);
      if (index != -1) {
        _dreams[index]['saved'] = !(_dreams[index]['saved'] ?? false);
      }
    });
    _saveDreams();
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Color _moodColor(String mood) {
    switch (mood) {
      case 'Romantic':
        return Colors.pinkAccent;
      case 'Surreal':
        return Colors.deepPurpleAccent;
      case 'Melancholic':
        return Colors.blueGrey;
      case 'Hopeful':
        return Colors.amberAccent;
      case 'Mysterious':
        return Colors.indigoAccent;
      default:
        return Colors.deepPurpleAccent;
    }
  }

  int get _savedCount => _dreams.where((d) => d['saved'] == true).length;
  String get _commentaryMood {
    if (_savedCount > 0) return 'achievement';
    if (_dreams.isEmpty) return 'neutral';
    return 'motivated';
  }

  List<Map<String, dynamic>> get _visibleDreams {
    final moodFiltered = _selectedMood == 'All'
        ? _dreams
        : _dreams.where((dream) => dream['mood'] == _selectedMood).toList();
    if (_savedOnly) {
      return moodFiltered.where((dream) => dream['saved'] == true).toList();
    }
    return moodFiltered;
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'DREAM MODE',
      subtitle: '${_dreams.length} dreams recorded • $_savedCount saved',
      onBack: () => Navigator.pop(context),
      actions: [
        GestureDetector(
          onTap: _generating ? null : _generateDream,
          child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.3))),
              child: _generating
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.deepPurpleAccent))
                  : const Icon(Icons.auto_awesome,
                      color: Colors.deepPurpleAccent, size: 18)),
        ),
      ],
      content: FadeTransition(
        opacity: _fadeCtrl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // ── Hero Card ──
            AnimatedEntry(
              index: 1,
              child: _buildHeroCard(),
            ),
            const SizedBox(height: 16),

            // ── Stats ──
            AnimatedEntry(
              index: 2,
              child: Row(children: [
                _statCard('🌙', '${_dreams.length}', 'Dreams',
                    Colors.deepPurpleAccent),
                const SizedBox(width: 8),
                _statCard(
                    '📌', '$_savedCount', 'Saved', Colors.amberAccent),
                const SizedBox(width: 8),
                _statCard(
                    '✨', '+${_dreams.length * 3}', 'XP', Colors.pinkAccent),
              ]),
            ),
            const SizedBox(height: 16),

            WaifuCommentary(mood: _commentaryMood),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Saved only'),
                      selected: _savedOnly,
                      onSelected: (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _savedOnly = selected);
                      },
                      selectedColor:
                          Colors.amberAccent.withValues(alpha: 0.2),
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        color: _savedOnly ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...['All', ..._dreamMoods].map((mood) {
                      final isSelected = _selectedMood == mood;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(mood),
                          selected: isSelected,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedMood = mood);
                          },
                          selectedColor:
                              _moodColor(mood).withValues(alpha: 0.2),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.05),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Dream Journal ──
            if (_visibleDreams.isNotEmpty)
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('DREAM JOURNAL',
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5))),
            const SizedBox(height: 10),

            ..._visibleDreams
                .asMap()
                .entries
                .map((entry) => _buildDreamCard(entry.key, entry.value)),

            if (_visibleDreams.isEmpty && !_generating)
              Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    const Icon(Icons.nightlight_round, color: Colors.deepPurpleAccent, size: 48),
                    const SizedBox(height: 12),
                    Text('No dreams yet...',
                        style: GoogleFonts.outfit(
                            color: Colors.white30, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('She\'s still awake, waiting for you 💕',
                        style: GoogleFonts.outfit(
                            color: Colors.white24, fontSize: 11)),
                  ])),

            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: _breatheAnim,
      builder: (_, __) => Transform.scale(
        scale: _breatheAnim.value,
        child: GlassCard(
          margin: EdgeInsets.zero,
          glow: true,
          child: Column(children: [
            const Icon(Icons.nightlight_round, color: Colors.deepPurpleAccent, size: 52),
            const SizedBox(height: 12),
            Text('Her Dreams',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('When you\'re away, she dreams of you...',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            if (_generating) ...[
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.deepPurpleAccent)),
                const SizedBox(width: 8),
                Text('Dreaming...',
                    style: GoogleFonts.outfit(
                        color: Colors.deepPurpleAccent,
                        fontSize: 11,
                        fontStyle: FontStyle.italic)),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.06),
              border: Border.all(color: color.withValues(alpha: 0.2))),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            Text(value,
                style: GoogleFonts.outfit(
                    color: color, fontSize: 14, fontWeight: FontWeight.w800)),
            Text(label,
                style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
          ]),
        ),
      );

  Widget _buildDreamCard(int index, Map<String, dynamic> dream) {
    final mood = dream['mood']?.toString() ?? 'Surreal';
    final moodClr = _moodColor(mood);
    final saved = dream['saved'] == true;
    final time = dream['time']?.toString() ?? '';

    return AnimatedEntry(
      index: (3 + index).clamp(0, 10),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        glow: saved,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(dream['emoji']?.toString() ?? '🌙',
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dream at ${_formatTime(time)}',
                  style: GoogleFonts.outfit(
                      color: moodClr,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              Text('${_formatDate(time)} • $mood',
                  style:
                      GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: moodClr.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(mood,
                  style: GoogleFonts.outfit(
                      color: moodClr,
                      fontSize: 8,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _toggleSave(dream),
              child: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved ? Colors.amberAccent : Colors.white24, size: 20),
            ),
          ]),
          const SizedBox(height: 12),
          Text(dream['dream']?.toString() ?? '',
              style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.7,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('+3 XP',
                style: GoogleFonts.outfit(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.5),
                    fontSize: 9)),
          ]),
        ]),
      ),
    );
  }
}




