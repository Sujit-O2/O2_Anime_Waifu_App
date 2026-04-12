import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class SelfImprovementPage extends StatefulWidget {
  const SelfImprovementPage({super.key});

  @override
  State<SelfImprovementPage> createState() => _SelfImprovementPageState();
}

class _SelfImprovementPageState extends State<SelfImprovementPage>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  List<ImprovementItem> _items = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this)
      ..forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await V2Storage.init();
    final saved = V2Storage.getMap('self_improvement_data');
    setState(() {
      if (saved != null && saved['items'] != null) {
        _items = (saved['items'] as List)
            .map((i) => ImprovementItem.fromJson(i))
            .toList();
      } else {
        _items = _generateSampleItems();
      }
      _isLoading = false;
    });
  }

  List<ImprovementItem> _generateSampleItems() {
    return [
      ImprovementItem(
          id: '1',
          title: 'Daily Meditation',
          description: '10 minutes of mindfulness',
          type: 'habit',
          streak: 15,
          icon: Icons.self_improvement,
          color: Colors.purple),
      ImprovementItem(
          id: '2',
          title: 'Read 30 Minutes',
          description: 'Daily reading habit',
          type: 'habit',
          streak: 8,
          icon: Icons.menu_book,
          color: Colors.blue),
      ImprovementItem(
          id: '3',
          title: 'Journaling',
          description: 'Write 3 things you\'re grateful for',
          type: 'habit',
          streak: 12,
          icon: Icons.edit_note,
          color: Colors.green),
      ImprovementItem(
          id: '4',
          title: 'Learn New Skill',
          description: 'Pick up a new skill this month',
          type: 'goal',
          streak: 0,
          progress: 0.6,
          icon: Icons.school,
          color: Colors.orange),
      ImprovementItem(
          id: '5',
          title: 'Morning Routine',
          description: 'Wake up at 6 AM daily',
          type: 'habit',
          streak: 5,
          icon: Icons.wb_sunny,
          color: Colors.amber),
      ImprovementItem(
          id: '6',
          title: 'Exercise',
          description: '30 minutes workout',
          type: 'habit',
          streak: 20,
          icon: Icons.fitness_center,
          color: Colors.red),
    ];
  }

  Future<void> _saveData() async {
    await V2Storage.setMap('self_improvement_data',
        {'items': _items.map((i) => i.toJson()).toList()});
  }

  List<ImprovementItem> get _filteredItems {
    if (_selectedTab == 0) {
      return _items.where((i) => i.type == 'habit').toList();
    }
    if (_selectedTab == 1) {
      return _items.where((i) => i.type == 'goal').toList();
    }
    return _items;
  }

  void _addItem() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String type = 'habit';
    IconData icon = Icons.star;
    Color color = V2Theme.primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
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
              const Text('Add Improvement',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 24),
              TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(color: Colors.white38),
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
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: V2Theme.darkGlass,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              const Text('Type', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  children: ['habit', 'goal']
                      .map((t) => ChoiceChip(
                          label: Text(t == 'habit' ? 'Habit' : 'Goal'),
                          selected: type == t,
                          onSelected: (s) => setModalState(() => type = t),
                          selectedColor: V2Theme.primaryColor,
                          backgroundColor: V2Theme.darkGlass,
                          labelStyle: TextStyle(
                              color:
                                  type == t ? Colors.white : Colors.white70)))
                      .toList()),
              const SizedBox(height: 16),
              const Text('Icon', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  children: [
                    Icons.star,
                    Icons.fitness_center,
                    Icons.menu_book,
                    Icons.self_improvement,
                    Icons.code,
                    Icons.brush
                  ]
                      .map((i) => GestureDetector(
                            onTap: () => setModalState(() => icon = i),
                            child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: icon == i
                                        ? V2Theme.primaryColor
                                            .withValues(alpha: 0.3)
                                        : V2Theme.darkGlass,
                                    borderRadius: BorderRadius.circular(12),
                                    border: icon == i
                                        ? Border.all(
                                            color: V2Theme.primaryColor)
                                        : null),
                                child: Icon(icon, color: Colors.white)),
                          ))
                      .toList()),
              const Spacer(),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty) return;
                        HapticFeedback.mediumImpact();
                        final item = ImprovementItem(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            title: titleController.text,
                            description: descController.text,
                            type: type,
                            streak: 0,
                            icon: icon,
                            color: color);
                        setState(() => _items.insert(0, item));
                        _saveData();
                        Navigator.pop(ctx);
                        showSuccessSnackbar(context, 'Added! 💪');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: V2Theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: const Text('Add',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleComplete(ImprovementItem item) {
    HapticFeedback.lightImpact();
    setState(() {
      final index = _items.indexOf(item);
      if (item.isCompleted) {
        _items[index] = item.copyWith(streak: 0, isCompleted: false);
      } else {
        _items[index] =
            item.copyWith(streak: item.streak + 1, isCompleted: true);
      }
    });
    _saveData();
  }

  void _deleteItem(ImprovementItem item) {
    setState(() => _items.remove(item));
    _saveData();
    showUndoSnackbar(context, 'Removed "${item.title}"', () {
      setState(() => _items.insert(0, item));
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildStats(),
          _buildTabs(),
          _buildItemsList(),
        ],
      ),
      floatingActionButton: V2FloatingActionButton(onPressed: _addItem),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: V2Theme.surfaceDark,
      flexibleSpace: FlexibleSpaceBar(
        title: FadeTransition(
            opacity: _animController,
            child: const Text('Self Improvement',
                style: TextStyle(fontWeight: FontWeight.bold))),
        background: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
              Colors.teal.withValues(alpha: 0.4),
              Colors.transparent
            ]))),
      ),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context)),
      actions: [IconButton(icon: const Icon(Icons.insights), onPressed: () {})],
    );
  }

  Widget _buildStats() {
    final totalStreak = _items
        .where((i) => i.type == 'habit')
        .fold(0, (sum, i) => sum + i.streak);
    final completedGoals =
        _items.where((i) => i.type == 'goal' && i.progress >= 1).length;
    final totalGoals = _items.where((i) => i.type == 'goal').length;
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 0,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: StatCard(
                        title: 'Total Streak',
                        value: '$totalStreak days',
                        icon: Icons.local_fire_department,
                        color: Colors.orange)),
                Expanded(
                    child: StatCard(
                        title: 'Goals Done',
                        value: '$completedGoals/$totalGoals',
                        icon: Icons.flag,
                        color: V2Theme.primaryColor)),
              ]))),
    );
  }

  Widget _buildTabs() {
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 1,
          child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: V2Theme.glassDecoration
                  .copyWith(borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Expanded(child: _buildTab('Habits', 0)),
                Expanded(child: _buildTab('Goals', 1)),
                Expanded(child: _buildTab('All', 2)),
              ]))),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            gradient: isSelected ? V2Theme.primaryGradient : null,
            borderRadius: BorderRadius.circular(16)),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
          child: Center(
              child: CircularProgressIndicator(color: V2Theme.primaryColor)));
    }
    if (_filteredItems.isEmpty) {
      return SliverFillRemaining(
          child: EmptyState(
              icon: Icons.trending_up,
              title: 'No Items Yet',
              subtitle: 'Start your self-improvement journey!',
              buttonText: 'Add Item',
              onButtonPressed: _addItem));
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
        final item = _filteredItems[index];
        return AnimatedEntry(
            index: index + 2,
            child: SwipeToDismissItem(
                onDismissed: () => _deleteItem(item),
                child: GlassCard(
                  onTap: () => _toggleComplete(item),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => _toggleComplete(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient:
                              item.isCompleted ? V2Theme.primaryGradient : null,
                          color: item.isCompleted ? null : V2Theme.darkGlass,
                          borderRadius: BorderRadius.circular(14),
                          border: item.isCompleted
                              ? null
                              : Border.all(color: Colors.white24),
                        ),
                        child: Icon(item.isCompleted ? Icons.check : item.icon,
                            color:
                                item.isCompleted ? Colors.white : item.color),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(item.title,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null)),
                          const SizedBox(height: 4),
                          Text(item.description,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (item.type == 'habit') ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              Icon(Icons.local_fire_department,
                                  size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('${item.streak} day streak',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.orange))
                            ])
                          ],
                          if (item.type == 'goal') ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                          value: item.progress,
                                          backgroundColor: V2Theme.darkGlass,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  V2Theme.primaryColor),
                                          minHeight: 6))),
                              const SizedBox(width: 8),
                              Text('${(item.progress * 100).round()}%',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white54))
                            ])
                          ],
                        ])),
                  ]),
                )));
      }, childCount: _filteredItems.length)),
    );
  }
}

