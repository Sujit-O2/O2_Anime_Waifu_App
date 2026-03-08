import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/affection_service.dart';

class StatsAndHabitsPage extends StatefulWidget {
  const StatsAndHabitsPage({super.key});

  @override
  State<StatsAndHabitsPage> createState() => _StatsAndHabitsPageState();
}

class _StatsAndHabitsPageState extends State<StatsAndHabitsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _totalMessages = 0;
  int _userMessages = 0;
  int _aiMessages = 0;
  Map<String, int> _topicCounts = {};

  // Habits
  List<Map<String, dynamic>> _habits = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
    _loadHabits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('conversation_memory') ?? [];
    int userMsg = 0;
    int aiMsg = 0;

    // Simple topic keyword counting
    final topics = {
      'anime': 0,
      'music': 0,
      'games': 0,
      'feelings': 0,
      'help': 0
    };

    for (var s in saved) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final msg = ChatMessage.fromJson(map);
        if (msg.role == 'user') {
          userMsg++;
          final text = msg.content.toLowerCase();
          if (text.contains('anime') ||
              text.contains('manga') ||
              text.contains('otaku')) topics['anime'] = topics['anime']! + 1;
          if (text.contains('music') ||
              text.contains('song') ||
              text.contains('play')) topics['music'] = topics['music']! + 1;
          if (text.contains('game') ||
              text.contains('play') ||
              text.contains('wordle') ||
              text.contains('quiz')) topics['games'] = topics['games']! + 1;
          if (text.contains('sad') ||
              text.contains('happy') ||
              text.contains('feel') ||
              text.contains('love'))
            topics['feelings'] = topics['feelings']! + 1;
          if (text.contains('help') ||
              text.contains('how') ||
              text.contains('what')) topics['help'] = topics['help']! + 1;
        } else if (msg.role == 'assistant') {
          aiMsg++;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _totalMessages = saved.length;
        _userMessages = userMsg;
        _aiMessages = aiMsg;
        // Filter out zero count topics and sort
        _topicCounts = Map.fromEntries(
            topics.entries.where((e) => e.value > 0).toList()
              ..sort((a, b) => b.value.compareTo(a.value)));
      });
    }
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final hString = prefs.getString('user_habits');
    if (hString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(hString);
        setState(() {
          _habits = decoded.cast<Map<String, dynamic>>();
        });
        _checkHabitResets();
      } catch (e) {
        debugPrint('Error loading habits: $e');
      }
    }
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_habits', jsonEncode(_habits));
  }

  void _checkHabitResets() {
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    bool changed = false;

    for (var hab in _habits) {
      if (hab['lastDoneDate'] != today) {
        hab['isDoneToday'] = false;
        changed = true;
      }
    }

    if (changed) {
      setState(() {});
      _saveHabits();
    }
  }

  void _addHabit(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      _habits.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name.trim(),
        'streak': 0,
        'isDoneToday': false,
        'lastDoneDate': '',
      });
    });
    _saveHabits();
  }

  void _toggleHabit(int index) {
    setState(() {
      final hab = _habits[index];
      final now = DateTime.now();
      final today = "${now.year}-${now.month}-${now.day}";

      if (hab['isDoneToday'] == true) {
        // Undo
        hab['isDoneToday'] = false;
        hab['streak'] =
            (hab['streak'] as int) > 0 ? (hab['streak'] as int) - 1 : 0;
        hab['lastDoneDate'] = ''; // Overly simple, but works for immediate undo
      } else {
        // Do
        hab['isDoneToday'] = true;
        hab['streak'] = (hab['streak'] as int) + 1;
        hab['lastDoneDate'] = today;

        // Reward affection for completing a habit!
        AffectionService.instance.addPoints(2);
      }
    });
    _saveHabits();
  }

  void _deleteHabit(int index) {
    setState(() {
      _habits.removeAt(index);
    });
    _saveHabits();
  }

  void _showAddHabitDialog() {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A35),
        title:
            Text('New Habit', style: GoogleFonts.outfit(color: Colors.white)),
        content: TextField(
          controller: tc,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Drink Water, Read 10 pages',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor),
            onPressed: () {
              Navigator.pop(ctx);
              _addHabit(tc.text);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatBox('Total Msgs', '$_totalMessages', Colors.blue),
            _StatBox('You', '$_userMessages', Colors.green),
            _StatBox('Zero Two', '$_aiMessages', Colors.pink),
          ],
        ),
        const SizedBox(height: 30),
        Text('Relationship status',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Text(
                '${AffectionService.instance.points} 💖',
                style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AffectionService.instance.levelColor),
              ),
              const SizedBox(height: 5),
              Text(AffectionService.instance.levelName,
                  style: GoogleFonts.outfit(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: AffectionService.instance.levelProgress,
                backgroundColor: Colors.white12,
                color: AffectionService.instance.levelColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 15),
              Text(
                '🔥 Daily Streak: ${AffectionService.instance.streakDays} days',
                style: GoogleFonts.outfit(
                    color: Colors.orangeAccent, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
        const SizedBox(height: 30),
        if (_topicCounts.isNotEmpty) ...[
          Text('Favorite Topics',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _topicCounts.entries
                .map((e) => Chip(
                      label: Text('${e.key} (${e.value})'),
                      backgroundColor: Colors.white12,
                      labelStyle: const TextStyle(color: Colors.white),
                    ))
                .toList(),
          ),
        ]
      ],
    );
  }

  Widget _buildHabitsTab() {
    return Column(
      children: [
        Expanded(
          child: _habits.isEmpty
              ? Center(
                  child: Text("No habits yet.\nZero Two will cheer you on!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _habits.length,
                  itemBuilder: (ctx, i) {
                    final hab = _habits[i];
                    final isDone = hab['isDoneToday'] == true;
                    return Card(
                      color: isDone
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.white10,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            isDone ? Icons.check_circle : Icons.circle_outlined,
                            color: isDone ? Colors.greenAccent : Colors.white54,
                            size: 32,
                          ),
                          onPressed: () => _toggleHabit(i),
                        ),
                        title: Text(
                          hab['name'],
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.white54,
                          ),
                        ),
                        subtitle: Text('🔥 ${hab['streak']} day streak',
                            style:
                                TextStyle(color: Colors.orangeAccent.shade200)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white38),
                          onPressed: () => _deleteHabit(i),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Habit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _showAddHabitDialog,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A24),
      appBar: AppBar(
        title: Text('Stats & Habits',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Stats', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Habits', icon: Icon(Icons.check_box)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildHabitsTab(),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
