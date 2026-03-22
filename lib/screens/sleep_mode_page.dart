import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sleep Mode page - silences all app notifications between user-set sleep hours.
class SleepModePage extends StatefulWidget {
  const SleepModePage({super.key});

  @override
  State<SleepModePage> createState() => _SleepModePageState();
}

class _SleepModePageState extends State<SleepModePage> {
  bool _sleepModeEnabled = false;
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  bool _sendGoodnight = true;
  bool _sendGoodmorning = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sleepModeEnabled = prefs.getBool('sleep_mode_enabled') ?? false;
      _sleepTime = TimeOfDay(
        hour: prefs.getInt('sleep_hour') ?? 22,
        minute: prefs.getInt('sleep_minute') ?? 0,
      );
      _wakeTime = TimeOfDay(
        hour: prefs.getInt('wake_hour') ?? 7,
        minute: prefs.getInt('wake_minute') ?? 0,
      );
      _sendGoodnight = prefs.getBool('sleep_goodnight') ?? true;
      _sendGoodmorning = prefs.getBool('sleep_goodmorning') ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sleep_mode_enabled', _sleepModeEnabled);
    await prefs.setInt('sleep_hour', _sleepTime.hour);
    await prefs.setInt('sleep_minute', _sleepTime.minute);
    await prefs.setInt('wake_hour', _wakeTime.hour);
    await prefs.setInt('wake_minute', _wakeTime.minute);
    await prefs.setBool('sleep_goodnight', _sendGoodnight);
    await prefs.setBool('sleep_goodmorning', _sendGoodmorning);
  }

  Future<void> _pickTime({required bool isSleep}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleep ? _sleepTime : _wakeTime,
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.pinkAccent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isSleep) {
          _sleepTime = picked;
        } else {
          _wakeTime = picked;
        }
      });
      await _save();
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0613),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sleep Mode',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade900,
                  Colors.deepPurple.shade900,
                ],
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🌙', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text('Sleep Mode',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Zero Two will be quiet during your sleep hours and greet you warmly each morning~',
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          // Enable toggle
          _settingsTile(
            icon: Icons.bedtime_rounded,
            iconColor: Colors.indigoAccent,
            title: 'Enable Sleep Mode',
            subtitle: _sleepModeEnabled ? 'Active — notifications silenced during sleep' : 'Disabled',
            trailing: Switch(
              value: _sleepModeEnabled,
              onChanged: (v) async {
                setState(() => _sleepModeEnabled = v);
                await _save();
              },
              activeColor: Colors.pinkAccent,
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 12),
          // Sleep time  
          _settingsTile(
            icon: Icons.nightlight_round,
            iconColor: Colors.blueAccent,
            title: 'Bedtime',
            subtitle: _formatTime(_sleepTime),
            onTap: () => _pickTime(isSleep: true),
          ),
          const SizedBox(height: 12),
          // Wake time
          _settingsTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: Colors.orangeAccent,
            title: 'Wake Time',
            subtitle: _formatTime(_wakeTime),
            onTap: () => _pickTime(isSleep: false),
          ),
          const SizedBox(height: 12),
          // Goodnight message toggle
          _settingsTile(
            icon: Icons.favorite_rounded,
            iconColor: Colors.pinkAccent,
            title: 'Send Goodnight Message',
            subtitle: 'Zero Two says goodnight at bedtime',
            trailing: Switch(
              value: _sendGoodnight,
              onChanged: (v) async {
                setState(() => _sendGoodnight = v);
                await _save();
              },
              activeColor: Colors.pinkAccent,
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.wb_twilight_rounded,
            iconColor: Colors.amberAccent,
            title: 'Send Good Morning Message',
            subtitle: 'Zero Two greets you at wake time',
            trailing: Switch(
              value: _sendGoodmorning,
              onChanged: (v) async {
                setState(() => _sendGoodmorning = v);
                await _save();
              },
              activeColor: Colors.pinkAccent,
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 24),
          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              _sleepModeEnabled
                  ? '🌙 Sleep mode is ON. Zero Two will be quiet from ${_formatTime(_sleepTime)} to ${_formatTime(_wakeTime)}.'
                  : '💤 Sleep mode is off. Turn it on to silence notifications during sleep hours.',
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
            ]),
          ),
          if (trailing != null) trailing,
          if (onTap != null && trailing == null)
            const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
        ]),
      ),
    );
  }
}
