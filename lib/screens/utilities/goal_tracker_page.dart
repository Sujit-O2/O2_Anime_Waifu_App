import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class GoalTrackerPage extends StatefulWidget {
  const GoalTrackerPage({super.key});

  @override
  State<GoalTrackerPage> createState() => _GoalTrackerPageState();
}

class _GoalTrackerPageState extends State<GoalTrackerPage>
    with TickerProviderStateMixin {
  List<Goal> _goals = [];
  bool _isLoading = true;
  String _filter = 'All';
  final List<String> _filters = ['All', 'Active', 'Completed', 'Overdue'];
  late AnimationController _headerController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this)
      ..forward();
    _loadGoals();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    await V2Storage.init();
    final saved = V2Storage.getMap('goals_data');
    if (!mounted) return;
    setState(() {
      if (saved != null && saved['goals'] != null) {
        _goals = (saved['goals'] as List).map((g) => Goal.fromJson(g)).toList();
      } else {
        _goals = _generateSampleGoals();
      }
      _isLoading = false;
    });
  }

  List<Goal> _generateSampleGoals() {
    return [
      Goal(
          id: '1',
          title: 'Learn Flutter',
          description: 'Master Flutter development',
          progress: 0.65,
          deadline: DateTime.now().add(const Duration(days: 30)),
          category: 'Career',
          priority: 'High'),
      Goal(
          id: '2',
          title: 'Read 12 Books',
          description: 'One book per month',
          progress: 0.33,
          deadline: DateTime.now().add(const Duration(days: 180)),
          category: 'Personal',
          priority: 'Medium'),
      Goal(
          id: '3',
          title: 'Save ₹50,000',
          description: 'Emergency fund',
          progress: 0.45,
          deadline: DateTime.now().add(const Duration(days: 90)),
          category: 'Financial',
          priority: 'High'),
      Goal(
          id: '4',
          title: 'Run 5K Marathon',
          description: 'Train for the city marathon',
          progress: 0.80,
          deadline: DateTime.now().add(const Duration(days: 60)),
          category: 'Health',
          priority: 'Medium'),
    ];
  }

  Future<void> _saveGoals() async {
    await V2Storage.setMap(
        'goals_data', {'goals': _goals.map((g) => g.toJson()).toList()});
  }

  List<Goal> get _filteredGoals {
    switch (_filter) {
      case 'Active':
        return _goals.where((g) => g.progress < 1 && g.progress > 0).toList();
      case 'Completed':
        return _goals.where((g) => g.progress >= 1).toList();
      case 'Overdue':
        return _goals
            .where((g) => g.deadline.isBefore(DateTime.now()) && g.progress < 1)
            .toList();
      default:
        return _goals;
    }
  }

  void _addGoal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Personal';
    String priority = 'Medium';
    int days = 30;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.8,
          decoration: const BoxDecoration(
              color: V2Theme.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('New Goal',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      hintText: 'Goal Title',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: V2Theme.darkGlass,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                      hintText: 'Description',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: V2Theme.darkGlass,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              const Text('Category', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  children: [
                    'Personal',
                    'Career',
                    'Health',
                    'Financial',
                    'Learning'
                  ]
                      .map((c) => ChoiceChip(
                          label: Text(c),
                          selected: category == c,
                          onSelected: (s) => setModalState(() => category = c),
                          selectedColor: V2Theme.primaryColor,
                          backgroundColor: V2Theme.darkGlass,
                          labelStyle: TextStyle(
                              color: category == c
                                  ? Colors.white
                                  : Colors.white70)))
                      .toList()),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  children: ['Low', 'Medium', 'High']
                      .map((p) => ChoiceChip(
                          label: Text(p),
                          selected: priority == p,
                          onSelected: (s) => setModalState(() => priority = p),
                          selectedColor: _getPriorityColor(p),
                          backgroundColor: V2Theme.darkGlass,
                          labelStyle: TextStyle(
                              color: priority == p
                                  ? Colors.white
                                  : Colors.white70)))
                      .toList()),
              const SizedBox(height: 16),
              const Text('Timeline', style: TextStyle(color: Colors.white70)),
              Slider(
                  value: days.toDouble(),
                  min: 7,
                  max: 365,
                  divisions: 51,
                  activeColor: V2Theme.primaryColor,
                  onChanged: (v) => setModalState(() => days = v.round())),
              Text('$days days', style: const TextStyle(color: Colors.white54)),
              const Spacer(),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty) return;
                        HapticFeedback.mediumImpact();
                        final goal = Goal(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            title: titleController.text,
                            description: descController.text,
                            progress: 0,
                            deadline: DateTime.now().add(Duration(days: days)),
                            category: category,
                            priority: priority);
                        if (!mounted) return;
                        setState(() => _goals.insert(0, goal));
                        _saveGoals();
                        Navigator.pop(ctx);
                        showSuccessSnackbar(context, 'Goal created! 🎯');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: V2Theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: const Text('Create Goal',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _updateProgress(Goal goal, double newProgress) {
    if (!mounted) return;
    setState(() {
      final index = _goals.indexOf(goal);
      _goals[index] = goal.copyWith(progress: newProgress.clamp(0, 1));
    });
    _saveGoals();
    if (newProgress >= 1) {
      HapticFeedback.heavyImpact();
      showSuccessSnackbar(context, 'Goal completed! 🏆');
    }
  }

  void _deleteGoal(Goal goal) {
    if (!mounted) return;
    setState(() => _goals.remove(goal));
    _saveGoals();
    showUndoSnackbar(context, 'Goal deleted', () {
      if (!mounted) return;
      setState(() => _goals.insert(0, goal));
      _saveGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'GOAL TRACKER',
      subtitle: 'Your Objectives',
      onBack: () => Navigator.pop(context),
      actions: [
        IconButton(icon: const Icon(Icons.filter_list), onPressed: () {})
      ],
      content: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildStats(),
              _buildFilters(),
              _buildGoalsList(),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: V2FloatingActionButton(onPressed: _addGoal),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final active = _goals.where((g) => g.progress < 1).length;
    final completed = _goals.where((g) => g.progress >= 1).length;
    final avgProgress = _goals.isEmpty
        ? 0.0
        : _goals.map((g) => g.progress).reduce((a, b) => a + b) / _goals.length;
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 0,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: StatCard(
                        title: 'Active',
                        value: '$active',
                        icon: Icons.flag,
                        color: Colors.green)),
                Expanded(
                    child: StatCard(
                        title: 'Completed',
                        value: '$completed',
                        icon: Icons.check_circle,
                        color: Colors.blue)),
                Expanded(
                    child: StatCard(
                        title: 'Progress',
                        value: '${(avgProgress * 100).round()}%',
                        icon: Icons.trending_up,
                        color: V2Theme.primaryColor)),
              ]))),
    );
  }

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 1,
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                  children: _filters.map((f) {
                final isSelected = _filter == f;
                return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                        label: Text(f),
                        selected: isSelected,
                        onSelected: (s) {
                          if (!mounted) return;
                          setState(() => _filter = f);
                        },
                        selectedColor: V2Theme.primaryColor,
                        backgroundColor: V2Theme.darkGlass,
                        labelStyle: TextStyle(
                            color:
                                isSelected ? Colors.white : Colors.white70)));
              }).toList()))),
    );
  }

  Widget _buildGoalsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
          child: Center(
              child: CircularProgressIndicator(color: V2Theme.primaryColor)));
    }
    if (_filteredGoals.isEmpty) {
      return SliverFillRemaining(
          child: EmptyState(
              icon: Icons.flag,
              title: 'No Goals',
              subtitle: 'Set your first goal to get started!',
              buttonText: 'Add Goal',
              onButtonPressed: _addGoal));
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
        final goal = _filteredGoals[index];
        final isOverdue =
            goal.deadline.isBefore(DateTime.now()) && goal.progress < 1;
        return AnimatedEntry(
            index: index + 2,
            child: SwipeToDismissItem(
                onDismissed: () => _deleteGoal(goal),
                child: GlassCard(
                  onTap: () => _showGoalDetails(goal),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: _getPriorityColor(goal.priority)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(goal.priority,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _getPriorityColor(goal.priority),
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: V2Theme.primaryColor
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(goal.category,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: V2Theme.primaryColor))),
                          const Spacer(),
                          if (isOverdue)
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Text('OVERDUE',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold))),
                        ]),
                        const SizedBox(height: 12),
                        Text(goal.title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        if (goal.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(goal.description,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis)
                        ],
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                      value: goal.progress,
                                      backgroundColor: V2Theme.darkGlass,
                                      valueColor: AlwaysStoppedAnimation(
                                          isOverdue
                                              ? Colors.red
                                              : V2Theme.primaryColor),
                                      minHeight: 8))),
                          const SizedBox(width: 12),
                          Text('${(goal.progress * 100).round()}%',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Icon(Icons.calendar_today,
                              size: 14,
                              color: isOverdue ? Colors.red : Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                              isOverdue
                                  ? 'Overdue by ${-goal.deadline.difference(DateTime.now()).inDays} days'
                                  : '${goal.deadline.difference(DateTime.now()).inDays} days left',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isOverdue ? Colors.red : Colors.white54)),
                          const Spacer(),
                          Slider(
                              value: goal.progress,
                              onChanged: (v) => _updateProgress(goal, v),
                              activeColor: V2Theme.primaryColor,
                              inactiveColor: V2Theme.darkGlass,
                              divisions: 20),
                        ]),
                      ]),
                )));
      }, childCount: _filteredGoals.length)),
    );
  }

  void _showGoalDetails(Goal goal) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: V2Theme.surfaceLight,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),
                    Text(goal.title,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(goal.description,
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    Row(children: [
                      _buildDetailItem('Priority', goal.priority,
                          _getPriorityColor(goal.priority)),
                      const SizedBox(width: 24),
                      _buildDetailItem(
                          'Category', goal.category, V2Theme.primaryColor),
                      const SizedBox(width: 24),
                      _buildDetailItem('Progress',
                          '${(goal.progress * 100).round()}%', Colors.green),
                    ]),
                    const SizedBox(height: 24),
                  ]),
            ));
  }

  Widget _buildDetailItem(String label, String value, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]);
}

class Goal {
  final String id;
  final String title;
  final String description;
  final double progress;
  final DateTime deadline;
  final String category;
  final String priority;

  Goal(
      {required this.id,
      required this.title,
      required this.description,
      required this.progress,
      required this.deadline,
      required this.category,
      required this.priority});
  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      progress: json['progress'].toDouble(),
      deadline: DateTime.parse(json['deadline']),
      category: json['category'],
      priority: json['priority']);
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'progress': progress,
        'deadline': deadline.toIso8601String(),
        'category': category,
        'priority': priority
      };
  Goal copyWith({double? progress}) => Goal(
      id: id,
      title: title,
      description: description,
      progress: progress ?? this.progress,
      deadline: deadline,
      category: category,
      priority: priority);
}
