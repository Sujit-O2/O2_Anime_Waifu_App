import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/waifu_background.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});
  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _remaining = 25 * 60;
  bool _running = false;
  int _session = 0; // completed pomodoros
  bool _isBreak = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Settings
  int _workMins = 25;
  int _shortBreakMins = 5;
  int _longBreakMins = 15;

  List<Map<String, dynamic>> _log = [];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _remaining = _workMins * 60;
    _loadLog();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLog() async {
    final p = await SharedPreferences.getInstance();
    try {
      final raw = p.getString('pomodoro_log') ?? '[]';
      setState(() => _log = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList());
    } catch (_) {}
  }

  Future<void> _saveLog() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('pomodoro_log', jsonEncode(_log));
  }

  int get _totalSeconds => _isBreak
      ? (_session % 4 == 0 && _session > 0
          ? _longBreakMins * 60
          : _shortBreakMins * 60)
      : _workMins * 60;

  void _start() {
    if (_remaining <= 0) _reset();
    setState(() => _running = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
        _onComplete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _onComplete() {
    if (!_isBreak) {
      final newCount = _session + 1;
      _log.insert(0, {
        'session': newCount,
        'time': DateTime.now().millisecondsSinceEpoch,
        'type': 'work',
      });
      _saveLog();
      setState(() {
        _session = newCount;
        _isBreak = true;
        _running = false;
      });
      _remaining = _totalSeconds;
    } else {
      setState(() {
        _isBreak = false;
        _running = false;
      });
      _remaining = _workMins * 60;
    }
    HapticFeedback.mediumImpact();
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _isBreak = false;
      _remaining = _workMins * 60;
    });
  }

  void _skip() {
    _timer?.cancel();
    _onComplete();
  }

  String _fmt(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _totalSeconds > 0 ? _remaining / _totalSeconds : 0;

  Color get _themeColor => _isBreak ? Colors.greenAccent : Colors.pinkAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: WaifuBackground(
        opacity: 0.09,
        tint: const Color(0xFF0A0808),
        child: SafeArea(
            child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  _timer?.cancel();
                  Navigator.pop(context);
                },
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12)),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white60, size: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('POMODORO TIMER',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                    Text(
                        '$_session sessions completed${_session >= 4 ? ' 🏆' : ''}',
                        style: GoogleFonts.outfit(
                            color: _themeColor.withOpacity(0.7), fontSize: 10)),
                  ])),
            ]),
          ),

          const SizedBox(height: 8),

          // Mode indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _modeChip('Work', !_isBreak),
              const SizedBox(width: 8),
              _modeChip('Short Break',
                  _isBreak && (_session % 4 != 0 || _session == 0)),
              const SizedBox(width: 8),
              _modeChip(
                  'Long Break', _isBreak && _session % 4 == 0 && _session > 0),
            ]),
          ),

          const SizedBox(height: 16),

          // Timer circle
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (ctx, _) => Transform.scale(
              scale: _running ? _pulseAnim.value : 1.0,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(
                        color: _themeColor.withOpacity(0.4), width: 2)),
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: CircularProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation(_themeColor),
                      strokeWidth: 8,
                    ),
                  ),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isBreak ? '☕' : '🍅',
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(_fmt(_remaining),
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w900)),
                        Text(_isBreak ? 'BREAK' : 'FOCUS',
                            style: GoogleFonts.outfit(
                                color: _themeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2)),
                      ]),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Pomodoro dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                4,
                (i) => Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < (_session % 4)
                            ? Colors.pinkAccent
                            : Colors.white.withOpacity(0.1),
                        border: Border.all(
                            color: Colors.pinkAccent.withOpacity(0.4)),
                      ),
                    )),
          ),

          const SizedBox(height: 20),

          // Controls
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _ctrlBtn(Icons.skip_previous_rounded, Colors.white38, _reset),
            const SizedBox(width: 16),
            _ctrlBtn(_running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                _themeColor, _running ? _pause : _start,
                large: true),
            const SizedBox(width: 16),
            _ctrlBtn(Icons.skip_next_rounded, Colors.white38, _skip),
          ]),

          const SizedBox(height: 16),

          // Settings row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _settingChip(
                      'Work',
                      _workMins,
                      (v) => setState(() {
                            _workMins = v;
                            if (!_running && !_isBreak) _remaining = v * 60;
                          })),
                  _settingChip('Short', _shortBreakMins,
                      (v) => setState(() => _shortBreakMins = v)),
                  _settingChip('Long', _longBreakMins,
                      (v) => setState(() => _longBreakMins = v)),
                ]),
          ),

          if (_log.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(children: [
                Text('Recent sessions',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 11)),
                const Spacer(),
                Text('${_log.length} total 🍅',
                    style:
                        GoogleFonts.outfit(color: _themeColor, fontSize: 11)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _log.length.clamp(0, 5),
                itemBuilder: (ctx, i) {
                  final l = _log[i];
                  final d =
                      DateTime.fromMillisecondsSinceEpoch(l['time'] as int);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      const Text('🍅', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text('Session #${l['session']}',
                          style: GoogleFonts.outfit(
                              color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      Text('${d.hour}:${d.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.outfit(
                              color: Colors.white24, fontSize: 11)),
                    ]),
                  );
                },
              ),
            ),
          ] else
            const Spacer(),
        ])),
      ),
    );
  }

  Widget _modeChip(String label, bool active) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active
              ? _themeColor.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          border: Border.all(color: active ? _themeColor : Colors.white12),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                color: active ? _themeColor : Colors.white24,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      );

  Widget _ctrlBtn(IconData icon, Color color, VoidCallback onTap,
          {bool large = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: large ? 64 : 48,
          height: large ? 64 : 48,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(large ? 0.5 : 0.3))),
          child: Icon(icon, color: color, size: large ? 32 : 22),
        ),
      );

  Widget _settingChip(String label, int val, void Function(int) onChange) =>
      GestureDetector(
        onTap: () {
          final newVal = val == 5
              ? 10
              : val == 10
                  ? 15
                  : val == 15
                      ? 20
                      : val == 20
                          ? 25
                          : val == 25
                              ? 45
                              : val == 45
                                  ? 60
                                  : 5;
          onChange(newVal);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white12),
          ),
          child: Text('$label: ${val}m',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
        ),
      );
}
