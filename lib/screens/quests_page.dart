part of '../main.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});
  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _svc = QuestsService.instance;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _svc.addListener(_rebuild);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _svc.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  // ─── Add Custom Quest Dialog ──────────────────────────────────────────────
  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int pts = 10;
    String emoji = '🎯';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1A0D2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Create Custom Quest',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji picker row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      '🎯',
                      '💪',
                      '📚',
                      '🧹',
                      '💧',
                      '🏃',
                      '🎮',
                      '💬',
                      '🌅',
                      '🎨'
                    ]
                        .map((e) => GestureDetector(
                              onTap: () => setLocal(() => emoji = e),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: emoji == e
                                      ? Colors.pinkAccent.withValues(alpha: 0.3)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: emoji == e
                                          ? Colors.pinkAccent
                                          : Colors.transparent),
                                ),
                                child: Text(e,
                                    style: const TextStyle(fontSize: 18)),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Quest Title',
                    labelStyle: GoogleFonts.outfit(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.outfit(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text('Reward: $pts pts',
                        style: GoogleFonts.outfit(
                            color: Colors.pinkAccent, fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: pts.toDouble(),
                        min: 5,
                        max: 50,
                        divisions: 9,
                        activeColor: Colors.pinkAccent,
                        inactiveColor: Colors.white12,
                        onChanged: (v) => setLocal(() => pts = v.toInt()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.outfit(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await _svc.addCustomQuest(
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? 'Complete this custom quest.'
                      : descCtrl.text.trim(),
                  rewardPoints: pts,
                  emoji: emoji,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _tabs.animateTo(1);
              },
              child: Text('Add Quest',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final completed = _svc.dailyQuests.where((q) => q.isCompleted).length;
    final total = _svc.dailyQuests.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAILY QUESTS',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2)),
                        Text('$completed/$total done today',
                            style: GoogleFonts.outfit(
                                color: Colors.pinkAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                  // Regenerate button (AI)
                  IconButton(
                    tooltip: 'Ask AI to generate new quests',
                    onPressed: _svc.isGenerating
                        ? null
                        : () async {
                            await _svc.generateAiQuests();
                          },
                    icon: _svc.isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.pinkAccent))
                        : const Icon(Icons.auto_awesome_rounded,
                            color: Colors.pinkAccent),
                  ),
                  // Add custom quest
                  IconButton(
                    tooltip: 'Create custom quest',
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Progress bar
            if (total > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completed / total,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                  ),
                ),
              ),

            // ── Tabs ─────────────────────────────────────────────────────────
            TabBar(
              controller: _tabs,
              indicatorColor: Colors.pinkAccent,
              labelColor: Colors.pinkAccent,
              unselectedLabelColor: Colors.white38,
              labelStyle:
                  GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: '✨ Today (${_svc.dailyQuests.length})'),
                Tab(text: '🎯 My Quests (${_svc.customQuests.length})'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  // ── Daily Quests ─────────────────────────────────────────
                  _svc.isGenerating
                      ? Center(
                          child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: Colors.pinkAccent),
                            const SizedBox(height: 14),
                            Text('Zero Two is thinking of quests for you~ 💭',
                                style: GoogleFonts.outfit(
                                    color: Colors.white54, fontSize: 13)),
                          ],
                        ))
                      : _svc.dailyQuests.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('No quests yet!',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white54, fontSize: 14)),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.pinkAccent),
                                    onPressed: _svc.generateAiQuests,
                                    icon:
                                        const Icon(Icons.auto_awesome_rounded),
                                    label: Text('Generate from AI',
                                        style: GoogleFonts.outfit()),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _svc.dailyQuests.length,
                              itemBuilder: (_, i) =>
                                  _buildQuestCard(_svc.dailyQuests[i], primary),
                            ),

                  // ── Custom Quests ────────────────────────────────────────
                  _svc.customQuests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('No custom quests yet.',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white54, fontSize: 14)),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pinkAccent),
                                onPressed: _showAddDialog,
                                icon: const Icon(Icons.add),
                                label: Text('Create One',
                                    style: GoogleFonts.outfit()),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _svc.customQuests.length,
                          itemBuilder: (_, i) => _buildQuestCard(
                              _svc.customQuests[i], Colors.purpleAccent,
                              showDelete: true),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.pinkAccent,
        icon: const Icon(Icons.add),
        label: Text('Custom Quest',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ─── Quest Card ───────────────────────────────────────────────────────────

  Widget _buildQuestCard(Quest q, Color accent, {bool showDelete = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: q.isCompleted
              ? [
                  Colors.green.withValues(alpha: 0.15),
                  Colors.teal.withValues(alpha: 0.08)
                ]
              : [
                  accent.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.3)
                ],
        ),
        border: Border.all(
            color: q.isCompleted
                ? Colors.green.withValues(alpha: 0.4)
                : accent.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(q.emoji, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(
          q.title,
          style: GoogleFonts.outfit(
            color: q.isCompleted ? Colors.white38 : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            decoration: q.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(q.description,
                style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12,
                    decoration:
                        q.isCompleted ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.pinkAccent, size: 12),
                const SizedBox(width: 4),
                Text('+${q.rewardPoints} pts',
                    style: GoogleFonts.outfit(
                        color: Colors.pinkAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        trailing: showDelete
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!q.isCompleted)
                    GestureDetector(
                      onTap: () => _svc.completeQuest(q.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.pinkAccent, size: 18),
                      ),
                    ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _svc.deleteCustomQuest(q.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 18),
                    ),
                  ),
                ],
              )
            : q.isCompleted
                ? const Icon(Icons.check_circle_rounded,
                    color: Colors.greenAccent, size: 28)
                : GestureDetector(
                    onTap: () => _svc.completeQuest(q.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.pinkAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.pinkAccent, size: 20),
                    ),
                  ),
      ),
    );
  }
}
