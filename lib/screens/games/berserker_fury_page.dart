import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BerserkerFuryPage extends StatefulWidget {
  const BerserkerFuryPage({super.key});
  @override
  State<BerserkerFuryPage> createState() => _BerserkerFuryPageState();
}

class _BerserkerFuryPageState extends State<BerserkerFuryPage>
    with TickerProviderStateMixin {
  late AnimationController _rageCtrl;
  late Animation<double> _rageAnim;

  bool _berserkActive = false;
  bool _onCooldown = false;
  bool _exhausted = false;
  int _cooldownSec = 0;
  int _berserkSec = 0;
  int _exhaustSec = 0;
  int _timesUsed = 0;
  final double _baseAttack = 100;
  final double _baseSpeed = 100;
  Timer? _berserkTimer;
  Timer? _cooldownTimer;
  Timer? _exhaustTimer;

  static const int _berserkDuration = 8;
  static const int _cooldownDuration = 20;
  static const int _exhaustDuration = 3;

  String get _currentMode {
    if (_berserkActive) return 'BERSERK';
    if (_exhausted) return 'EXHAUSTED';
    if (_onCooldown) return 'COOLDOWN';
    return 'READY';
  }

  double get _displayAttack {
    if (_berserkActive) return _baseAttack * 2.0;
    if (_exhausted) return _baseAttack * 0.8;
    return _baseAttack;
  }

  double get _displaySpeed {
    if (_berserkActive) return _baseSpeed * 1.3;
    if (_exhausted) return _baseSpeed * 0.8;
    return _baseSpeed;
  }

  @override
  void initState() {
    super.initState();
    _rageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..repeat(reverse: true);
    _rageAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _rageCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rageCtrl.dispose();
    _berserkTimer?.cancel();
    _cooldownTimer?.cancel();
    _exhaustTimer?.cancel();
    super.dispose();
  }

  void _activateBerserk() {
    if (_onCooldown || _berserkActive || _exhausted) return;
    setState(() {
      _berserkActive = true;
      _berserkSec = _berserkDuration;
      _timesUsed++;
    });
    _berserkTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _berserkSec--;
        if (_berserkSec <= 0) {
          _berserkActive = false;
          _exhausted = true;
          _exhaustSec = _exhaustDuration;
          t.cancel();
          _startExhaust();
        }
      });
    });
  }

  void _startExhaust() {
    _exhaustTimer?.cancel();
    _exhaustTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _exhaustSec--;
        if (_exhaustSec <= 0) {
          _exhausted = false;
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

  Color get _modeColor {
    switch (_currentMode) {
      case 'BERSERK': return const Color(0xFFFF2200);
      case 'EXHAUSTED': return Colors.grey;
      case 'COOLDOWN': return Colors.orange;
      default: return const Color(0xFFFF6600);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _berserkActive ? const Color(0xFF1A0000) : const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: _berserkActive ? const Color(0xFF1A0000) : const Color(0xFF0A0A0A),
        title: Text('🔥 Berserker Fury',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFFF4400), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFF4400)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildCharacterDisplay(),
          const SizedBox(height: 20),
          _buildStatsPanel(),
          const SizedBox(height: 16),
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildFireButton(),
          const SizedBox(height: 16),
          _buildHistoryCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
        ]),
      ),
    );
  }

  Widget _buildCharacterDisplay() {
    return AnimatedBuilder(
      animation: _rageAnim,
      builder: (_, __) => Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: RadialGradient(
            colors: _berserkActive
                ? [
                    const Color(0xFFFF2200).withAlpha((80 * _rageAnim.value).toInt()),
                    const Color(0xFF1A0000),
                  ]
                : [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)],
          ),
          border: Border.all(color: _modeColor.withAlpha(180)),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              _berserkActive ? Icons.whatshot : Icons.person,
              size: _berserkActive ? 80 * _rageAnim.value : 60,
              color: _modeColor,
            ),
            const SizedBox(height: 8),
            Text(
              _currentMode,
              style: GoogleFonts.orbitron(
                  color: _modeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            if (_berserkActive)
              Text('$_berserkSec s remaining',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if (_exhausted)
              Text('Exhausted: $_exhaustSec s',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: [
        _statBar('ATTACK POWER', _displayAttack, 200, _modeColor),
        const SizedBox(height: 12),
        _statBar('MOVE SPEED', _displaySpeed, 150, Colors.orange),
        const SizedBox(height: 12),
        _statBar('DEFENSE', _berserkActive ? 60 : 100, 100, Colors.blue),
      ]),
    );
  }

  Widget _statBar(String label, double value, double max, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text('${value.toInt()}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (value / max).clamp(0.0, 1.0),
          minHeight: 8,
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _modeColor.withAlpha(60)),
      ),
      child: Text(
        _berserkActive
            ? '🔥 BERSERK MODE! Attack ×2, Speed ×1.3 for $_berserkSec more seconds!'
            : _exhausted
                ? '😮‍💨 Exhausted... recovering for $_exhaustSec s'
                : _onCooldown
                    ? '⏳ Cooldown: $_cooldownSec s'
                    : '⚔️ Ready to unleash berserker fury!',
        style: TextStyle(color: _modeColor, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFireButton() {
    final canFire = !_onCooldown && !_berserkActive && !_exhausted;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canFire ? _activateBerserk : null,
        icon: const Icon(Icons.whatshot, size: 24),
        label: Text(
          _berserkActive
              ? '🔥 BERSERK ($_berserkSec s)'
              : _exhausted
                  ? '😮‍💨 EXHAUSTED ($_exhaustSec s)'
                  : _onCooldown
                      ? 'COOLDOWN: $_cooldownSec s'
                      : '🔥 BERSERKER FURY!',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canFire ? const Color(0xFFFF4400) : const Color(0xFF1A1A1A),
          foregroundColor: canFire ? Colors.white : Colors.white38,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('RAGES', '$_timesUsed', Icons.whatshot),
        _stat('DURATION', '${_berserkDuration}s', Icons.timer),
        _stat('COOLDOWN', '${_cooldownDuration}s', Icons.refresh),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFFFF4400), size: 20),
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
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ABILITY INFO',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFFF4400), fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Transforms into a raging berserker for 8 seconds\n'
          '• Attack power ×2, Move speed ×1.3\n'
          '• Defense reduced — high risk, high reward!\n'
          '• 3-second exhaustion phase after berserk ends\n'
          '• 20-second cooldown — pure power fantasy',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}
