import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WellnessRemindersPage extends StatefulWidget {
  const WellnessRemindersPage({super.key});

  @override
  State<WellnessRemindersPage> createState() => _WellnessRemindersPageState();
}

class _WellnessRemindersPageState extends State<WellnessRemindersPage> {
  bool _hydration = false;
  bool _eyeCare = false;
  bool _posture = false;
  bool _morningBriefing = false;
  int _hydrationIntervalMins = 60;
  TimeOfDay _morningTime = const TimeOfDay(hour: 7, minute: 30);

  int get _enabledCount {
    int count = 0;
    if (_hydration) count++;
    if (_eyeCare) count++;
    if (_posture) count++;
    if (_morningBriefing) count++;
    return count;
  }

  String get _commentaryMood {
    if (_enabledCount >= 3) {
      return 'achievement';
    }
    if (_enabledCount >= 1) {
      return 'motivated';
    }
    return 'relaxed';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _hydration = prefs.getBool('reminders_hydration') ?? false;
      _eyeCare = prefs.getBool('reminders_eyecare') ?? false;
      _posture = prefs.getBool('reminders_posture') ?? false;
      _morningBriefing = prefs.getBool('reminders_morning') ?? false;
      _hydrationIntervalMins = prefs.getInt('reminders_hydration_mins') ?? 60;
      final int h = prefs.getInt('morning_time_hour') ?? 7;
      final int m = prefs.getInt('morning_time_min') ?? 30;
      _morningTime = TimeOfDay(hour: h, minute: m);
    });
  }

  Future<void> _save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_hydration', _hydration);
    await prefs.setBool('reminders_eyecare', _eyeCare);
    await prefs.setBool('reminders_posture', _posture);
    await prefs.setBool('reminders_morning', _morningBriefing);
    await prefs.setInt('reminders_hydration_mins', _hydrationIntervalMins);
    await prefs.setInt('morning_time_hour', _morningTime.hour);
    await prefs.setInt('morning_time_min', _morningTime.minute);
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> _pickMorningTime() async {
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: _morningTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amberAccent,
              onPrimary: Colors.black,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected != null) {
      setState(() => _morningTime = selected);
      await _save();
      if (mounted) {
        showSuccessSnackbar(context, 'Morning briefing time updated.');
      }
    }
  }

  Widget _card({
    required String emoji,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color color = Colors.pinkAccent,
    Widget? extra,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: value
            ? color.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: value
              ? color.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: (bool next) async {
                  HapticFeedback.selectionClick();
                  setState(() => onChanged(next));
                  await _save();
                },
                activeColor: color,
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white12,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (extra != null && value) ...[
            const SizedBox(height: 12),
            extra,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: V2Theme.primaryColor,
          backgroundColor: V2Theme.surfaceLight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                      children: [
                        Text(
                          '👍 WELLNESS REMINDERS',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Build gentle daily support',
                          style: GoogleFonts.outfit(
                            color: V2Theme.secondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedEntry(
                index: 0,
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder cockpit',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_enabledCount of 4 wellness nudges active',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Keep hydration, posture, eye care, and mornings aligned without overloading your day.',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ProgressRing(
                        progress: _enabledCount / 4,
                        foreground: V2Theme.primaryColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: V2Theme.primaryColor,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_enabledCount',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'On',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              WaifuCommentary(mood: _commentaryMood),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Hydration',
                      value: _hydration ? '${_hydrationIntervalMins}m' : 'Off',
                      icon: Icons.water_drop_rounded,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Morning',
                      value: _morningBriefing ? _morningTime.format(context) : 'Off',
                      icon: Icons.wb_sunny_rounded,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Eye Care',
                      value: _eyeCare ? 'On' : 'Off',
                      icon: Icons.visibility_rounded,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Posture',
                      value: _posture ? 'On' : 'Off',
                      icon: Icons.accessibility_new_rounded,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _card(
                emoji: '💧',
                title: 'Hydration Reminder',
                subtitle: 'Get a water reminder every set interval.',
                value: _hydration,
                onChanged: (bool value) => _hydration = value,
                color: Colors.cyanAccent,
                extra: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remind every $_hydrationIntervalMins minutes',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: _hydrationIntervalMins.toDouble(),
                      min: 15,
                      max: 120,
                      divisions: 7,
                      activeColor: Colors.cyanAccent,
                      inactiveColor: Colors.white12,
                      label: '${_hydrationIntervalMins}m',
                      onChanged: (double value) async {
                        setState(() => _hydrationIntervalMins = value.round());
                        await _save();
                      },
                    ),
                  ],
                ),
              ),
              _card(
                emoji: '👁️',
                title: '20-20-20 Eye Care',
                subtitle: 'Look away from the screen every 20 minutes.',
                value: _eyeCare,
                onChanged: (bool value) => _eyeCare = value,
                color: Colors.greenAccent,
              ),
              _card(
                emoji: '🪑',
                title: 'Posture Check',
                subtitle: 'A quick nudge to sit straighter every hour.',
                value: _posture,
                onChanged: (bool value) => _posture = value,
                color: Colors.orangeAccent,
              ),
              _card(
                emoji: '🌅',
                title: 'Morning Briefing',
                subtitle: 'Start the day with a timed Zero Two check-in.',
                value: _morningBriefing,
                onChanged: (bool value) => _morningBriefing = value,
                color: Colors.amberAccent,
                extra: Row(
                  children: [
                    Text(
                      'Time: ${_morningTime.format(context)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickMorningTime,
                      icon: const Icon(
                        Icons.access_time_outlined,
                        color: Colors.amberAccent,
                        size: 16,
                      ),
                      label: Text(
                        'Change',
                        style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GlassCard(
                margin: EdgeInsets.zero,
                child: Text(
                  'Reminder delivery still depends on the app being active or allowed to run in the background by your device.',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



