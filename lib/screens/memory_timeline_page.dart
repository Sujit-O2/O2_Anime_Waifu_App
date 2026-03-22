import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/emotional_memory_service.dart';

class MemoryTimelinePage extends StatefulWidget {
  const MemoryTimelinePage({super.key});
  @override
  State<MemoryTimelinePage> createState() => _MemoryTimelinePageState();
}

class _MemoryTimelinePageState extends State<MemoryTimelinePage> {
  List<EmotionalMemory> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mems = await EmotionalMemoryService.instance.getAllMemories();
    if (mounted) setState(() { _memories = mems; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B18),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0828), Color(0xFF080B18)],
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(child: _loading ? _buildLoader() : _buildTimeline()),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEMORY TIMELINE',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w900,
                fontSize: 18, letterSpacing: 1.5)),
        Text('Your emotional story together',
            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11)),
      ]),
      const Spacer(),
      Text('${_memories.length} memories',
          style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11)),
    ]),
  );

  Widget _buildLoader() => const Center(
    child: CircularProgressIndicator(color: Color(0xFFBB52FF), strokeWidth: 2),
  );

  Widget _buildTimeline() {
    if (_memories.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('💭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No memories yet — start chatting!',
              style: GoogleFonts.outfit(color: Colors.white38)),
          const SizedBox(height: 8),
          Text('Emotional moments from your chats\nwill appear here automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12, height: 1.5)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _memories.length,
      itemBuilder: (ctx, i) => _MemoryCard(
        memory: _memories[i],
        isLast: i == _memories.length - 1,
        onForget: () async {
          await EmotionalMemoryService.instance.forgetMemory(_memories[i].id);
          setState(() => _memories.removeAt(i));
        },
        onPin: () async {
          await EmotionalMemoryService.instance.pinMemory(_memories[i].id);
          setState(() {});
        },
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final EmotionalMemory memory;
  final bool isLast;
  final VoidCallback onForget;
  final VoidCallback onPin;

  const _MemoryCard({
    required this.memory,
    required this.isLast,
    required this.onForget,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final color = _emotionColor(memory.emotion);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(width: 40, child: Column(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Center(child: Text(memory.emotion.emoji, style: const TextStyle(fontSize: 14))),
          ),
          if (!isLast)
            Container(
              width: 2, height: 50,
              color: Colors.white.withValues(alpha: 0.06),
            ),
        ])),
        const SizedBox(width: 10),
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: memory.pinned ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    memory.emotion.label,
                    style: GoogleFonts.outfit(
                        color: color, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
                if (memory.pinned)
                  const Icon(Icons.push_pin_rounded, color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 4),
                Text(
                  _formatDate(memory.timestamp),
                  style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                '"${memory.text}"',
                style: GoogleFonts.outfit(
                    color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic, height: 1.5),
                maxLines: 3, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Importance bar
              Row(children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: memory.importance,
                    minHeight: 3,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(memory.importance * 10).round()}/10',
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                if (!memory.pinned)
                  _ActionBtn(
                    label: '📌 Remember Forever',
                    color: const Color(0xFFFFD700),
                    onTap: onPin,
                  ),
                const Spacer(),
                _ActionBtn(
                  label: '🗑 Forget',
                  color: Colors.red.shade300,
                  onTap: () => _confirmForget(context),
                ),
              ]),
            ]),
          ),
        ),
      ],
    );
  }

  void _confirmForget(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0E2E),
        title: Text('Forget this memory?', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('"${memory.text.length > 80 ? '${memory.text.substring(0, 80)}...' : memory.text}"',
            style: GoogleFonts.outfit(color: Colors.white54, fontStyle: FontStyle.italic)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); onForget(); },
            child: Text('Forget', style: GoogleFonts.outfit(color: Colors.red.shade300)),
          ),
        ],
      ),
    );
  }

  Color _emotionColor(MemoryEmotion e) {
    switch (e) {
      case MemoryEmotion.love:    return const Color(0xFFFF4FA8);
      case MemoryEmotion.happy:   return const Color(0xFF56D364);
      case MemoryEmotion.sad:     return const Color(0xFF79C0FF);
      case MemoryEmotion.angry:   return const Color(0xFFFF6B35);
      case MemoryEmotion.scared:  return const Color(0xFFFFD700);
      case MemoryEmotion.amused:  return const Color(0xFFBB52FF);
      case MemoryEmotion.neutral: return Colors.white38;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(label,
        style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
