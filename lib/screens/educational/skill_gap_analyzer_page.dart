import 'package:anime_waifu/services/educational/skill_gap_analyzer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SkillGapAnalyzerPage extends StatefulWidget {
  const SkillGapAnalyzerPage({super.key});

  @override
  State<SkillGapAnalyzerPage> createState() => _SkillGapAnalyzerPageState();
}

class _SkillGapAnalyzerPageState extends State<SkillGapAnalyzerPage>
    with SingleTickerProviderStateMixin {
  final _service = SkillGapAnalyzerService.instance;
  late final TabController _tabs;
  final _titleCtrl = TextEditingController();
  SkillArea _skill = SkillArea.communication;
  double _score = 5;
  SkillAssessment? _active;
  bool _loading = true;

  static const _priorityColor = {
    GapPriority.critical: Colors.red,
    GapPriority.high: Colors.orange,
    GapPriority.medium: Colors.amber,
    GapPriority.low: Colors.green,
  };

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
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) {
      setState(() {
        _loading = false;
        final assessments = _service.getAssessments();
        if (assessments.isNotEmpty) _active = assessments.first;
      });
    }
  }

  Future<void> _createAssessment() async {
    HapticFeedback.mediumImpact();
    final assessment = await _service.createAssessment(
      title: _titleCtrl.text.trim().isEmpty
          ? 'Skill Check'
          : _titleCtrl.text.trim(),
      description: 'Self assessment',
      skillAreas: SkillArea.values,
      type: AssessmentType.selfAssessment,
    );
    _titleCtrl.clear();
    if (mounted) setState(() => _active = assessment);
  }

  Future<void> _scoreSkill() async {
    final assessment = _active ??
        (_service.getAssessments().isEmpty
            ? null
            : _service.getAssessments().first);
    if (assessment == null) return;
    HapticFeedback.selectionClick();
    await _service.addSkillScore(
      assessmentId: assessment.id,
      skillArea: _skill.label,
      score: _score,
      notes: 'Scored from analyzer',
    );
    if (mounted) setState(() => _active = assessment);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assessments = _service.getAssessments();
    final active = _active ?? (assessments.isEmpty ? null : assessments.first);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.secondary, cs.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Skill Gap Analyzer',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: cs.onSecondary)),
        iconTheme: IconThemeData(color: cs.onSecondary),
        bottom: TabBar(
          controller: _tabs,
          labelColor: cs.onSecondary,
          unselectedLabelColor: cs.onSecondary.withAlpha(153),
          indicatorColor: cs.onSecondary,
          tabs: const [
            Tab(text: 'Assess'),
            Tab(text: 'Gaps'),
            Tab(text: 'Goals'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _AssessTab(
                  active: active,
                  skill: _skill,
                  score: _score,
                  titleCtrl: _titleCtrl,
                  onSkillChanged: (s) => setState(() => _skill = s),
                  onScoreChanged: (s) => setState(() => _score = s),
                  onCreate: _createAssessment,
                  onScore: _scoreSkill,
                  service: _service,
                ),
                _GapsTab(service: _service, priorityColor: _priorityColor),
                _GoalsTab(service: _service),
              ],
            ),
    );
  }
}

class _AssessTab extends StatelessWidget {
  final SkillAssessment? active;
  final SkillArea skill;
  final double score;
  final TextEditingController titleCtrl;
  final ValueChanged<SkillArea> onSkillChanged;
  final ValueChanged<double> onScoreChanged;
  final VoidCallback onCreate;
  final VoidCallback onScore;
  final SkillGapAnalyzerService service;

