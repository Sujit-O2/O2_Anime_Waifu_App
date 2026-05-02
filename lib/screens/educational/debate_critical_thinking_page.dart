import 'package:anime_waifu/services/educational/debate_critical_thinking_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DebateCriticalThinkingPage extends StatefulWidget {
  const DebateCriticalThinkingPage({super.key});

  @override
  State<DebateCriticalThinkingPage> createState() =>
      _DebateCriticalThinkingPageState();
}

class _DebateCriticalThinkingPageState
    extends State<DebateCriticalThinkingPage>
    with SingleTickerProviderStateMixin {
  final _service = DebateCriticalThinkingService.instance;
  late final TabController _tabs;
  final _topicCtrl = TextEditingController();
  final _claimCtrl = TextEditingController();
  final _reasoningCtrl = TextEditingController();
  DebateCategory _category = DebateCategory.technology;
  DifficultyLevel _difficulty = DifficultyLevel.intermediate;
  DebateTopic? _selectedTopic;
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
    _topicCtrl.dispose();
    _claimCtrl.dispose();
    _reasoningCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) {
      setState(() {
        _loading = false;
        final topics = _service.getTopics();
        if (topics.isNotEmpty) _selectedTopic = topics.first;
      });
    }
  }

  Future<void> _createTopic() async {
    if (_topicCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final topic = await _service.createDebateTopic(
      title: _topicCtrl.text.trim(),
      description: 'Practice debate topic',
      category: _category,
      difficulty: _difficulty,
      position: 'For',
      keyPoints: const ['Define terms', 'Use evidence', 'Address objections'],
    );
    _topicCtrl.clear();
    if (mounted) setState(() => _selectedTopic = topic);
  }

  Future<void> _addArgument() async {
    final topics = _service.getTopics();
    final topic = _selectedTopic ?? (topics.isEmpty ? null : topics.first);
    if (topic == null || _claimCtrl.text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    await _service.addArgument(
      topicId: topic.id,
      claim: _claimCtrl.text.trim(),
      evidence: const ['Supporting evidence'],
      reasoning: _reasoningCtrl.text.trim(),
      type: ArgumentType.supporting,
      confidence: 0.7,
    );
    _claimCtrl.clear();
    _reasoningCtrl.clear();
    if (mounted) setState(() => _selectedTopic = topic);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topics = _service.getTopics();
    final topic = _selectedTopic ?? (topics.isEmpty ? null : topics.first);
    final arguments =
        topic == null ? <Argument>[] : _service.getArguments(topicId: topic.id);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.error, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Debate & Critical Thinking',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: cs.onError)),
        iconTheme: IconThemeData(color: cs.onError),
        bottom: TabBar(
          controller: _tabs,
          labelColor: cs.onError,
          unselectedLabelColor: cs.onError.withAlpha(153),
          indicatorColor: cs.onError,
          tabs: const [
            Tab(text: 'Topics'),
            Tab(text: 'Argue'),
            Tab(text: 'Tips'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _TopicsTab(
                  topics: topics,
                  selected: topic,
                  category: _category,
                  difficulty: _difficulty,
                  topicCtrl: _topicCtrl,
                  onCategoryChanged: (c) => setState(() => _category = c),
                  onDifficultyChanged: (d) => setState(() => _difficulty = d),
                  onTopicSelected: (t) => setState(() => _selectedTopic = t),
                  onCreate: _createTopic,
                  service: _service,
                ),
                _ArgumentsTab(
                  topic: topic,
                  arguments: arguments,
                  claimCtrl: _claimCtrl,
                  reasoningCtrl: _reasoningCtrl,
                  onAdd: _addArgument,
                  service: _service,
                ),
                _TipsTab(service: _service),
              ],
            ),
    );
  }
}

class _TopicsTab extends StatelessWidget {
  final List<DebateTopic> topics;
  final DebateTopic? selected;
  final DebateCategory category;
  final DifficultyLevel difficulty;
  final TextEditingController topicCtrl;
  final ValueChanged<DebateCategory> onCategoryChanged;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;
  final ValueChanged<DebateTopic> onTopicSelected;
  final VoidCallback onCreate;
  final DebateCriticalThinkingService service;

  const _TopicsTab({
    required this.topics,
    required this.selected,
    required this.category,
    required this.difficulty,
    required this.topicCtrl,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
    required this.onTopicSelected,
    required this.onCreate,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              service.getDebateInsights(),
              style: GoogleFonts.outfit(color: cs.onErrorContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Debate Topic',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: topicCtrl,
                  decoration: InputDecoration(
                    labelText: 'Topic statement',
                    hintText: 'e.g. AI will replace most jobs by 2040',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<DebateCategory>(
                        value: category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: DebateCategory.values
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.label,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onCategoryChanged(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<DifficultyLevel>(
                        value: difficulty,
                        decoration: InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: DifficultyLevel.values
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d.name),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onDifficultyChanged(v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Create Topic',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (topics.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.forum_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No topics yet',
                      style: GoogleFonts.outfit(
                          fontSize: 16, color: Colors.grey)),
                  Text('Create a debate topic to start practicing',
                      style: GoogleFonts.outfit(color: Colors.grey)),
                ],
              ),
            ),
          )
        else ...[
          Text('Your Topics',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...topics.map((t) {
            final isSelected = selected?.id == t.id;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isSelected
                    ? BorderSide(color: cs.error, width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTopicSelected(t);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(t.title,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: cs.error),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _Tag(t.category.label),
                          _Tag(t.difficulty.name),
                          _Tag('${t.arguments.length} args'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.outfit(
              fontSize: 11, color: cs.onSurface.withAlpha(180))),
    );
  }
}

class _ArgumentsTab extends StatelessWidget {
  final DebateTopic? topic;
  final List<Argument> arguments;
  final TextEditingController claimCtrl;
  final TextEditingController reasoningCtrl;
  final VoidCallback onAdd;
  final DebateCriticalThinkingService service;

  const _ArgumentsTab({
    required this.topic,
    required this.arguments,
    required this.claimCtrl,
    required this.reasoningCtrl,
    required this.onAdd,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (topic == null)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: cs.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Select a topic first',
                        style: GoogleFonts.outfit(
                            color: cs.onErrorContainer)),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.forum_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(topic!.title,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Build an Argument',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: claimCtrl,
                  decoration: InputDecoration(
                    labelText: 'Your claim',
                    hintText: 'State your position clearly',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasoningCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Reasoning & evidence',
                    alignLabelWithHint: true,
                    hintText: 'Explain why your claim is valid',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: topic != null ? onAdd : null,
                    icon: const Icon(Icons.fact_check_rounded),
                    label: Text('Analyze Argument',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (arguments.isNotEmpty) ...[
          Text('Arguments (${arguments.length})',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...arguments.map((arg) => _ArgumentCard(
                argument: arg,
                service: service,
              )),
        ],
      ],
    );
  }
}

class _ArgumentCard extends StatefulWidget {
  final Argument argument;
  final DebateCriticalThinkingService service;

  const _ArgumentCard({required this.argument, required this.service});

  @override
  State<_ArgumentCard> createState() => _ArgumentCardState();
}

class _ArgumentCardState extends State<_ArgumentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final validity = widget.argument.logicalValidity;
    final color = validity >= 7
        ? Colors.green
        : validity >= 5
            ? Colors.orange
            : Colors.red;

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _expanded = !_expanded);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.argument.claim,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                        '${validity.toStringAsFixed(1)}/10',
                        style: GoogleFonts.outfit(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: cs.onSurface.withAlpha(153),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  widget.service.getArgumentFeedback(widget.argument.id),
                  style: GoogleFonts.outfit(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TipsTab extends StatelessWidget {
  final DebateCriticalThinkingService service;

  const _TipsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tips = service.getCriticalThinkingTips();
    final lines = tips.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    lines.isNotEmpty ? lines.first : 'Tips',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.onTertiaryContainer)),
                const SizedBox(height: 12),
                ...lines.skip(1).map((line) {
                  final tip = line.startsWith('• ')
                      ? line.substring(2)
                      : line;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.psychology_outlined,
                            size: 18,
                            color:
                                cs.onTertiaryContainer.withAlpha(180)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tip,
                              style: GoogleFonts.outfit(
                                  color: cs.onTertiaryContainer)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
