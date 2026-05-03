import 'dart:convert';
import 'dart:math' as math;
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:anime_waifu/services/utilities_core/mobile_first_ui_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeditationGuidePage extends StatefulWidget {
  const MeditationGuidePage({super.key});

  @override
  State<MeditationGuidePage> createState() => _MeditationGuidePageState();
}

class _MeditationGuidePageState extends State<MeditationGuidePage> {
  List<MeditationSession> _sessions = [];
  bool _isMeditating = false;
  DateTime? _sessionStartTime;
  int _sessionDuration = 0;
  String _currentSession = '';
  double _focusScore = 0.0;
  int _breathRate = 0;

  @override
  void initState() {
    super.initState();
    _loadMeditationData();
    _initializeSessions();
  }

  Future<void> _loadMeditationData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('meditation_sessions');
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        if (!mounted) return;
        setState(() => _sessions = list
            .map((e) => MeditationSession.fromJson(e as Map<String, dynamic>))
            .toList());
      } catch (_) {}
    }
  }

  Future<void> _saveMeditationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'meditation_sessions', jsonEncode(_sessions.map((s) => s.toJson()).toList()));
  }

  void _initializeSessions() {
    _sessions = [
      MeditationSession(
        id: 'med_1',
        title: 'Calm Mind',
        description: 'A gentle introduction to mindfulness meditation',
        duration: 5,
        type: 'Mindfulness',
        icon: Icons.self_improvement,
        color: Colors.blueAccent,
      ),
      MeditationSession(
        id: 'med_2',
        title: 'Deep Relaxation',
        description: 'Release tension and achieve deep relaxation',
        duration: 10,
        type: 'Relaxation',
        icon: Icons.healing,
        color: Colors.purpleAccent,
      ),
      MeditationSession(
        id: 'med_3',
        title: 'Focus Boost',
        description: 'Sharpen your concentration and mental clarity',
        duration: 7,
        type: 'Focus',
        icon: Icons.center_focus_strong,
        color: Colors.greenAccent,
      ),
      MeditationSession(
        id: 'med_4',
        title: 'Stress Relief',
        description: 'Let go of anxiety and find inner peace',
        duration: 15,
        type: 'Stress Relief',
        icon: Icons.psychology,
        color: Colors.orangeAccent,
      ),
      MeditationSession(
        id: 'med_5',
        title: 'Loving Kindness',
        description: 'Cultivate compassion and positive emotions',
        duration: 12,
        type: 'Loving Kindness',
        icon: Icons.favorite,
        color: Colors.pinkAccent,
      ),
    ];
  }

  void _startMeditation(MeditationSession session) {
    setState(() {
      _isMeditating = true;
      _sessionStartTime = DateTime.now();
      _sessionDuration = session.duration * 60; // Convert to seconds
      _currentSession = session.title;
      _focusScore = 0.0;
      _breathRate = 12; // Starting breath rate
    });
    HapticFeedback.selectionClick();
    
    // Start meditation timer
    _startMeditationTimer();
  }

  void _stopMeditation() {
    if (_sessionStartTime == null) return;
    
    // Calculate focus score based on consistency (simulated)
    _focusScore = 60 + (math.Random().nextDouble() * 30); // 60-90 range
    
    setState(() {
      _isMeditating = false;
      _sessions.firstWhere((s) => s.title == _currentSession).completedCount++;
      _saveMeditationData();
    });
    
    HapticFeedback.selectionClick();
  }

  void _startMeditationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_isMeditating) return;
      
      setState(() {
        if (_sessionDuration > 0) {
          _sessionDuration--;
          // Simulate changing breath rate during meditation
          _breathRate = 12 + (math.Random().nextDouble() * 4).toInt(); // 12-16 breaths per minute
          // Simulate focus score fluctuation
          _focusScore = 70 + (math.Random().nextDouble() * 20); // 70-90 range
        } else {
          _stopMeditation();
          return;
        }
      });
      
      if (_isMeditating) {
        _startMeditationTimer();
      }
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: tokens.textSoft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Meditation Guide',
            style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 0.5)),
        actions: [
          if (_isMeditating)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('MEDITATING',
                      style: GoogleFonts.outfit(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(children: [
            // Header Section with improved design
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primary.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.self_improvement_rounded,
                            color: primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MINDFULNESS CENTER',
                                style: GoogleFonts.outfit(
                                  color: tokens.textSoft,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                )),
                            const SizedBox(height: 4),
                            Text('AI-Guided Meditation',
                                style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Personalized meditation sessions with biofeedback integration for deeper mindfulness and relaxation.',
                      style: GoogleFonts.outfit(
                          color: tokens.textSoft,
                          fontSize: 14,
                          height: 1.5)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main Content with smooth transitions
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: animation.drive(Tween(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  )),
                  child: child,
                ),
              ),
              child: _isMeditating
                  ? _buildMeditationSessionView()
                  : _buildSessionList(),
            ),

            const SizedBox(height: 32),

            // Stats Section (only show when not meditating and has data)
            if (!_isMeditating && _sessions.any((s) => s.completedCount > 0))
              _buildStatsSection(),
          ]),
        ),
      ),
    );
  }

  Widget _buildMeditationSessionView() {
    final session = _sessions.firstWhere((s) => s.title == _currentSession,
        orElse: () => _sessions.first);
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Column(
      key: const ValueKey('meditation_session'),
      children: [
        // Main meditation card with premium design
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                session.color.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: session.color.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: session.color.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Session icon with breathing animation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: session.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: session.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: AnimatedScale(
                  scale: _isMeditating ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeInOut,
                  child: Icon(session.icon,
                      color: session.color, size: 48),
                ),
              ),

              const SizedBox(height: 20),

              // Session title and description
              Text(session.title,
                  style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(session.description,
                  style: GoogleFonts.outfit(
                      color: tokens.textSoft,
                      fontSize: 14,
                      height: 1.5),
                  textAlign: TextAlign.center),

              const SizedBox(height: 24),

              // Timer display with circular progress
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      session.color.withValues(alpha: 0.2),
                      session.color.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: session.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TIME LEFT',
                          style: GoogleFonts.outfit(
                              color: tokens.textSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(_formatDuration(_sessionDuration),
                          style: GoogleFonts.outfit(
                              color: theme.colorScheme.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Metrics row with improved design
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMetricCard(
                    icon: Icons.favorite_rounded,
                    label: 'Focus',
                    value: '${_focusScore.toStringAsFixed(0)}%',
                    color: Colors.pinkAccent,
                  ),
                  const SizedBox(width: 16),
                  _buildMetricCard(
                    icon: Icons.air_rounded,
                    label: 'Breath',
                    value: '$_breathRate/min',
                    color: Colors.lightBlueAccent,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // End session button with premium styling
              HapticButton(
                onPressed: _stopMeditation,
                feedbackType: HapticFeedbackType.success,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.redAccent.withValues(alpha: 0.9),
                        Colors.redAccent.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stop_circle_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('End Session',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Waifu commentary with better spacing
        const WaifuCommentary(mood: 'peaceful'),
      ],
    );
  }

  Widget _buildSessionList() {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Column(
      key: const ValueKey('session_list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CHOOSE YOUR SESSION',
            style: GoogleFonts.outfit(
              color: tokens.textSoft,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sessions.length,
          itemBuilder: (context, index) {
            final session = _sessions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HapticButton(
                onPressed: () => _startMeditation(session),
                feedbackType: HapticFeedbackType.light,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        session.color.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: session.color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: session.color.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon container with improved design
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              session.color.withValues(alpha: 0.2),
                              session.color.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: session.color.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(session.icon,
                            color: session.color, size: 28),
                      ),

                      const SizedBox(width: 16),

                      // Content section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session.title,
                                style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(session.description,
                                style: GoogleFonts.outfit(
                                    color: tokens.textSoft,
                                    fontSize: 13,
                                    height: 1.4)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    color: tokens.textMuted, size: 14),
                                const SizedBox(width: 4),
                                Text('${session.duration} min',
                                    style: GoogleFonts.outfit(
                                        color: tokens.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: session.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(session.type,
                                      style: GoogleFonts.outfit(
                                          color: session.color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Completion count and arrow
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (session.completedCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: session.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: session.color, size: 12),
                                  const SizedBox(width: 4),
                                  Text('${session.completedCount}',
                                      style: GoogleFonts.outfit(
                                          color: session.color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Icon(Icons.chevron_right_rounded,
                              color: tokens.textMuted, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: GoogleFonts.outfit(
                      color: context.appTokens.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              Text(value,
                  style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR PROGRESS',
            style: GoogleFonts.outfit(
              color: tokens.textSoft,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Total Sessions',
                _sessions.fold<int>(0, (sum, s) => sum + s.completedCount).toString(),
                Icons.psychology_alt_rounded,
                Colors.pinkAccent,
              ),
              Container(
                width: 1,
                height: 40,
                color: tokens.outline,
              ),
              _buildStatItem(
                'Total Minutes',
                _sessions
                    .fold<int>(0, (sum, s) => sum + (s.duration * s.completedCount))
                    .toString(),
                Icons.timer_rounded,
                Colors.amberAccent,
              ),
              Container(
                width: 1,
                height: 40,
                color: tokens.outline,
              ),
              _buildStatItem(
                'Avg Focus',
                '${(_sessions.where((s) => s.completedCount > 0)
                        .map((s) => s.avgFocusScore)
                        .reduce((a, b) => (a + b) / 2)
                        .toStringAsFixed(0))}%',
                Icons.center_focus_strong_rounded,
                Colors.greenAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.outfit(
                color: tokens.textSoft,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ],
    );
  }
}

class MeditationSession {
  final String id;
  final String title;
  final String description;
  final int duration; // in minutes
  final String type;
  final IconData icon;
  final Color color;
  int completedCount;
  double avgFocusScore;

  MeditationSession({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.type,
    required this.icon,
    required this.color,
    this.completedCount = 0,
    this.avgFocusScore = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'duration': duration,
        'type': type,
        'icon': icon.toString(),
        'color': color.value,
        'completedCount': completedCount,
        'avgFocusScore': avgFocusScore,
      };

  factory MeditationSession.fromJson(Map<String, dynamic> json) => MeditationSession(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        duration: json['duration'] as int,
        type: json['type'] as String,
        icon: _iconFromString(json['icon'] as String),
        color: Color(json['color'] as int),
        completedCount: json['completedCount'] as int,
        avgFocusScore: json['avgFocusScore'] as double,
      );

  static IconData _iconFromString(String iconString) {
    // Simple mapping for common icons
    switch (iconString) {
      case 'Icons.self_improvement':
        return Icons.self_improvement;
      case 'Icons.healing':
        return Icons.healing;
      case 'Icons.center_focus_strong':
        return Icons.center_focus_strong;
      case 'Icons.psychology':
        return Icons.psychology;
      case 'Icons.favorite':
        return Icons.favorite;
      default:
        return Icons.psychology; // default
    }
  }
}

class MeditationSessionRecord {
  final String id;
  final String sessionId;
  final String title;
  final int duration; // in minutes
  final double focusScore;
  final int breathRate;
  final DateTime timestamp;

  MeditationSessionRecord({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.duration,
    required this.focusScore,
    required this.breathRate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'title': title,
        'duration': duration,
        'focusScore': focusScore,
        'breathRate': breathRate,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MeditationSessionRecord.fromJson(Map<String, dynamic> json) => MeditationSessionRecord(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        title: json['title'] as String,
        duration: json['duration'] as int,
        focusScore: json['focusScore'] as double,
        breathRate: json['breathRate'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

