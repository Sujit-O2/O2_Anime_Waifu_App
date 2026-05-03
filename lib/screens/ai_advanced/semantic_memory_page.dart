import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/emotional_memory_service.dart';
import 'package:anime_waifu/services/memory_context/semantic_memory_service.dart';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SemanticMemoryPage extends StatefulWidget {
  const SemanticMemoryPage({super.key});
  @override
  State<SemanticMemoryPage> createState() => _SemanticMemoryPageState();
}

class _SemanticMemoryPageState extends State<SemanticMemoryPage> {
  final _service = SemanticMemoryService.instance;
  final _ctrl = TextEditingController();
  bool _searching = false;
  bool _consolidating = false;
  String _contextBlock = '';
  Map<String, int> _topicFreq = {};
  String _summary = '';
  int _memoryCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final freq = await _service.getMemoryTopicFrequency();
    final summary = await _service.getPersonalitySummary();
    final mems = await EmotionalMemoryService.instance.getAllMemories();
    if (mounted) setState(() { _topicFreq = freq; _summary = summary; _memoryCount = mems.length; _loading = false; });
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _searching = true);
    final block = await _service.buildSemanticContextBlock(currentMessage: q);
    if (mounted) setState(() { _contextBlock = block; _searching = false; });
  }

  Future<void> _consolidate() async {
    HapticFeedback.mediumImpact();
    setState(() => _consolidating = true);
    await _service.consolidateMemories();
    await _loadData();
    if (mounted) {
      setState(() => _consolidating = false);
      showSuccessSnackbar(context, 'Memory consolidation complete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;
    final maxFreq = _topicFreq.isEmpty ? 1 : _topicFreq.values.fold(0, (a, b) => a > b ? a : b);

    return FeaturePageV2(
      title: 'SEMANTIC MEMORY',
      subtitle: '$_memoryCount memories indexed',
      onBack: () => Navigator.pop(context),
      actions: [
        GestureDetector(
          onTap: _loadData,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: tokens.panelMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: tokens.outlineStrong)),
            child: Icon(Icons.refresh_rounded, color: tokens.textMuted, size: 18),
          ),
        ),
      ],
      content: _loading
          ? const PremiumLoadingState(label: 'Indexing memories…', icon: Icons.search_rounded)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Hero ──────────────────────────────────────────────────
                AnimatedEntry(
                  index: 0,
                  child: GlassCard(
                    margin: EdgeInsets.zero,
                    glow: true,
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Semantic search', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('$_memoryCount memories indexed', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(_summary.isNotEmpty ? _summary : 'Type a message below to find the most relevant memories using semantic scoring.', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                      const SizedBox(width: 16),
                      ProgressRing(
                        progress: (_memoryCount / 80).clamp(0.0, 1.0),
                        foreground: primary,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🔍', style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text('$_memoryCount', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('Indexed', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 10)),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stats ─────────────────────────────────────────────────
                AnimatedEntry(
                  index: 1,
                  child: Row(children: [
                    Expanded(child: StatCard(title: 'Memories', value: '$_memoryCount', icon: Icons.memory_rounded, color: primary)),
                    Expanded(child: StatCard(title: 'Topics', value: '${_topicFreq.length}', icon: Icons.label_rounded, color: Colors.purpleAccent)),
                    Expanded(child: StatCard(title: 'Top Topic', value: _topicFreq.isEmpty ? '--' : _topicFreq.entries.reduce((a, b) => a.value > b.value ? a : b).key, icon: Icons.star_rounded, color: Colors.amberAccent)),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Search ────────────────────────────────────────────────
                AnimatedEntry(
                  index: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SEMANTIC SEARCH', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    GlassCard(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        TextField(
                          controller: _ctrl,
                          style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 13),
                          cursorColor: primary,
                          onSubmitted: (_) => _search(),
                          decoration: InputDecoration(
                            hintText: 'e.g. "I miss you so much"',
                            hintStyle: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12),
                            suffixIcon: IconButton(icon: Icon(Icons.search_rounded, color: primary), onPressed: _search),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        if (_searching) ...[
                          const SizedBox(height: 10),
                          LinearProgressIndicator(color: primary, backgroundColor: tokens.outline),
                        ],
                        if (_contextBlock.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: primary.withValues(alpha: 0.2))),
                            child: Text(
                              _contextBlock.replaceAll('// [Semantic Memory Context', '').replaceAll(']:', '').trim(),
                              style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.5),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ]),
                ),

                // ── Topic frequency ───────────────────────────────────────
                if (_topicFreq.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AnimatedEntry(
                    index: 3,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('MEMORY TOPICS', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      GlassCard(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: _topicFreq.entries.take(8).toList().asMap().entries.map((entry) {
                            final e = entry.value;
                            final ratio = maxFreq > 0 ? e.value / maxFreq : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                SizedBox(width: 80, child: Text(e.key, style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12))),
                                Expanded(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
                                    duration: Duration(milliseconds: 500 + entry.key * 60),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, v, __) => ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(value: v, backgroundColor: tokens.outline, valueColor: AlwaysStoppedAnimation(primary), minHeight: 7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${e.value}', style: GoogleFonts.outfit(color: primary, fontSize: 11, fontWeight: FontWeight.w700)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
                  ),
                ],

                // ── Consolidate ───────────────────────────────────────────
                const SizedBox(height: 16),
                AnimatedEntry(
                  index: 4,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _consolidating ? null : _consolidate,
                      icon: _consolidating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.compress_rounded, size: 18),
                      label: Text(_consolidating ? 'Consolidating…' : 'Consolidate Memories', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
