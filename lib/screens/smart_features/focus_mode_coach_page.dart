import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../../services/smart_features/focus_mode_service.dart';

class FocusModeCoachPage extends StatefulWidget {
  const FocusModeCoachPage({super.key});

  @override
  State<FocusModeCoachPage> createState() => _FocusModeCoachPageState();
}

class _FocusModeCoachPageState extends State<FocusModeCoachPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FocusModeService _service = FocusModeService.instance;
  FocusSession? _activeSession;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  String _goal = '';
  int _selectedDuration = 25;
  String _motivationalQuote = '';
  List<FocusSession> _sessionHistory = [];
  Map<String, dynamic> _stats = {};
  Map<String, int> _dailyFocus = {};
  bool _isLoading = false;
  String _selectedSound = '';
  bool _isSoundPlaying = false;

  final List<int> _durationOptions = [15, 25, 45, 60, 90];
  final Map<String, String> _ambientSounds = {
    'rain': 'Rain',
    'lofi': 'Lo-Fi',
    'white_noise': 'White Noise',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _checkActiveSession();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final history = await _service.getSessionHistory();
    final stats = await _service.getFocusStats();
    final dailyFocus = await _service.getDailyFocusTime(7);
    final quote = await _service.getMotivationalQuote();
    setState(() {
      _sessionHistory = history;
      _stats = stats;
      _dailyFocus = dailyFocus;
      _motivationalQuote = quote;
      _isLoading = false;
    });
  }

  Future<void> _checkActiveSession() async {
    final session = await _service.getActiveSession();
    if (session != null && session.endTime == null) {
      if (session.isPaused) {
        setState(() {
          _activeSession = session;
          _goal = session.goal;
          _selectedDuration = session.plannedDuration ~/ 60;
          _elapsedSeconds = session.actualTime;
          _remainingSeconds = session.plannedDuration - session.actualTime;
        });
      } else {
        final elapsed = DateTime.now().difference(session.startTime).inSeconds - session.actualTime;
        setState(() {
          _activeSession = session;
          _goal = session.goal;
          _selectedDuration = session.plannedDuration ~/ 60;
          _elapsedSeconds = session.actualTime + elapsed;
          _remainingSeconds = session.plannedDuration - (_elapsedSeconds);
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeSession != null && !_activeSession!.isPaused) {
        setState(() {
          _elapsedSeconds++;
          _remainingSeconds = (_activeSession!.plannedDuration - _elapsedSeconds).clamp(0, _activeSession!.plannedDuration);
        });
        if (_remainingSeconds <= 0) {
          _completeSession();
        }
      }
    });
  }

  Future<void> _startFocusSession() async {
    if (_goal.isEmpty) return;
    HapticFeedback.mediumImpact();
    await _service.startFocusSession(
      goal: _goal,
      duration: Duration(minutes: _selectedDuration),
    );
    final session = await _service.getActiveSession();
    setState(() {
      _activeSession = session;
      _elapsedSeconds = 0;
      _remainingSeconds = _selectedDuration * 60;
    });
    _startTimer();
  }

  Future<void> _pauseSession() async {
    HapticFeedback.selectionClick();
    await _service.pauseSession();
    _timer?.cancel();
    setState(() {
      _activeSession = _activeSession?.copyWith(isPaused: true);
    });
  }

  Future<void> _resumeSession() async {
    HapticFeedback.selectionClick();
    await _service.resumeSession();
    final session = await _service.getActiveSession();
    setState(() {
      _activeSession = session;
    });
    _startTimer();
  }

  Future<void> _endSession() async {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    await _service.endFocusSession();
    await _loadData();
    setState(() {
      _activeSession = null;
      _elapsedSeconds = 0;
      _remainingSeconds = 0;
    });
  }

  Future<void> _completeSession() async {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    await _service.endFocusSession();
    await _loadData();
    setState(() {
      _activeSession = null;
      _elapsedSeconds = 0;
      _remainingSeconds = 0;
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildTimerCircle() {
    final totalSeconds = _activeSession?.plannedDuration ?? 1;
    final progress = 1.0 - (_remainingSeconds / totalSeconds).clamp(0.0, 1.0);
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDuration(_remainingSeconds),
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _goal,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_activeSession == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus Goal',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) => setState(() => _goal = value),
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'What are you focusing on?',
                      hintStyle: GoogleFonts.outfit(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Duration',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _durationOptions.map((duration) {
                      final isSelected = _selectedDuration == duration;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDuration = duration),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00BCD4) : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00BCD4) : Colors.white12,
                            ),
                          ),
                          child: Text(
                            '${duration}m',
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ambient Sounds',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _ambientSounds.entries.map((entry) {
                      final isSelected = _selectedSound == entry.key;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedSound = isSelected ? '' : entry.key);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00BCD4).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00BCD4) : Colors.white12,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getSoundIcon(entry.key),
                                color: isSelected ? const Color(0xFF00BCD4) : Colors.white54,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.value,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isSelected ? const Color(0xFF00BCD4) : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goal.isNotEmpty ? _startFocusSession : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                ),
                child: Text(
                  'Start Focus',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_motivationalQuote.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, color: Color(0xFF00BCD4), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _motivationalQuote,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildTimerCircle(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Elapsed', _formatDuration(_elapsedSeconds)),
                    _buildStatItem('Goal', _goal),
                    _buildStatItem('Distractions', '${_service.getDistractionCount()}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_activeSession!.isPaused) ...[
                ElevatedButton(
                  onPressed: _resumeSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: Text(
                    'Resume',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _pauseSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: Text(
                    'Pause',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _endSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: Text(
                    'End',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          if (_selectedSound.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getSoundIcon(_selectedSound), color: const Color(0xFF00BCD4)),
                      const SizedBox(width: 12),
                      Text(
                        _ambientSounds[_selectedSound] ?? '',
                        style: GoogleFonts.outfit(color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _isSoundPlaying = !_isSoundPlaying);
                    },
                    icon: Icon(
                      _isSoundPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: const Color(0xFF00BCD4),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_sessionHistory.isEmpty) {
      return Center(
        child: Text(
          'No focus sessions yet',
          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    final sortedSessions = _sessionHistory.reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSessions.length,
      itemBuilder: (context, index) {
        final session = sortedSessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getScoreColor(session.score).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${session.score}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(session.score),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.goal,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDuration(session.actualTime)} • ${session.endTime != null ? _formatDate(session.endTime!) : 'Active'}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${session.plannedDuration ~/ 60}m',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF00BCD4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${session.distractions} distractions',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    if (_stats.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
    }
    final weekStats = _stats['week'] ?? {};
    final allTimeStats = _stats['allTime'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  'Total Focus',
                  _formatDuration(weekStats['totalTime'] ?? 0),
                  Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  'Sessions',
                  '${weekStats['sessions'] ?? 0}',
                  Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  'Avg Duration',
                  _formatDuration(weekStats['avgDuration'] ?? 0),
                  Icons.analytics_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  'Streak',
                  '${weekStats['streak'] ?? 0} days',
                  Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Daily Focus (Last 7 Days)',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: _dailyFocus.isEmpty
                ? Center(
                    child: Text(
                      'No data yet',
                      style: GoogleFonts.outfit(color: Colors.white54),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _dailyFocus.values.isEmpty ? 100 : _dailyFocus.values.reduce((a, b) => a > b ? a : b).toDouble() + 60,
                      barTouchData: const BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final keys = _dailyFocus.keys.toList();
                              if (value.toInt() >= 0 && value.toInt() < keys.length) {
                                return Text(
                                  keys[value.toInt()],
                                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: _dailyFocus.entries.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final value = entry.value.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value.toDouble(),
                              color: const Color(0xFF00BCD4),
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            'All Time',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _buildStatsRow('Total Focus Time', _formatDuration(allTimeStats['totalTime'] ?? 0)),
                const SizedBox(height: 12),
                _buildStatsRow('Total Sessions', '${allTimeStats['sessions'] ?? 0}'),
                const SizedBox(height: 12),
                _buildStatsRow('Average Session', _formatDuration(allTimeStats['avgDuration'] ?? 0)),
                const SizedBox(height: 12),
                _buildStatsRow('Longest Streak', '${allTimeStats['streak'] ?? 0} days'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return const Color(0xFF00BCD4);
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getSoundIcon(String sound) {
    switch (sound) {
      case 'rain':
        return Icons.water_drop_outlined;
      case 'lofi':
        return Icons.music_note_outlined;
      case 'white_noise':
        return Icons.waves_outlined;
      default:
        return Icons.music_note_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Focus Mode Coach',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00BCD4),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(),
                _buildHistoryTab(),
                _buildStatsTab(),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}

extension FocusSessionCopyWith on FocusSession {
  FocusSession copyWith({
    String? id,
    String? goal,
    int? plannedDuration,
    int? actualTime,
    DateTime? startTime,
    DateTime? endTime,
    bool? isPaused,
    int? distractions,
    int? score,
    String? notes,
  }) {
    return FocusSession(
      id: id ?? this.id,
      goal: goal ?? this.goal,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualTime: actualTime ?? this.actualTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isPaused: isPaused ?? this.isPaused,
      distractions: distractions ?? this.distractions,
      score: score ?? this.score,
      notes: notes ?? this.notes,
    );
  }
}
