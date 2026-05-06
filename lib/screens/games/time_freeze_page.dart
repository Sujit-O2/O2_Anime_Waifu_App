import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class TimeFreezePage extends StatefulWidget {
  const TimeFreezePage({super.key});
  @override
  State<TimeFreezePage> createState() => _TimeFreezePageState();
}

class _TimeFreezePageState extends State<TimeFreezePage>
    with TickerProviderStateMixin {
  late AnimationController _clockCtrl;
  late AnimationController _frozenCtrl;
  late Animation<double> _clockAnim;
  late Animation<double> _frozenAnim;

  bool _frozen = false;
  bool _onCooldown = false;
  int _cooldownSec = 0;
  int _freezeSec = 0;
  int _timesUsed = 0;
  int _enemiesFrozen = 0;
  Timer? _freezeTimer;
  Timer? _cooldownTimer;

  static const int _freezeDuration = 3;
  static const int _cooldownDuration = 120;

  final List<Map<String, dynamic>> _enemies = [
    {'name': 'KLAXOSAUR α', 'frozen': false, 'hp': 85},
    {'name': 'KLAXOSAUR β', 'frozen': false, 'hp': 60},
    {'name': 'KLAXOSAUR γ', 'frozen': false, 'hp': 40},
    {'name': 'BOSS UNIT', 'frozen': false, 'hp': 95},
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('time_freeze'));
    _clockCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _frozenCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _clockAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_clockCtrl);
    _frozenAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _frozenCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _clockCtrl.dispose();
    _frozenCtrl.dispose();
    _freezeTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _activateTimeFreeze() {
    if (_onCooldown || _frozen) return;
    _frozenCtrl.forward(from: 0);
    setState(() {
      _frozen = true;
      _freezeSec = _freezeDuration;
      _timesUsed++;
      _enemiesFrozen = _enemies.length;
      for (final e in _enemies) { e['frozen'] = true; }
    });
    _freezeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _freezeSec--;
        if (_freezeSec <= 0) {
          _frozen = false;
          for (final e in _enemies) { e['frozen'] = false; }
          _onCooldown = true;
          _cooldownSec = _cooldownDuration;
          t.cancel();
          _startCooldown();
        }
      });
    });
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldownSec--;
        if (_cooldownSec <= 0) {
          _onCooldown = false;
          _cooldownSec = 0;
          t.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _frozen ? const Color(0xFF050A1A) : const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: _frozen ? const Color(0xFF050A1A) : const Color(0xFF0A0A1A),
        title: Text('⏱️ Time Freeze',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF00CCFF), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF00CCFF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildClockDisplay(),
          const SizedBox(height: 20),
          _buildEnemyList(),
          const SizedBox(height: 16),
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildFireButton(),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
        ]),
      ),
    );
  }

  Widget _buildClockDisplay() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: RadialGradient(
          colors: _frozen
              ? [const Color(0xFF00CCFF).withAlpha(60), const Color(0xFF050A1A)]
              : [const Color(0xFF111122), const Color(0xFF0A0A1A)],
        ),
        border: Border.all(
            color: _frozen
                ? const Color(0xFF00CCFF).withAlpha(200)
                : Colors.white12),
      ),
      child: Stack(alignment: Alignment.center, children: [
        // Clock face
        AnimatedBuilder(
          animation: _clockAnim,
          builder: (_, __) => Transform.rotate(
            angle: _frozen ? 0 : _clockAnim.value * 2 * 3.14159,
            child: Icon(Icons.schedule,
                size: 80,
                color: _frozen
                    ? const Color(0xFF00CCFF)
                    : Colors.white24),
          ),
        ),
        // Frozen overlay
        if (_frozen)
          AnimatedBuilder(
            animation: _frozenAnim,
            builder: (_, __) => Container(
              width: 160 * _frozenAnim.value,
              height: 160 * _frozenAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF00CCFF).withAlpha(
                        (180 * _frozenAnim.value).toInt()),
                    width: 2),
              ),
            ),
          ),
        Positioned(
          bottom: 16,
          child: Text(
            _frozen ? '❄️ TIME FROZEN — $_freezeSec s' : 'TIME FLOWS NORMALLY',
            style: GoogleFonts.orbitron(
                color: _frozen ? const Color(0xFF00CCFF) : Colors.white38,
                fontSize: 12),
          ),
        ),
      ]),
    );
  }

  Widget _buildEnemyList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ENEMIES IN RANGE',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF00CCFF), fontSize: 11)),
        const SizedBox(height: 10),
        ...(_enemies.map((e) {
          final frozen = e['frozen'] as bool;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(
                frozen ? Icons.ac_unit : Icons.warning_amber,
                color: frozen ? const Color(0xFF00CCFF) : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e['name'] as String,
                      style: TextStyle(
                          color: frozen ? const Color(0xFF00CCFF) : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (e['hp'] as int) / 100,
                      minHeight: 4,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          frozen ? const Color(0xFF00CCFF) : Colors.red),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text(frozen ? 'FROZEN' : '${e['hp']}%',
                  style: TextStyle(
                      color: frozen ? const Color(0xFF00CCFF) : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ]),
          );
        })),
      ]),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _frozen ? const Color(0xFF00CCFF).withAlpha(80) : Colors.white12),
      ),
      child: Text(
        _frozen
            ? '❄️ Time is frozen! Strike enemies freely for $_freezeSec more seconds!'
            : _onCooldown
                ? '⏳ Temporal rift recharging... $_cooldownSec s'
                : '⏱️ Ready to freeze time! All enemies will be immobilized.',
        style: TextStyle(
            color: _frozen ? const Color(0xFF00CCFF) : Colors.white70,
            fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFireButton() {
    final canFire = !_onCooldown && !_frozen;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canFire ? _activateTimeFreeze : null,
        icon: const Icon(Icons.ac_unit, size: 24),
        label: Text(
          _frozen
              ? '❄️ TIME FROZEN ($_freezeSec s)'
              : _onCooldown
                  ? 'RECHARGING: $_cooldownSec s'
                  : '⏱️ FREEZE TIME!',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canFire ? const Color(0xFF00CCFF) : const Color(0xFF111122),
          foregroundColor: canFire ? Colors.black : Colors.white38,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('USED', '$_timesUsed', Icons.history),
        _stat('FROZEN', '$_enemiesFrozen', Icons.ac_unit),
        _stat('DURATION', '${_freezeDuration}s', Icons.timer),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFF00CCFF), size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.orbitron(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
    ]);
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ABILITY INFO',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF00CCFF), fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Halts all enemies in a temporal rift for 3 seconds\n'
          '• You and allies remain unaffected — attack freely!\n'
          '• Enemies are fully immobilized (cannot move or attack)\n'
          '• 2-minute cooldown — the most powerful control ability\n'
          '• High skill ceiling: timing is everything!',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}