class ImprovementItem {
  static const Map<String, IconData> _iconMap = {
    'self_improvement': Icons.self_improvement,
    'menu_book': Icons.menu_book,
    'edit_note': Icons.edit_note,
    'school': Icons.school,
    'wb_sunny': Icons.wb_sunny,
    'fitness_center': Icons.fitness_center,
    'star': Icons.star,
    'code': Icons.code,
    'brush': Icons.brush,
    'local_fire_department': Icons.local_fire_department,
    'flag': Icons.flag,
    'trending_up': Icons.trending_up,
    'insights': Icons.insights,
    'check': Icons.check,
  };

  static String _iconToKey(IconData icon) {
    for (final entry in _iconMap.entries) {
      if (entry.value.codePoint == icon.codePoint) return entry.key;
    }
    return 'star';
  }

  static IconData _keyToIcon(String key) => _iconMap[key] ?? Icons.star;

  final String id;
  final String title;
  final String description;
  final String type;
  final int streak;
  final double progress;
  final IconData icon;
  final Color color;
  final bool isCompleted;

  ImprovementItem(
      {required this.id,
      required this.title,
      required this.description,
      required this.type,
      required this.streak,
      this.progress = 0,
      required this.icon,
      required this.color,
      this.isCompleted = false});
  factory ImprovementItem.fromJson(Map<String, dynamic> json) =>
      ImprovementItem(
          id: json['id'],
          title: json['title'],
          description: json['description'],
          type: json['type'],
          streak: json['streak'] ?? 0,
          progress: (json['progress'] ?? 0).toDouble(),
          icon: _keyToIcon(json['icon'] is String ? json['icon'] : 'star'),
          color: Color(json['color']),
          isCompleted: json['isCompleted'] ?? false);
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'streak': streak,
        'progress': progress,
        'icon': _iconToKey(icon),
        'color': color.toARGB32(),
        'isCompleted': isCompleted
      };
  ImprovementItem copyWith({int? streak, bool? isCompleted}) => ImprovementItem(
      id: id,
      title: title,
      description: description,
      type: type,
      streak: streak ?? this.streak,
      progress: progress,
      icon: icon,
      color: color,
      isCompleted: isCompleted ?? this.isCompleted);
}




