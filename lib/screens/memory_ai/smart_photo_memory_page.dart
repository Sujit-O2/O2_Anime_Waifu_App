import 'package:anime_waifu/services/memory_context/smart_photo_memory_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SmartPhotoMemoryPage extends StatefulWidget {
  const SmartPhotoMemoryPage({super.key});

  @override
  State<SmartPhotoMemoryPage> createState() => _SmartPhotoMemoryPageState();
}

class _SmartPhotoMemoryPageState extends State<SmartPhotoMemoryPage>
    with SingleTickerProviderStateMixin {
  final _service = SmartPhotoMemoryService.instance;
  late final TabController _tabs;
  final _pathCtrl = TextEditingController();
  final _seedCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  MoodType? _filterMood;
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
    _pathCtrl.dispose();
    _seedCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addMemory() async {
    final seed = _seedCtrl.text.trim();
    if (_pathCtrl.text.trim().isEmpty || seed.isEmpty) return;
    HapticFeedback.mediumImpact();
    final caption = await _service.generateCaption(
        imagePath: _pathCtrl.text.trim(), aiResponse: seed);
    await _service.addMemory(
      imagePath: _pathCtrl.text.trim(),
      aiCaption: caption,
      userNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      detectedMood: _service.detectMoodFromResponse(seed),
    );
    _pathCtrl.clear();
    _seedCtrl.clear();
    _noteCtrl.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Smart Photo Memory',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: cs.onPrimary)),
        iconTheme: IconThemeData(color: cs.onPrimary),
        bottom: TabBar(
          controller: _tabs,
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onPrimary.withAlpha(153),
          indicatorColor: cs.onPrimary,
          tabs: const [
            Tab(text: 'Gallery'),
            Tab(text: 'Add'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _GalleryTab(
                  service: _service,
                  filterMood: _filterMood,
                  onFilterChanged: (m) => setState(() => _filterMood = m),
                  onRefresh: () => setState(() {}),
                ),
                _AddMemoryTab(
                  pathCtrl: _pathCtrl,
                  seedCtrl: _seedCtrl,
                  noteCtrl: _noteCtrl,
                  onAdd: _addMemory,
                ),
                _InsightsTab(service: _service),
              ],
            ),
    );
  }
}

class _GalleryTab extends StatelessWidget {
  final SmartPhotoMemoryService service;
  final MoodType? filterMood;
  final ValueChanged<MoodType?> onFilterChanged;
  final VoidCallback onRefresh;

  const _GalleryTab({
    required this.service,
    required this.filterMood,
    required this.onFilterChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final memories = filterMood == null
        ? service.getAllMemories()
        : service.getMemoriesByMood(filterMood!);

    return Column(
      children: [
        // Mood filter chips
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _FilterChip(
                label: 'All',
                selected: filterMood == null,
                onTap: () => onFilterChanged(null),
              ),
              ...MoodType.values.map((m) => _FilterChip(
                    label: '${m.emoji} ${m.label}',
                    selected: filterMood == m,
                    onTap: () => onFilterChanged(filterMood == m ? null : m),
                  )),
            ],
          ),
        ),
        Expanded(
          child: memories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No memories yet',
                          style: GoogleFonts.outfit(
                              fontSize: 18, color: Colors.grey)),
                      Text('Add your first photo memory',
                          style: GoogleFonts.outfit(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: memories.length,
                  itemBuilder: (context, index) {
                    final memory = memories[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(memory.detectedMood.emoji,
                                    style:
                                        const TextStyle(fontSize: 28)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(memory.aiCaption,
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600)),
                                  if (memory.userNote != null) ...[
                                    const SizedBox(height: 4),
                                    Text(memory.userNote!,
                                        style: GoogleFonts.outfit(
                                            color: cs.onSurface
                                                .withAlpha(153),
                                            fontSize: 12)),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(memory.timestamp),
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: cs.onSurface
                                            .withAlpha(120)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    memory.isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: memory.isFavorite
                                        ? Colors.amber
                                        : null,
                                  ),
                                  onPressed: () async {
                                    HapticFeedback.selectionClick();
                                    await service
                                        .toggleFavorite(memory.id);
                                    onRefresh();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded),
                                  onPressed: () async {
                                    HapticFeedback.mediumImpact();
                                    await service
                                        .deleteMemory(memory.id);
                                    onRefresh();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.outfit(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: cs.primaryContainer,
      ),
    );
  }
}

class _AddMemoryTab extends StatelessWidget {
  final TextEditingController pathCtrl;
  final TextEditingController seedCtrl;
  final TextEditingController noteCtrl;
  final VoidCallback onAdd;

  const _AddMemoryTab({
    required this.pathCtrl,
    required this.seedCtrl,
    required this.noteCtrl,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Photo Memory',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    'Describe the photo and its emotional context to generate an AI caption',
                    style: GoogleFonts.outfit(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: pathCtrl,
                  decoration: InputDecoration(
                    labelText: 'Photo path or identifier',
                    prefixIcon: const Icon(Icons.image_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: seedCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Describe the mood / what it feels like',
                    alignLabelWithHint: true,
                    hintText:
                        'e.g. happy, smiling, beautiful sunset, loving moment',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Personal note (optional)',
                    prefixIcon: const Icon(Icons.note_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: Text('Add Memory',
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

class _InsightsTab extends StatelessWidget {
  final SmartPhotoMemoryService service;

  const _InsightsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stats = service.getMoodStatistics();
    final total = stats.values.fold(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              service.getEmotionalInsights(),
              style: GoogleFonts.outfit(color: cs.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              service.analyzeMoodTrend(),
              style: GoogleFonts.outfit(color: cs.onSecondaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (total > 0) ...[
          Text('Mood Breakdown',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...stats.entries
              .where((e) => e.value > 0)
              .map((entry) {
            final pct = total > 0 ? entry.value / total : 0.0;
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(entry.key.emoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key.label,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600)),
                              Text('${entry.value}',
                                  style: GoogleFonts.outfit(
                                      color: cs.onSurface.withAlpha(153))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: pct,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