  const _AssessTab({
    required this.active,
    required this.skill,
    required this.score,
    required this.titleCtrl,
    required this.onSkillChanged,
    required this.onScoreChanged,
    required this.onCreate,
    required this.onScore,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Create assessment
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Assessment',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Assessment title (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.assignment_rounded),
                    label: Text('Create Assessment',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Score a skill
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rate a Skill',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<SkillArea>(
                  value: skill,
                  decoration: InputDecoration(
                    labelText: 'Skill area',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: SkillArea.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onSkillChanged(v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Score: ',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                    Text(score.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: cs.primary)),
                    Text('/10',
                        style: GoogleFonts.outfit(
                            color: cs.onSurface.withAlpha(153))),
                  ],
                ),
                Slider(
                  value: score,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  label: score.toStringAsFixed(1),
                  onChanged: onScoreChanged,
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: active != null ? onScore : null,
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text('Submit Score',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Analysis
        if (active != null)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          color: cs.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Text('Analysis',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: cs.onSecondaryContainer)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(service.getSkillAnalysis(active!.id),
                      style: GoogleFonts.outfit(
                          color: cs.onSecondaryContainer)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GapsTab extends StatelessWidget {
  final SkillGapAnalyzerService service;
  final Map<GapPriority, MaterialColor> priorityColor;

  const _GapsTab(
      {required this.service, required this.priorityColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gaps = service.getSkillGaps();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              service.getPersonalizedRecommendations(),
              style: GoogleFonts.outfit(color: cs.onTertiaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (gaps.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 48, color: Colors.green),
                  const SizedBox(height: 12),
                  Text('No gaps identified yet',
                      style: GoogleFonts.outfit(
                          fontSize: 16, color: Colors.grey)),
                  Text('Complete an assessment to find areas to improve',
                      style: GoogleFonts.outfit(color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else ...[
          Text('Identified Gaps (${gaps.length})',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...gaps.map((gap) {
            final color = priorityColor[gap.priority] ?? Colors.grey;
            final gapSize = gap.targetLevel - gap.currentLevel;
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(gap.skillArea,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: color.withAlpha(100)),
                          ),
                          child: Text(gap.priority.name,
                              style: GoogleFonts.outfit(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                            gap.currentLevel.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: color)),
                        Text(' / 10  →  target: ',
                            style: GoogleFonts.outfit(
                                color: cs.onSurface.withAlpha(153))),
                        Text(
                            gap.targetLevel.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        Text(
                            '  (+${gapSize.toStringAsFixed(1)})',
                            style: GoogleFonts.outfit(
                                color: cs.onSurface.withAlpha(153),
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: gap.currentLevel / 10,
                      color: color,
                      borderRadius: BorderRadius.circular(4),
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

class _GoalsTab extends StatelessWidget {
  final SkillGapAnalyzerService service;

  const _GoalsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final goals = service.getGoals();

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
              service.getProgressTracking(),
              style: GoogleFonts.outfit(color: cs.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (goals.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.flag_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No goals yet',
                      style: GoogleFonts.outfit(
                          fontSize: 16, color: Colors.grey)),
                  Text('Goals are created automatically from skill gaps',
                      style: GoogleFonts.outfit(color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else ...[
          Text('Learning Goals',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...goals.map((goal) {
            final progress = goal.targetScore > 0
                ? (goal.currentScore / goal.targetScore).clamp(0.0, 1.0)
                : 0.0;
            final stepsProgress = goal.steps.isNotEmpty
                ? goal.completedSteps / goal.steps.length
                : 0.0;
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(goal.title,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                        _StatusBadge(goal.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(goal.skillArea,
                        style: GoogleFonts.outfit(
                            color: cs.onSurface.withAlpha(153),
                            fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Score progress',
                                  style: GoogleFonts.outfit(fontSize: 11)),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: progress,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Steps',
                                  style: GoogleFonts.outfit(fontSize: 11)),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: stepsProgress,
                                borderRadius: BorderRadius.circular(4),
                                color: cs.tertiary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                        '${goal.completedSteps}/${goal.steps.length} steps • deadline ${_formatDate(goal.deadline)}',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: cs.onSurface.withAlpha(153))),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _StatusBadge extends StatelessWidget {
  final GoalStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      GoalStatus.completed => Colors.green,
      GoalStatus.inProgress => Colors.blue,
      GoalStatus.onHold => Colors.orange,
      GoalStatus.cancelled => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.name,
          style: GoogleFonts.outfit(
              color: color, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}
