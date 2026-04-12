import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class DayRecapPage extends StatefulWidget {
  const DayRecapPage({super.key});

  @override
  State<DayRecapPage> createState() => _DayRecapPageState();
}

class _DayRecapPageState extends State<DayRecapPage>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  Map<String, dynamic> _stats = {};
  List<String> _achievements = [];
  String _mood = '😊';
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this)
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
    final saved = V2Storage.getMap(
        'day_recap_${_selectedDate.toIso8601String().split('T')[0]}');
    setState(() {
      if (saved != null) {
        _stats = Map<String, dynamic>.from(saved['stats'] ?? {});
        _achievements = List<String>.from(saved['achievements'] ?? []);
        _mood = saved['mood'] ?? '😊';
      } else {
        _stats = _generateSampleStats();
        _achievements = _generateSampleAchievements();
        _mood = ['😊', '😄', '😐', '😔', '😤'][DateTime.now().weekday % 5];
      }
      _isLoading = false;
    });
  }

  Map<String, dynamic> _generateSampleStats() {
    return {
      'tasks_completed': 5,
      'tasks_total': 8,
      'focus_minutes': 120,
      'steps': 8500,
      'water_ml': 2000,
      'sleep_hours': 7.5,
      'mood_score': 4,
      'calories': 1850,
    };
  }

  List<String> _generateSampleAchievements() {
    return [
      '🏃 Ran 8000+ steps',
      '⏰ Completed 2+ focus sessions',
      '💧 Drank 2L of water',
      '📚 Read for 30 minutes',
    ];
  }

  Future<void> _saveData() async {
    final dateKey = _selectedDate.toIso8601String().split('T')[0];
    await V2Storage.setMap('day_recap_$dateKey', {
      'stats': _stats,
      'achievements': _achievements,
      'mood': _mood,
    });
  }

  void _selectDate(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() => _selectedDate = date);
    _loadData();
  }

  void _updateMood(String mood) {
    HapticFeedback.lightImpact();
    setState(() => _mood = mood);
    _saveData();
    showSuccessSnackbar(context, 'Mood updated! $mood');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: V2Theme.surfaceDark,
        body: Center(
          child: CircularProgressIndicator(color: V2Theme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildDateSelector(),
          _buildMoodSelector(),
          _buildProgressCard(),
          _buildStatsGrid(),
          _buildAchievements(),
          _buildWaifuCommentary(),
        ],
      ),
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
            child: const Text('Day Recap',
                style: TextStyle(fontWeight: FontWeight.bold))),
        background: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
              Colors.indigo.withValues(alpha: 0.4),
              Colors.transparent
            ]))),
      ),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context)),
      actions: [IconButton(icon: const Icon(Icons.share), onPressed: () {})],
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 0,
          child: Container(
            height: 80,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = today.subtract(Duration(days: 6 - index));
                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month;
                return GestureDetector(
                  onTap: () => _selectDate(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: isSelected ? V2Theme.primaryGradient : null,
                      color: isSelected ? null : V2Theme.darkGlass,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          isSelected ? null : Border.all(color: Colors.white12),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_getDayAbbr(date.weekday),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.white54)),
                          const SizedBox(height: 4),
                          Text('${date.day}',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70)),
                        ]),
                  ),
                );
              },
            ),
          )),
    );
  }

  String _getDayAbbr(int weekday) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
  }

  Widget _buildMoodSelector() {
    final moods = ['😊', '😄', '😐', '😔', '😤'];
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 1,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How was your day?',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: moods.map((m) {
                          final isSelected = _mood == m;
                          return GestureDetector(
                            onTap: () => _updateMood(m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? V2Theme.primaryGradient.scale(0.3)
                                    : null,
                                color: isSelected ? null : V2Theme.darkGlass,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: V2Theme.primaryColor, width: 2)
                                    : null,
                              ),
                              child:
                                  Text(m, style: const TextStyle(fontSize: 28)),
                            ),
                          );
                        }).toList()),
                  ]))),
    );
  }

  Widget _buildProgressCard() {
    final completed = _stats['tasks_completed'] ?? 0;
    final total = _stats['tasks_total'] ?? 1;
    final progress = total > 0 ? completed / total : 0.0;
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 2,
          child: GlassCard(
            glow: true,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: [
              Row(children: [
                ProgressRing(
                    progress: progress,
                    size: 80,
                    strokeWidth: 8,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${(progress * 100).round()}%',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ])),
                const SizedBox(width: 20),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Tasks Completed',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('$completed of $total tasks done',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7))),
                      const SizedBox(height: 8),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: V2Theme.darkGlass,
                              valueColor: const AlwaysStoppedAnimation(
                                  V2Theme.primaryColor),
                              minHeight: 8)),
                    ])),
              ]),
            ]),
          )),
    );
  }

  Widget _buildStatsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8),
          delegate: SliverChildListDelegate([
            _buildStatTile('⏱️ Focus', '${_stats['focus_minutes'] ?? 0}',
                'minutes', Icons.timer, Colors.purple),
            _buildStatTile('👟 Steps', '${_stats['steps'] ?? 0}', 'steps',
                Icons.directions_walk, Colors.green),
            _buildStatTile('💧 Water', '${_stats['water_ml'] ?? 0}', 'ml',
                Icons.water_drop, Colors.blue),
            _buildStatTile('😴 Sleep', '${_stats['sleep_hours'] ?? 0}', 'hours',
                Icons.bedtime, Colors.indigo),
          ])),
    );
  }

  Widget _buildStatTile(
      String title, String value, String unit, IconData icon, Color color) {
    return AnimatedEntry(
        index: 3,
        child: GlassCard(
          margin: EdgeInsets.zero,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(height: 2),
            Text(unit,
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
          ]),
        ));
  }

  Widget _buildAchievements() {
    if (_achievements.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 4,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Achievements'),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _achievements
                        .map((a) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                  gradient: V2Theme.primaryGradient.scale(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: V2Theme.primaryColor
                                          .withValues(alpha: 0.3))),
                              child: Text(a,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13)),
                            ))
                        .toList())),
          ])),
    );
  }

  Widget _buildWaifuCommentary() {
    final progress = (_stats['tasks_completed'] ?? 0) /
        ((_stats['tasks_total'] ?? 1).clamp(1, 100));
    String mood = progress > 0.7
        ? 'achievement'
        : progress > 0.4
            ? 'neutral'
            : 'relaxed';
    return SliverToBoxAdapter(
      child: AnimatedEntry(
          index: 5,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: WaifuCommentary(mood: mood))),
    );
  }
}



