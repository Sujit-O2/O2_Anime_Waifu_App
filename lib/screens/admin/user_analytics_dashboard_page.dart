import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/user_profile/affection_service.dart';

class UserAnalyticsDashboardPage extends StatelessWidget {
  const UserAnalyticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AffectionService.instance;
    final points = service.points;
    final streak = service.streakDays;
    final level = _levelForPoints(points);
    final currentLevelPoints = _thresholds[level];
    final nextLevelPoints = level >= _thresholds.length - 1
        ? currentLevelPoints
        : _thresholds[level + 1];
    final progress = level >= _thresholds.length - 1
        ? 1.0
        : (points - currentLevelPoints) /
            (nextLevelPoints - currentLevelPoints);
    final hourActivity = _hourActivity();
    final peakHour = hourActivity.entries.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    final mood = points >= 1200
        ? 'achievement'
        : streak >= 4
            ? 'motivated'
            : 'neutral';

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: V2Theme.surfaceDark,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {},
            color: V2Theme.primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white60,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Analytics Dashboard',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Momentum, affection, and relationship health at a glance.',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      ProgressRing(
                        progress: progress.clamp(0.0, 1.0),
                        size: 116,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '$level',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Level',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Relationship Overview',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              points >= 5000
                                  ? 'This bond is deep and well-established.'
                                  : 'You are steadily stacking affection and trust.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              level >= _thresholds.length - 1
                                  ? 'Maximum level reached'
                                  : '${nextLevelPoints - points} XP to the next level',
                              style: GoogleFonts.outfit(
                                color: V2Theme.secondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                WaifuCommentary(mood: mood),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatCard(
                        title: 'Total XP',
                        value: '$points',
                        icon: Icons.auto_awesome_rounded,
                        color: V2Theme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Current Streak',
                        value: '$streak d',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatCard(
                        title: 'Peak Hour',
                        value: '${peakHour.key.toString().padLeft(2, '0')}:00',
                        icon: Icons.schedule_rounded,
                        color: V2Theme.secondaryColor,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Affinity Tier',
                        value: _tierLabel(points),
                        icon: Icons.favorite_rounded,
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Weekly Intensity',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A lightweight pulse view of how often you tend to show up across the week.',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children:
                            List<Widget>.generate(_weeklyPulse.length, (index) {
                          final value = _weeklyPulse[index];
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 320),
                                    height: 28 + value * 78,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      gradient: const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: <Color>[
                                          V2Theme.primaryColor,
                                          V2Theme.secondaryColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _weekDays[index],
                                    style: GoogleFonts.outfit(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Peak Hours',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The brighter columns show when you are most likely to interact.',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 104,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List<Widget>.generate(24, (hour) {
                            final value = hourActivity[hour]!;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                child: Tooltip(
                                  message:
                                      '${hour.toString().padLeft(2, '0')}:00',
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 260),
                                    height: 10 + value * 82,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: hour == peakHour.key
                                          ? V2Theme.secondaryColor
                                          : V2Theme.secondaryColor.withValues(
                                              alpha: 0.16 + value * 0.7,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Growth Signals',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _growthRow(
                        label: 'Daily chats',
                        value: (points / 1600).clamp(0.2, 0.95),
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(height: 10),
                      _growthRow(
                        label: 'Trust build',
                        value: (streak / 14).clamp(0.1, 0.92),
                        color: V2Theme.secondaryColor,
                      ),
                      const SizedBox(height: 10),
                      _growthRow(
                        label: 'Affection depth',
                        value: (points / 3200).clamp(0.15, 0.98),
                        color: Colors.pinkAccent,
                      ),
                      const SizedBox(height: 10),
                      _growthRow(
                        label: 'Feature usage',
                        value: ((points / 25) % 100) / 100,
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const List<int> _thresholds = <int>[
    0,
    50,
    150,
    300,
    500,
    800,
    1200,
    1800,
    2600,
    3600,
    5000,
  ];

  static const List<double> _weeklyPulse = <double>[
    0.45,
    0.62,
    0.72,
    0.58,
    0.86,
    0.78,
    0.68,
  ];

  static const List<String> _weekDays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static int _levelForPoints(int points) {
    for (var index = _thresholds.length - 1; index >= 0; index--) {
      if (points >= _thresholds[index]) {
        return index;
      }
    }
    return 0;
  }

  static String _tierLabel(int points) {
    if (points >= 5000) {
      return 'Soulmate';
    }
    if (points >= 2000) {
      return 'Sweetheart';
    }
    if (points >= 750) {
      return 'Close';
    }
    if (points >= 150) {
      return 'Growing';
    }
    return 'New';
  }

  static Map<int, double> _hourActivity() {
    return <int, double>{
      for (var hour = 0; hour < 24; hour++)
        hour: switch (hour) {
          >= 0 && < 6 => 0.12,
          >= 6 && < 9 => 0.35,
          >= 9 && < 12 => 0.55,
          >= 12 && < 15 => 0.42,
          >= 15 && < 18 => 0.68,
          >= 18 && < 21 => 0.94,
          >= 21 && < 23 => 0.81,
          _ => 0.3,
        },
    };
  }

  Widget _growthRow({
    required String label,
    required double value,
    required Color color,
  }) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(value.clamp(0.0, 1.0) * 100).round()}%',
          style: GoogleFonts.outfit(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}




