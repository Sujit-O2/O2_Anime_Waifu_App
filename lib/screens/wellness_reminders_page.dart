import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hydration = prefs.getBool('reminders_hydration') ?? false;
      _eyeCare = prefs.getBool('reminders_eyecare') ?? false;
      _posture = prefs.getBool('reminders_posture') ?? false;
      _morningBriefing = prefs.getBool('reminders_morning') ?? false;
      _hydrationIntervalMins = prefs.getInt('reminders_hydration_mins') ?? 60;
      final h = prefs.getInt('morning_time_hour') ?? 7;
      final m = prefs.getInt('morning_time_min') ?? 30;
      _morningTime = TimeOfDay(hour: h, minute: m);
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_hydration', _hydration);
    await prefs.setBool('reminders_eyecare', _eyeCare);
    await prefs.setBool('reminders_posture', _posture);
    await prefs.setBool('reminders_morning', _morningBriefing);
    await prefs.setInt('reminders_hydration_mins', _hydrationIntervalMins);
    await prefs.setInt('morning_time_hour', _morningTime.hour);
    await prefs.setInt('morning_time_min', _morningTime.minute);
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: value
            ? color.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
            color: value
                ? color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 11)),
              ])),
          Switch(
            value: value,
            onChanged: (v) {
              setState(() => onChanged(v));
              _save();
            },
            activeColor: color,
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
        if (extra != null && value) ...[
          const SizedBox(height: 12),
          extra,
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('WELLNESS REMINDERS',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Waifu intro
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.pinkAccent.withValues(alpha: 0.08),
              border:
                  Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Text('🌸', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                'I\'ll take care of you, Darling~ Toggle the reminders you want!',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
              )),
            ]),
          ),

          _card(
            emoji: '💧',
            title: 'Hydration Reminder',
            subtitle: 'Zero Two reminds you to drink water',
            value: _hydration,
            onChanged: (v) => _hydration = v,
            color: Colors.cyanAccent,
            extra:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Remind every: $_hydrationIntervalMins min',
                  style:
                      GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
              Slider(
                value: _hydrationIntervalMins.toDouble(),
                min: 15,
                max: 120,
                divisions: 7,
                activeColor: Colors.cyanAccent,
                inactiveColor: Colors.white12,
                label: '${_hydrationIntervalMins}m',
                onChanged: (v) {
                  setState(() => _hydrationIntervalMins = v.round());
                  _save();
                },
              ),
            ]),
          ),

          _card(
            emoji: '👁️',
            title: '20-20-20 Eye Care',
            subtitle: 'Every 20 min: look 20ft away for 20 sec',
            value: _eyeCare,
            onChanged: (v) => _eyeCare = v,
            color: Colors.greenAccent,
          ),

          _card(
            emoji: '🪑',
            title: 'Posture Check',
            subtitle: 'Nudge to sit up straight every hour',
            value: _posture,
            onChanged: (v) => _posture = v,
            color: Colors.orangeAccent,
          ),

          _card(
            emoji: '🌅',
            title: 'Morning Briefing',
            subtitle: 'Zero Two greets you with the day\'s forecast',
            value: _morningBriefing,
            onChanged: (v) => _morningBriefing = v,
            color: Colors.amberAccent,
            extra: Row(children: [
              Text('Time: ${_morningTime.format(context)}',
                  style:
                      GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _morningTime,
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: Colors.amberAccent,
                            onPrimary: Colors.black),
                      ),
                      child: child!,
                    ),
                  );
                  if (t != null) {
                    setState(() => _morningTime = t);
                    _save();
                  }
                },
                icon: const Icon(Icons.access_time_outlined,
                    color: Colors.amberAccent, size: 16),
                label: Text('Change',
                    style: GoogleFonts.outfit(
                        color: Colors.amberAccent, fontSize: 12)),
              ),
            ]),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(
              'Note: Actual notification delivery requires the app to be open or running in background. Background notifications depend on your device\'s battery optimization settings.',
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
