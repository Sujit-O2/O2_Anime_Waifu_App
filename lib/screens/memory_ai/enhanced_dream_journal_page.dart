import 'package:anime_waifu/services/ai_personalization/enhanced_dream_journal_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EnhancedDreamJournalPage extends StatefulWidget {
  const EnhancedDreamJournalPage({super.key});

  @override
  State<EnhancedDreamJournalPage> createState() =>
      _EnhancedDreamJournalPageState();
}

class _EnhancedDreamJournalPageState extends State<EnhancedDreamJournalPage>
    with SingleTickerProviderStateMixin {
  final _service = EnhancedDreamJournalService.instance;
  late final TabController _tabs;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  DreamMood _mood = DreamMood.neutral;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveDream() async {
    if (_descCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    await _service.addDream(
      title: _titleCtrl.text.trim().isEmpty
          ? 'Untitled Dream'
          : _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      mood: _mood,
      tags: _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    );
    _titleCtrl.clear();
    _descCtrl.clear();
    _tagsCtrl.clear();
    if (mounted) setState(() => _mood = DreamMood.neutral);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1A1A4E), cs.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Dream Journal',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Record'),
            Tab(text: 'Dreams'),
            Tab(text: 'Patterns'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _RecordTab(
                  titleCtrl: _titleCtrl,
                  descCtrl: _descCtrl,
                  tagsCtrl: _tagsCtrl,
                  mood: _mood,
                  onMoodChanged: (m) => setState(() => _mood = m),
                  onSave: _saveDream,
                ),
                _DreamsTab(service: _service, onRefresh: () => setState(() {})),
                _PatternsTab(service: _service),
              ],
            ),
    );
  }
}

class _RecordTab extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController tagsCtrl;
  final DreamMood mood;
  final ValueChanged<DreamMood> onMoodChanged;
  final VoidCallback onSave;

  const _RecordTab({
    required this.titleCtrl,
    required this.descCtrl,
    required this.tagsCtrl,
    required this.mood,
    required this.onMoodChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mood selector
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dream Mood',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DreamMood.values.map((m) {
                    final selected = mood == m;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onMoodChanged(m);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primaryContainer
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? Border.all(color: cs.primary, width: 2)
                              : null,
                        ),
                        child: Text('${m.emoji} ${m.label}',
                            style: GoogleFonts.outfit(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected
                                    ? cs.onPrimaryContainer
                                    : cs.onSurface)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Entry form
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record Your Dream',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dream title',
                    prefixIcon: const Icon(Icons.bedtime_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  minLines: 4,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: 'What happened in your dream?',
                    alignLabelWithHint: true,
                    hintText:
                        'Describe the events, people, places, and feelings...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'flying, school, family',
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_rounded),
                    label: Text('Save Dream',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DreamsTab extends StatelessWidget {
  final EnhancedDreamJournalService service;
  final VoidCallback onRefresh;

  const _DreamsTab({required this.service, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dreams = service.getAllDreams();

    if (dreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌙', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text('No dreams recorded yet',
                style: GoogleFonts.outfit(
                    fontSize: 18, color: Colors.grey)),
            Text('Record your first dream to start finding patterns',
                style: GoogleFonts.outfit(color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dreams.length,
      itemBuilder: (context, index) {
        final dream = dreams[index];
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(dream.mood.emoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dream.title,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(
                            _formatDate(dream.timestamp),
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: cs.onSurface.withAlpha(120)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        await service.deleteDream(dream.id);
                        onRefresh();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dream.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      color: cs.onSurface.withAlpha(180)),
                ),
                if (dream.symbols.isNotEmpty || dream.themes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...dream.symbols.map((s) => _Tag(s, cs.primaryContainer,
                          cs.onPrimaryContainer)),
                      ...dream.themes.map((t) => _Tag(t,
                          cs.secondaryContainer, cs.onSecondaryContainer)),
                    ],
                  ),
                ],
                if (dream.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: dream.tags
                        .map((t) => _Tag(
                            t,
                            cs.surfaceContainerHighest,
                            cs.onSurface.withAlpha(180)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _Tag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Tag(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.outfit(fontSize: 11, color: fg)),
    );
  }
}

class _PatternsTab extends StatelessWidget {
  final EnhancedDreamJournalService service;

  const _PatternsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final patterns = service.getRecurringPatterns();
    final recentDreams =
        service.getDreamsInPeriod(const Duration(days: 7));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF1A1A4E),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              service.getPatternInsights(),
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Recent week stats
        if (recentDreams.isNotEmpty) ...[
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This Week',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: cs.onSecondaryContainer)),
                      Text('${recentDreams.length} dreams recorded',
                          style: GoogleFonts.outfit(
                              color: cs.onSecondaryContainer
                                  .withAlpha(180))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (patterns.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No patterns yet',
                      style: GoogleFonts.outfit(
                          fontSize: 16, color: Colors.grey)),
                  Text(
                      'Record at least 2 dreams with similar themes to detect patterns',
                      style: GoogleFonts.outfit(color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else ...[
          Text('Recurring Patterns',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...patterns.map((pattern) {
            final isSymbol = pattern.type == PatternType.symbol;
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSymbol
                      ? cs.primaryContainer
                      : cs.secondaryContainer,
                  child: Text(
                    isSymbol ? '🔮' : '🎭',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                title: Text(pattern.name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        textStyle: const TextStyle(
                            textBaseline: TextBaseline.alphabetic))),
                subtitle: Text(
                    '${isSymbol ? 'Symbol' : 'Theme'} • ${pattern.occurrences} appearances',
                    style: GoogleFonts.outfit(fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('×${pattern.occurrences}',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer)),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
