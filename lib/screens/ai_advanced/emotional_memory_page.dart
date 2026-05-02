import 'package:anime_waifu/services/ai_personalization/emotional_memory_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EmotionalMemoryPage extends StatefulWidget {
  const EmotionalMemoryPage({super.key});

  @override
  State<EmotionalMemoryPage> createState() => _EmotionalMemoryPageState();
}

class _EmotionalMemoryPageState extends State<EmotionalMemoryPage> {
  final _service = EmotionalMemoryService.instance;
  final _textCtrl = TextEditingController();
  List<EmotionalMemory> _memories = [];
  bool _loading = true;
  bool _saving = false;
  MemoryEmotion _selectedEmotion = MemoryEmotion.neutral;
  double _importance = 0.5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final mems = await _service.getAllMemories();
    if (mounted) setState(() { _memories = mems; _loading = false; });
  }

  Future<void> _save() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await _service.saveMemory(
      text: text,
      emotion: _selectedEmotion,
      importance: _importance,
    );
    _textCtrl.clear();
    await _load();
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pin(EmotionalMemory m) async {
    HapticFeedback.selectionClick();
    await _service.pinMemory(m.id);
    await _load();
  }

  Future<void> _forget(EmotionalMemory m) async {
    HapticFeedback.mediumImpact();
    await _service.forgetMemory(m.id);
    await _load();
  }

  Color _emotionColor(MemoryEmotion e) {
    switch (e) {
      case MemoryEmotion.love: return Colors.pinkAccent;
      case MemoryEmotion.happy: return Colors.greenAccent;
      case MemoryEmotion.sad: return Colors.blueAccent;
      case MemoryEmotion.angry: return Colors.redAccent;
      case MemoryEmotion.scared: return Colors.orangeAccent;
      case MemoryEmotion.amused: return Colors.yellowAccent;
      case MemoryEmotion.neutral: return Colors.white38;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🧠 Emotional Memory',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(children: [
        // Stats bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            _statPill('${_memories.length}', 'Memories', Colors.deepOrange),
            const SizedBox(width: 8),
            _statPill(
                '${_memories.where((m) => m.pinned).length}',
                'Pinned',
                Colors.pinkAccent),
            const SizedBox(width: 8),
            _statPill(
                '${_memories.where((m) => m.importance > 0.7).length}',
                'High Importance',
                Colors.amberAccent),
          ]),
        ),
        // Add memory
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.deepOrange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Memory',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _textCtrl,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'What should I remember?',
                    hintStyle:
                        GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 8),
                // Emotion selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MemoryEmotion.values.map((e) {
                      final sel = _selectedEmotion == e;
                      final c = _emotionColor(e);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedEmotion = e),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel
                                ? c.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel ? c : Colors.white12),
                          ),
                          child: Text('${e.emoji} ${e.label}',
                              style: GoogleFonts.outfit(
                                  color: sel ? c : Colors.white38,
                                  fontSize: 11)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Importance: ${(_importance * 10).round()}/10',
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 11)),
                  Expanded(
                    child: Slider(
                      value: _importance,
                      onChanged: (v) => setState(() => _importance = v),
                      activeColor: Colors.deepOrange,
                      inactiveColor: Colors.white12,
                    ),
                  ),
                ]),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(_saving ? 'Saving...' : 'Save Memory',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Memory list
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange))
              : _memories.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const Text('🧠', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('No memories yet',
                              style: GoogleFonts.outfit(
                                  color: Colors.white38, fontSize: 16)),
                          Text('Add your first emotional memory above',
                              style: GoogleFonts.outfit(
                                  color: Colors.white24, fontSize: 13)),
                        ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _memories.length,
                      itemBuilder: (ctx, i) {
                        final m = _memories[i];
                        final c = _emotionColor(m.emotion);
                        return Dismissible(
                          key: ValueKey(m.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.redAccent.withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent),
                          ),
                          onDismissed: (_) => _forget(m),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: m.pinned
                                  ? c.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: m.pinned
                                      ? c.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.07)),
                            ),
                            child: Row(children: [
                              Text(m.emotion.emoji,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(m.text,
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: c.withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(m.emotion.label,
                                              style: GoogleFonts.outfit(
                                                  color: c, fontSize: 10)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                            '${(m.importance * 10).round()}/10',
                                            style: GoogleFonts.outfit(
                                                color: Colors.white38,
                                                fontSize: 10)),
                                        const Spacer(),
                                        Text(_timeAgo(m.timestamp),
                                            style: GoogleFonts.outfit(
                                                color: Colors.white24,
                                                fontSize: 10)),
                                      ]),
                                    ]),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _pin(m),
                                child: Icon(
                                  m.pinned
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  color: m.pinned ? c : Colors.white24,
                                  size: 20,
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: GoogleFonts.outfit(
                color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }
}
