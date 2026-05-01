import 'package:anime_waifu/services/creative/collaborative_storytelling_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CollaborativeStorytellingPage extends StatefulWidget {
  const CollaborativeStorytellingPage({super.key});

  @override
  State<CollaborativeStorytellingPage> createState() =>
      _CollaborativeStorytellingPageState();
}

class _CollaborativeStorytellingPageState
    extends State<CollaborativeStorytellingPage>
    with SingleTickerProviderStateMixin {
  final _service = CollaborativeStorytellingService.instance;
  late TabController _tabs;
  bool _loading = true;
  String _prompt = '';

  final _titleCtrl = TextEditingController();
  final _genreCtrl = TextEditingController(text: 'romance fantasy');
  StoryFormat _format = StoryFormat.novel;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _genreCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createProject() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    await _service.createStoryProject(
      title: _titleCtrl.text.trim(),
      genre: _genreCtrl.text.trim().isEmpty ? 'fantasy' : _genreCtrl.text.trim(),
      description: 'Collaborative story',
      format: _format,
      targetChapters: 8,
    );
    _titleCtrl.clear();
    if (mounted) {
      setState(() {});
      Navigator.pop(context);
    }
  }

  void _generatePrompt() {
    setState(() => _prompt = _service.getWritingPrompts(
          _genreCtrl.text.trim().isEmpty ? 'fantasy' : _genreCtrl.text.trim(),
        ));
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateStorySheet(
        titleCtrl: _titleCtrl,
        genreCtrl: _genreCtrl,
        format: _format,
        onFormatChanged: (v) => setState(() => _format = v),
        onSubmit: _createProject,
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
              title: Text('Collaborative Storytelling',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4527A0), Color(0xFF7B1FA2)],
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
              tabs: const [Tab(text: 'Stories'), Tab(text: 'Prompts')],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabs,
                children: [
                  _StoriesTab(service: _service, cs: cs),
                  _PromptsTab(
                    service: _service,
                    genreCtrl: _genreCtrl,
                    prompt: _prompt,
                    onGenerate: _generatePrompt,
                    cs: cs,
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.auto_stories),
        label: Text('New Story', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF4527A0),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _StoriesTab extends StatelessWidget {
  const _StoriesTab({required this.service, required this.cs});
  final CollaborativeStorytellingService service;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final projects = service.getProjects();
    if (projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 64, color: cs.onSurfaceVariant.withAlpha(80)),
              const SizedBox(height: 16),
              Text('No stories yet',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Tap + to start your first collaborative story!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (_, i) {
        final p = projects[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4527A0).withAlpha(30),
              child: const Icon(Icons.auto_stories,
                  color: Color(0xFF4527A0), size: 20),
            ),
            title: Text(p.title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${p.genre} • Chapter ${p.currentChapter} • ${p.format.name}',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: cs.onSurfaceVariant),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text('Story Suggestions',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      service.getStorySuggestions(p.id),
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromptsTab extends StatelessWidget {
  const _PromptsTab({
    required this.service,
    required this.genreCtrl,
    required this.prompt,
    required this.onGenerate,
    required this.cs,
  });
  final CollaborativeStorytellingService service;
  final TextEditingController genreCtrl;
  final String prompt;
  final VoidCallback onGenerate;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Writing Prompt Generator',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: genreCtrl,
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    labelText: 'Genre',
                    labelStyle: GoogleFonts.outfit(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category_outlined),
                    hintText: 'e.g. romance fantasy, sci-fi thriller',
                    hintStyle: GoogleFonts.outfit(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.edit_note),
                    label: Text('Generate Prompt', style: GoogleFonts.outfit()),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4527A0)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (prompt.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF4527A0).withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: Color(0xFF4527A0), size: 18),
                      const SizedBox(width: 8),
                      Text('Writing Prompt',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4527A0))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(prompt,
                      style: GoogleFonts.outfit(
                          fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Story Insights',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(service.getStoryInsights(),
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: cs.onSurfaceVariant, height: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateStorySheet extends StatefulWidget {
  const _CreateStorySheet({
    required this.titleCtrl,
    required this.genreCtrl,
    required this.format,
    required this.onFormatChanged,
    required this.onSubmit,
  });
  final TextEditingController titleCtrl;
  final TextEditingController genreCtrl;
  final StoryFormat format;
  final ValueChanged<StoryFormat> onFormatChanged;
  final VoidCallback onSubmit;

  @override
  State<_CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends State<_CreateStorySheet> {
  late StoryFormat _fmt;

  @override
  void initState() {
    super.initState();
    _fmt = widget.format;
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('New Story Project',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: widget.titleCtrl,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Story Title',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.genreCtrl,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Genre',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<StoryFormat>(
            value: _fmt,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Format',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.format_list_bulleted),
            ),
            items: StoryFormat.values
                .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.name, style: GoogleFonts.outfit())))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _fmt = v);
                widget.onFormatChanged(v);
              }
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onSubmit,
              icon: const Icon(Icons.add),
              label: Text('Create Story', style: GoogleFonts.outfit()),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4527A0)),
            ),
          ),
        ],
      ),
    );
  }
}
