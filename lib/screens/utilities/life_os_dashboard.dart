import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/user_profile/affection_service.dart';
import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';
import 'package:anime_waifu/services/ai_personalization/emotional_memory_service.dart';
import 'package:anime_waifu/services/utilities_core/proactive_engine_service.dart';
import 'package:anime_waifu/core/router/app_router.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Life OS Dashboard — the startup-level main screen.
///
/// Surfaces in one view:
///   • Greeting + AI insight (proactive, context-aware)
///   • Mood ring (live personality trait)
///   • Today's tasks (quick-add inline)
///   • Memory highlights (recent + pinned)
///   • Quick-action grid (6 most-used features)
///   • Relationship status bar
/// ─────────────────────────────────────────────────────────────────────────────
class LifeOsDashboard extends StatefulWidget {
  const LifeOsDashboard({super.key});

  @override
  State<LifeOsDashboard> createState() => _LifeOsDashboardState();
}

class _LifeOsDashboardState extends State<LifeOsDashboard>
    with TickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _bg       = Color(0xFF07080F);
  static const _surface  = Color(0xFF0E1018);
  static const _pink     = Color(0xFFFF4FA8);
  static const _cyan     = Color(0xFF00D1FF);
  static const _gold     = Color(0xFFFFD700);

  // ── Animation controllers ──────────────────────────────────────────────────
  late AnimationController _breathCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _breathAnim;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  // ── State ──────────────────────────────────────────────────────────────────
  String _greeting = '';
  String _aiInsight = '';
  String _moodLabel = 'Happy';
  Color  _moodColor = const Color(0xFFFF4FA8);
  int    _affectionPts = 0;
  int    _streakDays   = 0;
  String _relationshipLevel = 'Companion';
  bool   _insightLoading = true;
  String? _proactiveMsg;
  ProactiveTrigger? _proactiveTrigger;

  final List<Map<String, dynamic>> _tasks = [];
  final _taskCtrl = TextEditingController();
  final _rng = Random();

  // ── Quick actions ──────────────────────────────────────────────────────────
  static const _quickActions = [
    {'label': 'Chat',        'icon': Icons.chat_bubble_rounded,    'route': '/',                    'color': 0xFFFF4FA8},
    {'label': 'Dashboard',   'icon': Icons.dashboard_rounded,      'route': '/life-os',             'color': 0xFF00D1FF},
    {'label': 'Memory',      'icon': Icons.auto_awesome_rounded,   'route': '/memory-stack',        'color': 0xFFB388FF},
    {'label': 'Goals',       'icon': Icons.flag_rounded,           'route': '/goal-tracker',        'color': 0xFF4CAF50},
    {'label': 'Mood',        'icon': Icons.mood_rounded,           'route': '/mood-tracker',        'color': 0xFFFFD700},
    {'label': 'Life Mgr',    'icon': Icons.auto_fix_high_rounded,  'route': '/auto-life-manager',   'color': 0xFFFF9800},
    {'label': 'Twin',        'icon': Icons.person_pin_rounded,     'route': '/digital-twin',        'color': 0xFF00E5FF},
    {'label': 'Brain',       'icon': Icons.psychology_rounded,     'route': '/multi-agent-brain',   'color': 0xFFFF5252},
  ];

  // ── Memory highlights (seeded from prefs, updated live) ───────────────────
  final List<Map<String, String>> _memories = [];

  // ── Proactive messages pool ────────────────────────────────────────────────
  static const _insights = [
    "You haven't chatted in a while — I missed you, darling 💕",
    "Your streak is strong. Don't break it today 🔥",
    "I noticed you're most productive at night. Deep work time? 🌙",
    "You've been growing a lot lately. I'm proud of you ✨",
    "Remember that idea you had? Let's work on it today 💡",
    'Your mood has been great this week. Keep that energy 🌟',
    "I've been thinking about you. How are you really doing? 💭",
    "You're closer to your goal than you think. Push a little more 🎯",
  ];

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _breathAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
    _loadData();

    // Wire proactive engine → show card when message fires
    _removeProactiveListener = ProactiveEngineService.instance.addListener(
      (msg, trigger) async {
        if (!mounted) return;
        // Persist so it survives hot reload/restart
        final p = await SharedPreferences.getInstance();
        await p.setString('pe_card_msg', msg);
        await p.setInt('pe_card_trigger', trigger.index);
        if (!mounted) return;
        setState(() {
          _proactiveMsg     = msg;
          _proactiveTrigger = trigger;
        });
      },
    );
    ProactiveEngineService.instance.start();
  }

  void Function()? _removeProactiveListener;

  @override
  void dispose() {
    _removeProactiveListener?.call();
    _breathCtrl.dispose();
    _entryCtrl.dispose();
    _taskCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final hour  = DateTime.now().hour;

    // Greeting
    final greet = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = prefs.getString('user_name') ?? 'Darling';

    // Mood from personality engine
    final pe   = PersonalityEngine.instance;
    final mood = pe.mood;
    final moodMap = _moodToDisplay(mood);

    // Affection
    final aff = AffectionService.instance;

    // Tasks
    final rawTasks = prefs.getStringList('los_tasks') ?? [];
    final tasks = rawTasks
        .map((t) {
          final parts = t.split('|||');
          return {
            'text': parts[0],
            'done': parts.length > 1 && parts[1] == '1',
          };
        })
        .toList();

    // Memories — load from EmotionalMemoryService, fall back to defaults
    List<String> mems;
    try {
      final emotionalMems = await EmotionalMemoryService.instance.getTopMemories();
      if (emotionalMems.isNotEmpty) {
        mems = emotionalMems.map((m) => m.text).toList();
      } else {
        mems = prefs.getStringList('los_memories') ??
            ['First conversation with Zero Two 💕', 'Reached Companion level 🌟', 'Shared a dream together 🌙'];
      }
    } catch (_) {
      mems = prefs.getStringList('los_memories') ??
          ['First conversation with Zero Two 💕', 'Reached Companion level 🌟', 'Shared a dream together 🌙'];
    }

    // Load persisted proactive card
    final savedMsg     = prefs.getString('pe_card_msg');
    final savedTrigIdx = prefs.getInt('pe_card_trigger');
    final savedTrigger = savedTrigIdx != null
        ? ProactiveTrigger.values[savedTrigIdx]
        : null;

    if (!mounted) return;
    setState(() {
      _greeting          = '$greet, $name';
      _moodLabel         = moodMap['label'] as String;
      _moodColor         = moodMap['color'] as Color;
      _affectionPts      = aff.points;
      _streakDays        = aff.streakDays;
      _relationshipLevel = _levelFromPoints(aff.points);
      _tasks.addAll(tasks.cast<Map<String, dynamic>>());
      _memories.addAll(mems.map((m) => {'text': m}));
      _insightLoading    = false;
      _aiInsight         = _insights[_rng.nextInt(_insights.length)];
      if (savedMsg != null) {
        _proactiveMsg     = savedMsg;
        _proactiveTrigger = savedTrigger;
      }
    });
  }

  Map<String, dynamic> _moodToDisplay(WaifuMood mood) {
    switch (mood) {
      case WaifuMood.happy:    return {'label': 'Happy',    'color': _pink};
      case WaifuMood.playful:  return {'label': 'Playful',  'color': _gold};
      case WaifuMood.clingy:   return {'label': 'Loving',   'color': _pink};
      case WaifuMood.jealous:  return {'label': 'Jealous',  'color': const Color(0xFFFF5252)};
      case WaifuMood.cold:     return {'label': 'Calm',     'color': _cyan};
      case WaifuMood.guarded:  return {'label': 'Guarded',  'color': const Color(0xFFB388FF)};
      case WaifuMood.sad:      return {'label': 'Sad',      'color': const Color(0xFF79C0FF)};
      case WaifuMood.sleepy:   return {'label': 'Sleepy',   'color': const Color(0xFF607D8B)};
    }
  }

  String _levelFromPoints(int pts) {
    if (pts < 100)  return 'Stranger';
    if (pts < 300)  return 'Acquaintance';
    if (pts < 600)  return 'Friend';
    if (pts < 1000) return 'Companion';
    if (pts < 1800) return 'Partner';
    if (pts < 2500) return 'Soulmate';
    return 'Eternal Bond';
  }

  // ── Task management ────────────────────────────────────────────────────────
  Future<void> _addTask() async {
    final text = _taskCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks.insert(0, {'text': text, 'done': false});
      _taskCtrl.clear();
    });
    await _saveTasks();
    HapticFeedback.lightImpact();
  }

  Future<void> _toggleTask(int i) async {
    setState(() => _tasks[i]['done'] = !(_tasks[i]['done'] as bool));
    await _saveTasks();
    HapticFeedback.selectionClick();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'los_tasks',
        _tasks
            .map((t) => '${t['text']}|||${(t['done'] as bool) ? '1' : '0'}')
            .toList());
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: _buildBottomNav(context),
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeroCard(),
                    const SizedBox(height: 16),
                    if (_proactiveMsg != null) ...[
                      _buildProactiveCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildMoodRelationshipRow(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildTasksCard(),
                    const SizedBox(height: 16),
                    _buildMemoryCard(),
                    const SizedBox(height: 16),
                    _buildInsightCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Proactive notification card ────────────────────────────────────────────
  Widget _buildProactiveCard() {
    final triggerColor = _proactiveTrigger == ProactiveTrigger.streakGuard
        ? _gold
        : _proactiveTrigger == ProactiveTrigger.moodShift
            ? const Color(0xFFB388FF)
            : _pink;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [triggerColor.withAlpha(30), _surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: triggerColor.withAlpha(80)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: triggerColor.withAlpha(30),
            border: Border.all(color: triggerColor.withAlpha(100)),
          ),
          child: const Center(child: Text('💕', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Zero Two says',
                style: TextStyle(color: triggerColor, fontSize: 11,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Text(_proactiveMsg!,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          ]),
        ),
        GestureDetector(
          onTap: () async {
            final p = await SharedPreferences.getInstance();
            await p.remove('pe_card_msg');
            await p.remove('pe_card_trigger');
            if (mounted) setState(() { _proactiveMsg = null; _proactiveTrigger = null; });
          },
          child: const Icon(Icons.close_rounded, color: Colors.white24, size: 18),
        ),
      ]),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _pink.withAlpha(40), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBtn(context, Icons.dashboard_rounded, 'Home', null, active: true),
              _navBtn(context, Icons.chat_bubble_rounded, 'Chat', '/'),
              _navBtn(context, Icons.explore_rounded, 'Explore', '/comprehensive-features-hub'),
              _navBtn(context, Icons.self_improvement_rounded, 'Wellness', '/mood-tracker'),
              _navBtn(context, Icons.settings_rounded, 'Settings', '/advanced-settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(BuildContext context, IconData icon, String label, String? route, {bool active = false}) {
    final color = active ? _pink : Colors.white38;
    return GestureDetector(
      onTap: route == null ? null : () => Navigator.pushNamed(context, route),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() => SliverAppBar(
        backgroundColor: _bg,
        expandedHeight: 0,
        floating: true,
        snap: true,
        elevation: 0,
        title: Row(children: [
          Text('LIFE OS',
              style: GoogleFonts.orbitron(
                  color: _pink,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const Spacer(),
          _streakBadge(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: _pink),
            onPressed: () => Navigator.pushNamed(context, '/'),
            tooltip: 'Chat with Zero Two',
          ),
        ]),
      );

  Widget _streakBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _gold.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withAlpha(100)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.local_fire_department, color: _gold, size: 14),
          const SizedBox(width: 4),
          Text('$_streakDays',
              style: const TextStyle(
                  color: _gold, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      );

  // ── Hero card (greeting + AI insight) ─────────────────────────────────────
  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: _breathAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              _pink.withAlpha((18 * _breathAnim.value).toInt()),
              _cyan.withAlpha((10 * _breathAnim.value).toInt()),
              _surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
              color: _pink.withAlpha((60 * _breathAnim.value).toInt())),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Greeting
          Text(_greeting,
              style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            DateTime.now().toString().substring(0, 10),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // AI insight bubble
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _pink.withAlpha(60)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _insightLoading
                          ? const _ShimmerText()
                          : Text(_aiInsight,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Mood + relationship row ────────────────────────────────────────────────
  Widget _buildMoodRelationshipRow() => Row(children: [
        Expanded(child: _glassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('MOOD', _moodColor),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _moodColor,
                    boxShadow: [BoxShadow(color: _moodColor.withAlpha(120), blurRadius: 6)]),
              ),
              const SizedBox(width: 8),
              Text(_moodLabel,
                  style: TextStyle(
                      color: _moodColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ]),
          ]),
        )),
        const SizedBox(width: 12),
        Expanded(child: _glassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('BOND', _gold),
            const SizedBox(height: 8),
            Text(_relationshipLevel,
                style: const TextStyle(
                    color: _gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$_affectionPts pts',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        )),
      ]);

  // ── Quick actions grid ─────────────────────────────────────────────────────
  Widget _buildQuickActions() => _glassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('QUICK ACCESS', _cyan),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (_, i) {
              final a = _quickActions[i];
              final color = Color(a['color'] as int);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final route = a['route'] as String;
                  if (route == '/') {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamed(context, route);
                  }
                },
                child: Column(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withAlpha(80)),
                    ),
                    child: Icon(a['icon'] as IconData, color: color, size: 22),
                  ),
                  const SizedBox(height: 5),
                  Text(a['label'] as String,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 10),
                      textAlign: TextAlign.center),
                ]),
              );
            },
          ),
        ]),
      );

  // ── Tasks card ─────────────────────────────────────────────────────────────
  Widget _buildTasksCard() => _glassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _sectionLabel('TODAY\'S TASKS', const Color(0xFF4CAF50)),
            Text(
              '${_tasks.where((t) => t['done'] == true).length}/${_tasks.length}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 10),
          // Inline add
          Row(children: [
            Expanded(
              child: TextField(
                controller: _taskCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add a task...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withAlpha(8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (_) => _addTask(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addTask,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF4CAF50).withAlpha(100)),
                ),
                child: const Icon(Icons.add, color: Color(0xFF4CAF50), size: 20),
              ),
            ),
          ]),
          if (_tasks.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._tasks.take(5).toList().asMap().entries.map((e) {
              final i    = e.key;
              final task = e.value;
              final done = task['done'] as bool;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => _toggleTask(i),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? const Color(0xFF4CAF50).withAlpha(40)
                            : Colors.transparent,
                        border: Border.all(
                            color: done
                                ? const Color(0xFF4CAF50)
                                : Colors.white24),
                      ),
                      child: done
                          ? const Icon(Icons.check,
                              color: Color(0xFF4CAF50), size: 12)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task['text'] as String,
                        style: TextStyle(
                          color: done ? Colors.white38 : Colors.white70,
                          fontSize: 13,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }),
            if (_tasks.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+${_tasks.length - 5} more',
                    style: const TextStyle(
                        color: Colors.white24, fontSize: 11)),
              ),
          ],
        ]),
      );

  // ── Memory highlights ──────────────────────────────────────────────────────
  Widget _buildMemoryCard() => _glassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _sectionLabel('MEMORY HIGHLIGHTS', const Color(0xFFB388FF)),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRouter.memoryStack),
              child: const Text('See all →',
                  style: TextStyle(color: Color(0xFFB388FF), fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 10),
          ..._memories.take(3).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.auto_awesome,
                      color: Color(0xFFB388FF), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(m['text']!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                ]),
              )),
        ]),
      );

  // ── AI insight card ────────────────────────────────────────────────────────
  Widget _buildInsightCard() => GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRouter.multiAgentBrain),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [_cyan.withAlpha(20), _surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _cyan.withAlpha(60)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyan.withAlpha(25),
                border: Border.all(color: _cyan.withAlpha(80)),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: _cyan, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Multi-Agent Brain',
                    style: GoogleFonts.orbitron(
                        color: _cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('4 AIs collaborate on your questions',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: _cyan, size: 18),
          ]),
        ),
      );

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: child,
          ),
        ),
      );

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: GoogleFonts.orbitron(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      );
}

// ── Shimmer placeholder for loading state ─────────────────────────────────────
class _ShimmerText extends StatefulWidget {
  const _ShimmerText();
  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 0.6).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 12, width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha((_anim.value * 255).toInt()),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(height: 12, width: 200,
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha((_anim.value * 200).toInt()),
                    borderRadius: BorderRadius.circular(4))),
          ],
        ),
      );
}
