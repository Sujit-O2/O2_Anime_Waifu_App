import 'package:anime_waifu/services/creative/game_master_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameMasterPage extends StatefulWidget {
  const GameMasterPage({super.key});

  @override
  State<GameMasterPage> createState() => _GameMasterPageState();
}

class _GameMasterPageState extends State<GameMasterPage>
    with SingleTickerProviderStateMixin {
  final _service = GameMasterService.instance;
  late TabController _tabs;
  bool _loading = true;
  String _encounter = '';

  final _titleCtrl = TextEditingController();
  final _settingCtrl = TextEditingController(text: 'Frontier city');
  RPGGenre _genre = RPGGenre.fantasy;
  DifficultyLevel _difficulty = DifficultyLevel.medium;

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
    _settingCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createCampaign() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    await _service.createCampaign(
      title: _titleCtrl.text.trim(),
      genre: _genre,
      description: 'Campaign from GM dashboard',
      setting: _settingCtrl.text.trim().isEmpty
          ? 'Frontier city'
          : _settingCtrl.text.trim(),
      playerCount: 4,
      difficulty: _difficulty,
    );
    _titleCtrl.clear();
    if (mounted) {
      setState(() {});
      Navigator.pop(context);
    }
  }

  void _generateEncounter() {
    setState(() {
      _encounter = _service.generateRandomEncounter(
        genre: _genre,
        difficulty: _difficulty,
      );
    });
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateCampaignSheet(
        titleCtrl: _titleCtrl,
        settingCtrl: _settingCtrl,
        genre: _genre,
        difficulty: _difficulty,
        onGenreChanged: (v) => setState(() => _genre = v),
        onDifficultyChanged: (v) => setState(() => _difficulty = v),
        onSubmit: _createCampaign,
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
              title: Text('Game Master',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4E342E), Color(0xFF795548)],
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
                Tab(text: 'Campaigns'),
                Tab(text: 'Encounter'),
                Tab(text: 'GM Tips'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabs,
                children: [
                  _CampaignsTab(service: _service, cs: cs),
                  _EncounterTab(
                    service: _service,
                    genre: _genre,
                    difficulty: _difficulty,
                    encounter: _encounter,
                    onGenreChanged: (v) => setState(() => _genre = v),
                    onDifficultyChanged: (v) =>
                        setState(() => _difficulty = v),
                    onGenerate: _generateEncounter,
                    cs: cs,
                  ),
                  _GMTipsTab(service: _service, cs: cs),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.flag),
        label: Text('New Campaign', style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF4E342E),
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ── Campaigns Tab ──────────────────────────────────────────────────────────
class _CampaignsTab extends StatelessWidget {
  const _CampaignsTab({required this.service, required this.cs});
  final GameMasterService service;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final campaigns = service.getCampaigns();
    if (campaigns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.castle_outlined,
                  size: 64, color: cs.onSurfaceVariant.withAlpha(80)),
              const SizedBox(height: 16),
              Text('No campaigns yet',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Tap + to create your first D&D campaign!',
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
      itemCount: campaigns.length,
      itemBuilder: (_, i) {
        final c = campaigns[i];
        return _CampaignCard(campaign: c, cs: cs, service: service);
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard(
      {required this.campaign, required this.cs, required this.service});
  final RPGCampaign campaign;
  final ColorScheme cs;
  final GameMasterService service;

  Color get _statusColor {
    switch (campaign.status) {
      case CampaignStatus.inProgress:
        return Colors.green;
      case CampaignStatus.completed:
        return Colors.blue;
      case CampaignStatus.onHold:
        return Colors.orange;
      case CampaignStatus.planning:
        return Colors.grey;
    }
  }

  IconData get _genreIcon {
    switch (campaign.genre) {
      case RPGGenre.fantasy:
        return Icons.auto_fix_high;
      case RPGGenre.scifi:
        return Icons.rocket_launch;
      case RPGGenre.horror:
        return Icons.nightlight;
      case RPGGenre.mystery:
        return Icons.search;
      case RPGGenre.superhero:
        return Icons.bolt;
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
                  backgroundColor: const Color(0xFF4E342E).withAlpha(30),
                  child: Icon(_genreIcon,
                      color: const Color(0xFF4E342E), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(campaign.title,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(
                          '${campaign.genre.name} • ${campaign.setting} • ${campaign.playerCount} players',
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
                  child: Text(campaign.status.name,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: _statusColor,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatChip(
                    icon: Icons.people_outline,
                    label: '${campaign.npcs.length} NPCs'),
                const SizedBox(width: 8),
                _StatChip(
                    icon: Icons.psychology_outlined,
                    label: '${campaign.plotTwists.length} Twists'),
                const SizedBox(width: 8),
                _StatChip(
                    icon: Icons.map_outlined,
                    label: '${campaign.worldElements.length} Lore'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              service.getCampaignIdeas(
                genre: campaign.genre,
                difficulty: campaign.difficulty,
                playerCount: campaign.playerCount,
              ).split('\n').take(2).join('\n'),
              style: GoogleFonts.outfit(
                  fontSize: 12, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Encounter Tab ──────────────────────────────────────────────────────────
class _EncounterTab extends StatelessWidget {
  const _EncounterTab({
    required this.service,
    required this.genre,
    required this.difficulty,
    required this.encounter,
    required this.onGenreChanged,
    required this.onDifficultyChanged,
    required this.onGenerate,
    required this.cs,
  });
  final GameMasterService service;
  final RPGGenre genre;
  final DifficultyLevel difficulty;
  final String encounter;
  final ValueChanged<RPGGenre> onGenreChanged;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;
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
                Text('Random Encounter Generator',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                DropdownButtonFormField<RPGGenre>(
                  value: genre,
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    labelText: 'Genre',
                    labelStyle: GoogleFonts.outfit(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: RPGGenre.values
                      .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.name, style: GoogleFonts.outfit())))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onGenreChanged(v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DifficultyLevel>(
                  value: difficulty,
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
                          child: Text(d.name, style: GoogleFonts.outfit())))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onDifficultyChanged(v);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.casino),
                    label: Text('Roll Encounter', style: GoogleFonts.outfit()),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4E342E)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (encounter.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF4E342E).withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield,
                          color: Color(0xFF4E342E), size: 18),
                      const SizedBox(width: 8),
                      Text('Encounter',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4E342E))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(encounter,
                      style: GoogleFonts.outfit(fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── GM Tips Tab ────────────────────────────────────────────────────────────
class _GMTipsTab extends StatelessWidget {
  const _GMTipsTab({required this.service, required this.cs});
  final GameMasterService service;
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
                Text('GM Insights',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(service.getCampaignInsights(),
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GM Advice',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(service.getGMAdvice(),
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Create Campaign Sheet ──────────────────────────────────────────────────
class _CreateCampaignSheet extends StatefulWidget {
  const _CreateCampaignSheet({
    required this.titleCtrl,
    required this.settingCtrl,
    required this.genre,
    required this.difficulty,
    required this.onGenreChanged,
    required this.onDifficultyChanged,
    required this.onSubmit,
  });
  final TextEditingController titleCtrl;
  final TextEditingController settingCtrl;
  final RPGGenre genre;
  final DifficultyLevel difficulty;
  final ValueChanged<RPGGenre> onGenreChanged;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;
  final VoidCallback onSubmit;

  @override
  State<_CreateCampaignSheet> createState() => _CreateCampaignSheetState();
}

class _CreateCampaignSheetState extends State<_CreateCampaignSheet> {
  late RPGGenre _genre;
  late DifficultyLevel _diff;

  @override
  void initState() {
    super.initState();
    _genre = widget.genre;
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('New Campaign',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: widget.titleCtrl,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Campaign Title',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.flag_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.settingCtrl,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Setting',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.map_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<RPGGenre>(
            value: _genre,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: 'Genre',
              labelStyle: GoogleFonts.outfit(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: RPGGenre.values
                .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g.name, style: GoogleFonts.outfit())))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _genre = v);
                widget.onGenreChanged(v);
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
                    child: Text(d.name, style: GoogleFonts.outfit())))
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
              label: Text('Create Campaign', style: GoogleFonts.outfit()),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4E342E)),
            ),
          ),
        ],
      ),
    );
  }
}
