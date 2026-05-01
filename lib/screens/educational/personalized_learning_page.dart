import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/educational/personalized_learning_service.dart';

class PersonalizedLearningPage extends StatefulWidget {
  const PersonalizedLearningPage({super.key});

  @override
  State<PersonalizedLearningPage> createState() =>
      _PersonalizedLearningPageState();
}

class _PersonalizedLearningPageState extends State<PersonalizedLearningPage>
    with SingleTickerProviderStateMixin {
  final _service = PersonalizedLearningService.instance;
  late TabController _tabs;
  bool _loading = true;

  // Create path form
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  SkillCategory _category = SkillCategory.programming;
  DifficultyLevel _difficulty = DifficultyLevel.beginner;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createPath() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    await _service.createLearningPath(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? 'A personalized learning journey'
          : _descCtrl.text.trim(),
      category: _category,
      difficulty: _difficulty,
      estimatedHours: _difficulty == DifficultyLevel.beginner
          ? 10
          : _difficulty == DifficultyLevel.intermediate
              ? 20
              : 40,
      topics: [_category.label],
      prerequisites: [],
    );
    _titleCtrl.clear();
    _descCtrl.clear();
    if (mounted) setState(() {});
    Navigator.pop(context);
  }

  Future<void> _generateRec() async {
    await _service.generateRecommendation(
      userId: 'user',
      category: _category,
      difficulty: _difficulty,
      interests: [_category.label],
      completedTopics: [],
    );
    if (mounted) setState(() {});
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePathSheet(
        titleCtrl: _titleCtrl,
        descCtrl: _descCtrl,
        category: _category,
        difficulty: _difficulty,
        onCategoryChanged: (v) => setState(() => _category = v),
        onDifficultyChanged: (v) => setState(() => _difficulty = v),
        onSubmit: _createPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Personalized Learning',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3949AB),
                      cs.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: Colors.white,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Paths'),
                Tab(text: 'Recommendations'),
                Tab(text: 'Sessions'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabs,
                children: [
                  _PathsTab(service: _service, onGenRec: _generateRec),
                  _RecsTab(service: _service),
                  _SessionsTab(service: _service),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.add),
        label: Text('New Path', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ── Paths Tab ──────────────────────────────────────────────────────────────
class _PathsTab extends StatelessWidget {
  const _PathsTab({required this.service, required this.onGenRec});
  final PersonalizedLearningService service;
  final VoidCallback onGenRec;

  @override
  Widget build(BuildContext context) {
    final paths = service.getPaths();
    final cs = Theme.of(context).colorScheme;
    if (paths.isEmpty) {
      return _EmptyState(
        icon: Icons.school_outlined,
        message: 'No learning paths yet.\nTap + to create your first path!',
        action: ElevatedButton.icon(
          onPressed: onGenRec,
          icon: const Icon(Icons.auto_awesome),
          label: Text('Generate Recommendation', style: GoogleFonts.outfit()),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paths.length,
      itemBuilder: (_, i) => _PathCard(path: paths[i], cs: cs),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({required this.path, required this.cs});
  final LearningPath path;
  final ColorScheme cs;

  Color get _statusColor {
    switch (path.status) {
      case PathStatus.completed:
        return Colors.green;
      case PathStatus.inProgress:
        return Colors.orange;
      case PathStatus.notStarted:
        return Colors.grey;
    }
  }

  IconData get _categoryIcon {
    switch (path.category) {
      case SkillCategory.programming:
        return Icons.code;
      case SkillCategory.dataScience:
        return Icons.bar_chart;
      case SkillCategory.design:
        return Icons.palette;
      case SkillCategory.business:
        return Icons.business_center;
      case SkillCategory.marketing:
        return Icons.campaign;
      case SkillCategory.communication:
        return Icons.chat_bubble_outline;
      case SkillCategory.leadership:
        return Icons.groups;
      case SkillCategory.creativity:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(_categoryIcon, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(path.title,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(
                          '${path.category.label} • ${path.difficulty.label} • ${path.estimatedHours}h',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    path.status.name,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: _statusColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (path.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(path.description,
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${path.progress}% complete',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: path.progress / 100,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text('${path.modules.length} modules',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
            if (path.topics.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: path.topics
                    .take(3)
                    .map((t) => Chip(
                          label: Text(t,
                              style: GoogleFonts.outfit(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Recommendations Tab ────────────────────────────────────────────────────
class _RecsTab extends StatelessWidget {
  const _RecsTab({required this.service});
  final PersonalizedLearningService service;

  @override
  Widget build(BuildContext context) {
    final recs = service.getRecommendations();
    final cs = Theme.of(context).colorScheme;
    if (recs.isEmpty) {
      return const _EmptyState(
        icon: Icons.auto_awesome_outlined,
        message: 'No recommendations yet.\nCreate a path to get started!',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recs.length,
      itemBuilder: (_, i) => _RecCard(rec: recs[i], cs: cs),
    );
  }
}

class _RecCard extends StatelessWidget {
  const _RecCard({required this.rec, required this.cs});
  final ContentRecommendation rec;
  final ColorScheme cs;

  Color get _diffColor {
    switch (rec.difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(rec.title,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _diffColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(rec.difficulty.label,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: _diffColor,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(rec.description,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${rec.estimatedTime} min',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(width: 16),
                const Icon(Icons.star_outline, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${rec.relevanceScore.toStringAsFixed(1)}/10',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const Spacer(),
                Text(rec.contentType.label,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            if (rec.learningOutcomes.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text('Learning Outcomes',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              ...rec.learningOutcomes.take(3).map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(o,
                                style: GoogleFonts.outfit(fontSize: 12))),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sessions Tab ───────────────────────────────────────────────────────────
class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.service});
  final PersonalizedLearningService service;

  @override
  Widget build(BuildContext context) {
    final sessions = service.getSessions();
    final cs = Theme.of(context).colorScheme;
    if (sessions.isEmpty) {
      return const _EmptyState(
        icon: Icons.play_circle_outline,
        message: 'No sessions yet.\nStart a recommendation to begin!',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (_, i) {
        final s = sessions[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  s.completed ? Colors.green.withAlpha(30) : cs.primaryContainer,
              child: Icon(
                s.completed ? Icons.check : Icons.play_arrow,
                color: s.completed ? Colors.green : cs.primary,
              ),
            ),
            title: Text('Session ${i + 1}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${s.progress}% • ${s.completed ? "Completed" : "In Progress"}',
              style: GoogleFonts.outfit(fontSize: 12),
            ),
            trailing: Text(
              _formatDate(s.startTime),
              style: GoogleFonts.outfit(
                  fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Create Path Bottom Sheet ───────────────────────────────────────────────
class _CreatePathSheet extends StatefulWidget {
  const _CreatePathSheet({
    required this.titleCtrl,
    required this.descCtrl,
    required this.category,
    required this.difficulty,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
    required this.onSubmit,
  });
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final SkillCategory category;
  final DifficultyLevel difficulty;
  final ValueChanged<SkillCategory> onCategoryChanged;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;
  final VoidCallback onSubmit;

  @override
  State<_CreatePathSheet> createState() => _CreatePathSheetState();
}

class _CreatePathSheetState extends State<_CreatePathSheet> {
  late SkillCategory _cat;
  late DifficultyLevel _diff;

  @override
  void initState() {
    super.initState();
    _cat = widget.category;
    _diff = widget.difficulty;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('New Learning Path',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: widget.titleCtrl,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.descCtrl,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SkillCategory>(
            value: _cat,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Category',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: SkillCategory.values
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.label, style: GoogleFonts.outfit())))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _cat = v);
                widget.onCategoryChanged(v);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DifficultyLevel>(
            value: _diff,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Difficulty',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.signal_cellular_alt),
            ),
            items: DifficultyLevel.values
                .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d.label, style: GoogleFonts.outfit())))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _diff = v);
                widget.onDifficultyChanged(v);
              }
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onSubmit,
              icon: const Icon(Icons.add),
              label: Text('Create Path', style: GoogleFonts.outfit()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: cs.onSurfaceVariant.withAlpha(100)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 15, color: cs.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
