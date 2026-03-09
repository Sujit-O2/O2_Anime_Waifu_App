part of '../main.dart';

extension _MoodTrackerPageExtension on _ChatHomePageState {
  Widget _buildMoodTrackerPage() {
    return _MoodTrackerView();
  }
}

// ─── Mood data ────────────────────────────────────────────────────────────────
const _moodData = [
  (emoji: '😄', label: 'Happy', color: Color(0xFFFFD700)),
  (emoji: '😊', label: 'Good', color: Color(0xFF7CFC00)),
  (emoji: '😐', label: 'Neutral', color: Color(0xFF87CEEB)),
  (emoji: '😔', label: 'Sad', color: Color(0xFF6495ED)),
  (emoji: '😤', label: 'Frustrated', color: Color(0xFFFF6347)),
  (emoji: '😴', label: 'Tired', color: Color(0xFF9370DB)),
  (emoji: '💪', label: 'Motivated', color: Color(0xFF00FA9A)),
  (emoji: '😰', label: 'Anxious', color: Color(0xFFFF8C00)),
];

Color _colorForMood(String mood) {
  for (final m in _moodData) {
    if (mood.contains(m.label) || mood.contains(m.emoji)) {
      return m.color;
    }
  }
  return Colors.white38;
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class _MoodTrackerView extends StatefulWidget {
  @override
  State<_MoodTrackerView> createState() => _MoodTrackerViewState();
}

class _MoodTrackerViewState extends State<_MoodTrackerView>
    with TickerProviderStateMixin {
  List<Map<String, String>> _entries = [];
  bool _loading = true;
  String? _selectedMood;
  late final AnimationController _successCtrl;
  late final Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _successAnim =
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    _load();
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await MoodService.getAll();
    if (mounted) {
      setState(() {
        _entries = entries.reversed.toList();
        _loading = false;
      });
    }
  }

  Future<void> _logMood(String mood) async {
    setState(() => _selectedMood = mood);
    await _successCtrl.forward(from: 0);
    await MoodService.saveMood(mood);
    await _load();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _selectedMood = null);
  }

  Future<void> _clear() async {
    final messenger = ScaffoldMessenger.of(context);
    await MoodService.clearAll();
    await _load();
    messenger
        .showSnackBar(const SnackBar(content: Text('Mood history cleared 🗑')));
  }

  // Get most-used mood from history
  String? _dominantMood() {
    if (_entries.isEmpty) return null;
    final counts = <String, int>{};
    for (final e in _entries) {
      final m = e['mood'] ?? '';
      counts[m] = (counts[m] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    final dominant = _dominantMood();
    final dominantColor =
        dominant != null ? _colorForMood(dominant) : Colors.pinkAccent;

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 4),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MOOD TRACKER',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5)),
                    Text('How are you feeling, Darling?~ 💕',
                        style: GoogleFonts.outfit(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                if (_entries.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 22),
                    onPressed: _clear,
                  ),
              ],
            ),
          ),

          // ── Stats strip ─────────────────────────────────────────────────────
          if (_entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    dominantColor.withValues(alpha: 0.15),
                    dominantColor.withValues(alpha: 0.04),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: dominantColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text('🏆', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Most Common Mood',
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 10)),
                        Text(dominant ?? '',
                            style: GoogleFonts.outfit(
                                color: dominantColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: dominantColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_entries.length} logs',
                          style: GoogleFonts.outfit(
                              color: dominantColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Mood picker grid ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: _moodData.map((m) {
                final isSelected = _selectedMood == '${m.emoji} ${m.label}';
                return GestureDetector(
                  onTap: () => _logMood('${m.emoji} ${m.label}'),
                  child: AnimatedBuilder(
                    animation: _successAnim,
                    builder: (_, __) {
                      final scale =
                          isSelected ? (1.0 + 0.12 * _successAnim.value) : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                m.color.withValues(
                                    alpha: isSelected ? 0.35 : 0.10),
                                m.color.withValues(alpha: 0.02),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: m.color
                                  .withValues(alpha: isSelected ? 0.9 : 0.25),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: m.color.withValues(alpha: 0.5),
                                        blurRadius: 12,
                                        spreadRadius: 1),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(m.emoji,
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text(m.label,
                                  style: GoogleFonts.outfit(
                                      color:
                                          isSelected ? m.color : Colors.white60,
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Expanded(child: Divider(color: Colors.white12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('HISTORY',
                      style: GoogleFonts.outfit(
                          color: Colors.white24,
                          fontSize: 10,
                          letterSpacing: 1.5)),
                ),
                const Expanded(child: Divider(color: Colors.white12)),
              ],
            ),
          ),

          // ── History list ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.pinkAccent, strokeWidth: 2))
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('😶', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No moods logged yet!',
                                style: GoogleFonts.outfit(
                                    color: Colors.white38, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Tap an emoji above to start 💕',
                                style: GoogleFonts.outfit(
                                    color: Colors.white24, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _entries.length,
                        itemBuilder: (ctx, i) {
                          final e = _entries[i];
                          final mood = e['mood'] ?? '';
                          final ts = DateTime.tryParse(e['ts'] ?? '') ??
                              DateTime.now();
                          final color = _colorForMood(mood);
                          final isToday = ts.day == DateTime.now().day &&
                              ts.month == DateTime.now().month;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                color.withValues(alpha: 0.10),
                                color.withValues(alpha: 0.02),
                              ]),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                // Color dot
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: color),
                                ),
                                const SizedBox(width: 12),
                                Text(mood,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                if (isToday)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('TODAY',
                                        style: GoogleFonts.outfit(
                                            color: color,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5)),
                                  ),
                                Text(
                                  '${ts.day}/${ts.month}  '
                                  '${ts.hour.toString().padLeft(2, '0')}:'
                                  '${ts.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
