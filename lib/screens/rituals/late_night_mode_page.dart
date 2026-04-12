import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class LateNightModePage extends StatefulWidget {
  const LateNightModePage({super.key});

  @override
  State<LateNightModePage> createState() => _LateNightModePageState();
}

class _LateNightModePageState extends State<LateNightModePage> {
  static const String _enabledKey = 'late_night_enabled_v2';
  static const String _startKey = 'late_night_start_v2';
  static const String _endKey = 'late_night_end_v2';
  static const String _cozyVoiceKey = 'late_night_cozy_voice_v2';
  static const String _sleepReminderKey = 'late_night_sleep_reminder_v2';
  static const String _reduceAnimationsKey = 'late_night_reduce_animations_v2';

  bool _lateNightEnabled = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);
  bool _cozyVoice = true;
  bool _sleepReminder = false;
  bool _reduceAnimations = false;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _restoreSettings();
  }

  bool get _isCurrentlyNight {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return startMinutes > endMinutes
        ? (nowMinutes >= startMinutes || nowMinutes <= endMinutes)
        : (nowMinutes >= startMinutes && nowMinutes <= endMinutes);
  }

  Future<void> _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _lateNightEnabled = prefs.getBool(_enabledKey) ?? true;
      _startTime = _decodeTime(
        prefs.getString(_startKey),
        fallback: const TimeOfDay(hour: 23, minute: 0),
      );
      _endTime = _decodeTime(
        prefs.getString(_endKey),
        fallback: const TimeOfDay(hour: 6, minute: 0),
      );
      _cozyVoice = prefs.getBool(_cozyVoiceKey) ?? true;
      _sleepReminder = prefs.getBool(_sleepReminderKey) ?? false;
      _reduceAnimations = prefs.getBool(_reduceAnimationsKey) ?? false;
      _restored = true;
    });
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, _lateNightEnabled);
    await prefs.setString(_startKey, _encodeTime(_startTime));
    await prefs.setString(_endKey, _encodeTime(_endTime));
    await prefs.setBool(_cozyVoiceKey, _cozyVoice);
    await prefs.setBool(_sleepReminderKey, _sleepReminder);
    await prefs.setBool(_reduceAnimationsKey, _reduceAnimations);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: V2Theme.primaryColor,
            surface: V2Theme.surfaceLight,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
    await _persistSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isNightActive = _lateNightEnabled && _isCurrentlyNight;
    final mood = isNightActive
        ? 'relaxed'
        : _lateNightEnabled
            ? 'motivated'
            : 'neutral';

    if (!_restored) {
      return const Scaffold(
        backgroundColor: V2Theme.surfaceDark,
        body: Center(
          child: CircularProgressIndicator(color: V2Theme.primaryColor),
        ),
      );
    }

    return FeaturePageV2(
      title: 'Late Night Mode',
      subtitle: 'Quiet the app down and switch into a softer night rhythm.',
      onBack: () => Navigator.of(context).pop(),
      content: RefreshIndicator(
        onRefresh: _restoreSettings,
        color: V2Theme.primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: <Widget>[
                GlassCard(
                  margin: EdgeInsets.zero,
                  glow: true,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isNightActive
                              ? const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF5E6BFF),
                                    Color(0xFF9A7BFF),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFFFF9F5C),
                                    Color(0xFFFFC857),
                                  ],
                                ),
                        ),
                        child: Icon(
                          isNightActive
                              ? Icons.nights_stay_rounded
                              : Icons.light_mode_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              isNightActive
                                  ? 'Night Mode Active'
                                  : _lateNightEnabled
                                      ? 'Scheduled and Ready'
                                      : 'Night Mode Disabled',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isNightActive
                                  ? 'Zero Two switches to a calmer, softer presence right now.'
                                  : 'The schedule is ${_formatTime(_startTime)} to ${_formatTime(_endTime)}.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                height: 1.4,
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
                        title: 'Status',
                        value: isNightActive
                            ? 'Live'
                            : _lateNightEnabled
                                ? 'Scheduled'
                                : 'Off',
                        icon: Icons.bedtime_rounded,
                        color: V2Theme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Window',
                        value:
                            '${_formatTime(_startTime)}-${_formatTime(_endTime)}',
                        icon: Icons.schedule_rounded,
                        color: V2Theme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatCard(
                        title: 'Cozy Voice',
                        value: _cozyVoice ? 'On' : 'Off',
                        icon: Icons.record_voice_over_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Sleep Reminders',
                        value: _sleepReminder ? 'On' : 'Off',
                        icon: Icons.notifications_active_rounded,
                        color: Colors.lightGreenAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _settingTile(
                        icon: Icons.nights_stay_outlined,
                        title: 'Enable Late Night Mode',
                        subtitle:
                            'Automatically shift the app into a quieter night presentation.',
                        value: _lateNightEnabled,
                        onChanged: (value) async {
                          setState(() => _lateNightEnabled = value);
                          await _persistSettings();
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _timeCard(
                              label: 'Starts',
                              time: _startTime,
                              onTap: () => _pickTime(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _timeCard(
                              label: 'Ends',
                              time: _endTime,
                              onTap: () => _pickTime(false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _settingTile(
                        icon: Icons.record_voice_over_outlined,
                        title: 'Cozy Voice Style',
                        subtitle:
                            'Use softer voice delivery and calmer reply pacing.',
                        value: _cozyVoice,
                        onChanged: (value) async {
                          setState(() => _cozyVoice = value);
                          await _persistSettings();
                        },
                      ),
                      const SizedBox(height: 8),
                      _settingTile(
                        icon: Icons.bed_outlined,
                        title: 'Sleep Reminder',
                        subtitle:
                            'Let Zero Two nudge you toward rest during the window.',
                        value: _sleepReminder,
                        onChanged: (value) async {
                          setState(() => _sleepReminder = value);
                          await _persistSettings();
                        },
                      ),
                      const SizedBox(height: 8),
                      _settingTile(
                        icon: Icons.animation_outlined,
                        title: 'Reduce Animations',
                        subtitle:
                            'Tone down motion for a calmer night experience.',
                        value: _reduceAnimations,
                        onChanged: (value) async {
                          setState(() => _reduceAnimations = value);
                          await _persistSettings();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: V2Theme.primaryColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Get some rest, darling. I will still be here when you wake up, and we do not need to rush the night.',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: V2Theme.primaryColor,
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        secondary: Icon(icon, color: Colors.white70),
      ),
    );
  }

  Widget _timeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(time),
              style: GoogleFonts.outfit(
                color: V2Theme.secondaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to change',
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _encodeTime(TimeOfDay time) => '${time.hour}:${time.minute}';

  static TimeOfDay _decodeTime(
    String? raw, {
    required TimeOfDay fallback,
  }) {
    if (raw == null || !raw.contains(':')) {
      return fallback;
    }
    final parts = raw.split(':');
    final hour = int.tryParse(parts.first);
    final minute = int.tryParse(parts.last);
    if (hour == null || minute == null) {
      return fallback;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}



