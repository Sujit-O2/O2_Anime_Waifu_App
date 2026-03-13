import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LateNightModePage extends StatefulWidget {
  const LateNightModePage({super.key});
  @override
  State<LateNightModePage> createState() => _LateNightModePageState();
}

class _LateNightModePageState extends State<LateNightModePage> {
  bool _lateNightEnabled = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);
  bool _cozyVoice = true;
  bool _sleepReminder = false;
  bool _reduceAnimations = false;

  bool get _isCurrentlyNight {
    final now = TimeOfDay.now();
    final nowM = now.hour * 60 + now.minute;
    final startM = _startTime.hour * 60 + _startTime.minute;
    final endM = _endTime.hour * 60 + _endTime.minute;
    return startM > endM
        ? (nowM >= startM || nowM <= endM)
        : (nowM >= startM && nowM <= endM);
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Colors.pinkAccent, surface: Color(0xFF1A1A2E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _isCurrentlyNight && _lateNightEnabled;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.pop(context)),
        title: Text('LATE NIGHT MODE',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: isNight
                    ? [const Color(0xFF0A0530), const Color(0xFF150A2E)]
                    : [const Color(0xFF1A1A1A), const Color(0xFF0A0A16)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: (isNight ? Colors.deepPurpleAccent : Colors.white)
                      .withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Text(isNight ? '🌙' : '☀️', style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isNight ? 'Night Mode Active' : 'Day Mode Active',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(
                    isNight
                        ? 'Zero Two is in cozy mode~'
                        : 'Normal mode active!',
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          _toggle(
              'Enable Late Night Mode',
              _lateNightEnabled,
              Icons.nights_stay_outlined,
              Colors.deepPurpleAccent,
              (v) => setState(() => _lateNightEnabled = v)),
          const SizedBox(height: 20),
          Text('NIGHT HOURS',
              style: GoogleFonts.outfit(
                  color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _timeCard('Starts', _startTime, () => _pickTime(true))),
            const SizedBox(width: 12),
            Expanded(
                child: _timeCard('Ends', _endTime, () => _pickTime(false))),
          ]),
          const SizedBox(height: 20),
          Text('SETTINGS',
              style: GoogleFonts.outfit(
                  color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          _toggle(
              'Cozy Voice Style',
              _cozyVoice,
              Icons.record_voice_over_outlined,
              Colors.pinkAccent,
              (v) => setState(() => _cozyVoice = v),
              sub: 'Zero Two speaks softer at night'),
          const SizedBox(height: 8),
          _toggle('Sleep Reminder', _sleepReminder, Icons.bed_outlined,
              Colors.purpleAccent, (v) => setState(() => _sleepReminder = v),
              sub: 'Zero Two reminds you to rest'),
          const SizedBox(height: 8),
          _toggle(
              'Reduce Animations',
              _reduceAnimations,
              Icons.animation_outlined,
              Colors.tealAccent,
              (v) => setState(() => _reduceAnimations = v),
              sub: 'Quieter, calmer interface'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.deepPurpleAccent.withValues(alpha: 0.07),
              border: Border.all(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🌙', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                '"Get some rest, Darling~ I\'ll be right here when you wake up. Sweet dreams~ 💕"',
                style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _toggle(String label, bool val, IconData icon, Color color,
          ValueChanged<bool> fn,
          {String? sub}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
        child: SwitchListTile(
            dense: sub != null,
            secondary: Icon(icon, color: color, size: 20),
            title: Text(label,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
            subtitle: sub != null
                ? Text(sub,
                    style:
                        GoogleFonts.outfit(color: Colors.white38, fontSize: 11))
                : null,
            value: val,
            onChanged: fn,
            activeColor: color,
            inactiveTrackColor: Colors.white12),
      );

  Widget _timeCard(String label, TimeOfDay time, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.3))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 4),
            Text(_fmt(time),
                style: GoogleFonts.outfit(
                    color: Colors.deepPurpleAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text('Tap to change',
                style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
          ]),
        ),
      );
}
