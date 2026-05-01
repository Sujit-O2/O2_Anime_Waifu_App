import 'package:anime_waifu/services/memory_context/semantic_memory_service.dart';
import 'package:anime_waifu/services/ai_personalization/emotional_memory_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SemanticMemoryPage extends StatefulWidget {
  const SemanticMemoryPage({super.key});

  @override
  State<SemanticMemoryPage> createState() => _SemanticMemoryPageState();
}

class _SemanticMemoryPageState extends State<SemanticMemoryPage> {
  final _service = SemanticMemoryService.instance;
  final _controller = TextEditingController();
  bool _loading = false;
  bool _consolidating = false;
  String _contextBlock = '';
  Map<String, int> _topicFreq = {};
  String _summary = '';
  List<EmotionalMemory> _allMemories = [];
  bool _loadingMemories = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loadingMemories = true);
    final freq = await _service.getMemoryTopicFrequency();
    final summary = await _service.getPersonalitySummary();
    final mems = await EmotionalMemoryService.instance.getAllMemories();
    if (mounted) {
      setState(() {
        _topicFreq = freq;
        _summary = summary;
        _allMemories = mems;
        _loadingMemories = false;
      });
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    final block = await _service.buildSemanticContextBlock(
      currentMessage: query,
    );
    if (mounted) {
      setState(() {
        _contextBlock = block;
        _loading = false;
      });
    }
  }

  Future<void> _consolidate() async {
    HapticFeedback.mediumImpact();
    setState(() => _consolidating = true);
    await _service.consolidateMemories();
    await _loadData();
    if (mounted) {
      setState(() => _consolidating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory consolidation complete'),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        title: Text('🔍 Semantic Memory',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loadingMemories
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats
                Row(children: [
                  _statPill('${_allMemories.length}', 'Memories',
                      Colors.deepPurple),
                  const SizedBox(width: 8),
                  _statPill('${_topicFreq.length}', 'Topics',
                      Colors.purpleAccent),
                ]),
                const SizedBox(height: 16),

                // Summary
                if (_summary.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.deepPurple.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🧠', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_summary,
                              style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Search
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.deepPurple.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Semantic Search',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                          'Type a message to find the most relevant memories.',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controller,
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. "I miss you so much"',
                          hintStyle: GoogleFonts.outfit(
                              color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          isDense: true,
                          contentPadding: const EdgeInsets.all(10),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search_rounded,
                                color: Colors.deepPurple),
                            onPressed: _search,
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                      if (_loading) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(
                            color: Colors.deepPurple),
                      ],
                      if (_contextBlock.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.deepPurple.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            _contextBlock
                                .replaceAll('// [Semantic Memory Context', '')
                                .replaceAll(']:',
                                    '')
                                .trim(),
                            style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Topic frequency
                if (_topicFreq.isNotEmpty) ...[
                  Text('Memory Topics',
                      style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: _topicFreq.entries.take(8).map((e) {
                        final maxVal = _topicFreq.values
                            .fold(0, (a, b) => a > b ? a : b);
                        final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            SizedBox(
                                width: 90,
                                child: Text(e.key,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 12))),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio.toDouble(),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.07),
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                          Colors.deepPurple),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${e.value}',
                                style: GoogleFonts.outfit(
                                    color: Colors.deepPurple.shade200,
                                    fontSize: 11)),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Consolidate button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _consolidating ? null : _consolidate,
                    icon: _consolidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.deepPurple))
                        : const Icon(Icons.compress_rounded, size: 18),
                    label: Text(
                        _consolidating
                            ? 'Consolidating...'
                            : 'Consolidate Memories',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple.shade200,
                      side: BorderSide(
                          color: Colors.deepPurple.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
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
