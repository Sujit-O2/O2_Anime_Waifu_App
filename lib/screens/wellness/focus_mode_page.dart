import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class FocusModePage extends StatefulWidget {
  const FocusModePage({super.key});

  @override
  State<FocusModePage> createState() => _FocusModePageState();
}

class _FocusModePageState extends State<FocusModePage>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late final VoidCallback _timerListener;
  bool _isRunning = false;
  int _selectedMinutes = 25;
  int _remainingSeconds = 0;
  String _selectedMode = 'Deep Work';
  final List<String> _modes = [
    'Deep Work',
    'Study',
    'Creative',
    'Reading',
    'Meditation'
  ];
  final Map<String, int> _modeDurations = {
    'Deep Work': 25,
    'Study': 45,
    'Creative': 30,
    'Reading': 20,
    'Meditation': 15
  };
  List<FocusSession> _sessions = [];
  int _totalMinutes = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(vsync: this);
    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);
    _timerListener = () {
      final duration = _timerController.duration;
      if (duration == null) {
        return;
      }

      if (_timerController.isCompleted && _isRunning) {
        _completeSession();
        return;
      }

      if (_isRunning) {
        setState(() {
          _remainingSeconds =
              (duration.inSeconds * (1 - _timerController.value)).round();
        });
      }
    };
    _timerController.addListener(_timerListener);
    _remainingSeconds = _selectedMinutes * 60;
    _loadData();
  }

  @override
  void dispose() {
    _timerController.removeListener(_timerListener);
    _timerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await V2Storage.init();
    final saved = V2Storage.getMap('focus_data');
    if (saved != null) {
      _sessions = (saved['sessions'] as List?)
              ?.map((s) => FocusSession.fromJson(s))
              .toList() ??
          [];
      _totalMinutes = saved['totalMinutes'] ?? 0;
      _streak = saved['streak'] ?? 0;
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveData() async {
    await V2Storage.setMap('focus_data', {
      'sessions': _sessions.map((s) => s.toJson()).toList(),
      'totalMinutes': _totalMinutes,
      'streak': _streak,
    });
  }

  void _startTimer() {
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() {
      _isRunning = true;
      if (_remainingSeconds <= 0 || _remainingSeconds > _selectedMinutes * 60) {
        _remainingSeconds = _selectedMinutes * 60;
      }
    });
    _timerController.duration = Duration(seconds: _remainingSeconds);
    _timerController.forward(from: 0);
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timerController.stop();
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _remainingSeconds =
          ((_timerController.duration?.inSeconds ?? _remainingSeconds) *
                  (1 - _timerController.value))
              .round();
    });
  }

  void _resetTimer() {
    HapticFeedback.mediumImpact();
    _timerController.reset();
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  void _completeSession() {
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _totalMinutes += _selectedMinutes;
      _streak++;
      _sessions.insert(
          0,
          FocusSession(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            mode: _selectedMode,
            duration: _selectedMinutes,
            completedAt: DateTime.now(),
          ));
    });
    _saveData();
    showSuccessSnackbar(context, 'Focus session complete! 🎯');
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageV2(
      title: 'FOCUS MODE',
      subtitle: 'Deep Work Session',
      onBack: () => Navigator.pop(context),
      actions: [
        IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
      ],
      content: CustomScrollView(
        slivers: [
          _buildTimerSection(),
          _buildModeSelector(),
          _buildDurationSelector(),
          _buildStats(),
          _buildRecentSessions(),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    final progress = _remainingSeconds / (_selectedMinutes * 60);
    return SliverToBoxAdapter(
      child: AnimatedEntry(
        index: 0,
        child: Center(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _isRunning
                          ? [
                              BoxShadow(
                                color: V2Theme.primaryColor.withValues(
                                    alpha:
                                        0.3 + (_pulseController.value * 0.3)),
                                blurRadius: 30 + (_pulseController.value * 20),
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: V2Theme.glassGradient,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ProgressRing(
                    progress: progress,
                    size: 220,
                    strokeWidth: 12,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_formatTime(_remainingSeconds),
                            style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(_selectedMode,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning && _remainingSeconds == _selectedMinutes * 60)
                    _buildControlButton(Icons.play_arrow, () => _startTimer(),
                        isPrimary: true)
                  else if (_isRunning)
                    _buildControlButton(Icons.pause, () => _pauseTimer(),
                        isPrimary: true)
                  else
                    _buildControlButton(Icons.play_arrow, () => _startTimer(),
                        isPrimary: true),
                  const SizedBox(width: 16),
                  _buildControlButton(Icons.refresh, () => _resetTimer()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed,
      {bool isPrimary = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary ? V2Theme.primaryGradient : null,
        color: isPrimary ? Colors.transparent : V2Theme.darkGlass,
        shape: BoxShape.circle,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                    color: V2Theme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ]
            : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 32),
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildModeSelector() {
    return SliverToBoxAdapter(
      child: AnimatedEntry(
        index: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Focus Mode'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _modes.map((mode) {
                  final isSelected = _selectedMode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        if (_isRunning) return;
                        HapticFeedback.lightImpact();
                        if (!mounted) return;
                        setState(() {
                          _selectedMode = mode;
                          _selectedMinutes = _modeDurations[mode]!;
                          _remainingSeconds = _selectedMinutes * 60;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected ? V2Theme.primaryGradient : null,
                          color: isSelected ? Colors.transparent : V2Theme.darkGlass,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.white12),
                        ),
                        child: Text(mode,
                            style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    if (_isRunning) return const SliverToBoxAdapter(child: SizedBox());
    return SliverToBoxAdapter(
      child: AnimatedEntry(
        index: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Duration'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [15, 25, 45, 60].map((mins) {
                  final isSelected = _selectedMinutes == mins;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (!mounted) return;
                      setState(() {
                        _selectedMinutes = mins;
                        _remainingSeconds = mins * 60;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? V2Theme.primaryGradient.scale(0.5)
                            : null,
                        color: isSelected ? Colors.transparent : V2Theme.darkGlass,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSelected
                                ? V2Theme.primaryColor
                                : Colors.transparent),
                      ),
                      child: Text('$mins',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected ? Colors.white : Colors.white70)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return SliverToBoxAdapter(
      child: AnimatedEntry(
        index: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                  child: StatCard(
                      title: 'Total Focus',
                      value: '$_totalMinutes min',
                      icon: Icons.timer,
                      color: V2Theme.primaryColor)),
              Expanded(
                  child: StatCard(
                      title: 'Streak',
                      value: '🔥 $_streak',
                      icon: Icons.local_fire_department,
                      color: Colors.orange)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSessions() {
    if (_sessions.isEmpty) {
      return const SliverToBoxAdapter(
        child: AnimatedEntry(
          index: 5,
          child: Padding(
            padding: EdgeInsets.all(32),
            child: EmptyState(
              icon: Icons.history,
              title: 'No Sessions Yet',
              subtitle: 'Complete your first focus session!',
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return const SectionHeader(title: 'Recent Sessions');
            }
            final session = _sessions[index - 1];
            return AnimatedEntry(
              index: index + 5,
              child: GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: V2Theme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle,
                          color: V2Theme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.mode,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('${session.duration} minutes',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    Text(_formatDate(session.completedAt),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
          childCount: _sessions.length.clamp(0, 5) + 1,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}';
}

class FocusSession {
  final String id;
  final String mode;
  final int duration;
  final DateTime completedAt;
  FocusSession(
      {required this.id,
      required this.mode,
      required this.duration,
      required this.completedAt});
  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
      id: json['id'],
      mode: json['mode'],
      duration: json['duration'],
      completedAt: DateTime.parse(json['completedAt']));
  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'duration': duration,
        'completedAt': completedAt.toIso8601String()
      };
}



