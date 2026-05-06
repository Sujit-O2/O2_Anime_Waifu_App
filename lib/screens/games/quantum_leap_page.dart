import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class QuantumLeapPage extends StatefulWidget {
  const QuantumLeapPage({super.key});
  @override
  State<QuantumLeapPage> createState() => _QuantumLeapPageState();
}

class _QuantumLeapPageState extends State<QuantumLeapPage>
    with TickerProviderStateMixin {
  late AnimationController _portalCtrl;
  late Animation<double> _portalAnim;

  bool _teleporting = false;
  bool _onCooldown = false;
  int _cooldownSec = 0;
  int _totalLeaps = 0;
  double _playerX = 0.5;
  double _playerY = 0.5;
  double _targetX = 0.5;
  double _targetY = 0.5;
  String _leapMode = 'Solo Blink';
  Timer? _cooldownTimer;
  final Random _rng = Random();

  static const int _cooldownDuration = 12;

  final List<String> _modes = ['Solo Blink', 'Team Jump', 'Enemy Swap'];
  final List<Map<String, dynamic>> _leapLog = [];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('quantum_leap'));
    _portalCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _portalAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _portalCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _portalCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _activateQuantumLeap() async {
    if (_onCooldown || _teleporting) return;
    final newX = 0.1 + _rng.nextDouble() * 0.8;
    final newY = 0.1 + _rng.nextDouble() * 0.8;
    setState(() {
      _teleporting = true;
      _targetX = newX;
      _targetY = newY;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _playerX = newX;
      _playerY = newY;
      _teleporting = false;
      _totalLeaps++;
      _onCooldown = true;
      _cooldownSec = _cooldownDuration;
      _leapLog.insert(0, {
        'mode': _leapMode,
        'time': DateTime.now().toIso8601String().substring(11, 19),
        'dist': '${(sqrt(pow(newX - 0.5, 2) + pow(newY - 0.5, 2)) * 100).toStringAsFixed(0)}m',
      });
      if (_leapLog.length > 5) _leapLog.removeLast();
    });
    _startCooldown();
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
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: Text('⚡ Quantum Leap',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF44DDFF), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF44DDFF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildMapDisplay(),
          const SizedBox(height: 20),
          _buildModeSelector(),
          const SizedBox(height: 16),
          _buildFireButton(),
          const SizedBox(height: 16),
          _buildLeapLog(),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
        ]),
      ),
    );
  }

  Widget _buildMapDisplay() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0D1020),
        border: Border.all(color: const Color(0xFF44DDFF).withAlpha(80)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(children: [
          // Grid lines
          CustomPaint(
            size: const Size(double.infinity, 220),
            painter: _GridPainter(),
          ),
          // Target marker
          if (_teleporting)
            AnimatedBuilder(
              animation: _portalAnim,
              builder: (_, __) => Positioned(
                left: _targetX * (MediaQuery.of(context).size.width - 32) - 16,
                top: _targetY * 220 - 16,
                child: Container(
                  width: 32 * _portalAnim.value,
                  height: 32 * _portalAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF44DDFF).withAlpha(
                        (150 * _portalAnim.value).toInt()),
                    border: Border.all(color: const Color(0xFF44DDFF), width: 2),
                  ),
                ),
              ),
            ),
          // Player marker
          Positioned(
            left: _playerX * (MediaQuery.of(context).size.width - 32) - 12,
            top: _playerY * 220 - 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              child: Icon(
                Icons.person_pin,
                color: _teleporting ? Colors.transparent : const Color(0xFF44DDFF),
                size: 24,
              ),
            ),
          ),
          // Label
          Positioned(
            bottom: 8,
            right: 12,
            child: Text('TAP FIRE TO LEAP',
                style: GoogleFonts.orbitron(
                    color: Colors.white24, fontSize: 10)),
          ),
        ]),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LEAP MODE',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF44DDFF), fontSize: 11)),
        const SizedBox(height: 10),
        Row(
          children: _modes.map((m) {
            final selected = m == _leapMode;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _leapMode = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF44DDFF).withAlpha(40)
                        : const Color(0xFF1A1A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected
                            ? const Color(0xFF44DDFF)
                            : Colors.white12),
                  ),
                  child: Text(m,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildFireButton() {
    final canFire = !_onCooldown && !_teleporting;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canFire ? _activateQuantumLeap : null,
        icon: const Icon(Icons.flash_on, size: 22),
        label: Text(
          _teleporting
              ? '⚡ TELEPORTING...'
              : _onCooldown
                  ? 'COOLDOWN: $_cooldownSec s'
                  : '⚡ QUANTUM LEAP!',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canFire ? const Color(0xFF44DDFF) : const Color(0xFF111122),
          foregroundColor: canFire ? Colors.black : Colors.white38,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildLeapLog() {
    if (_leapLog.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LEAP LOG',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF44DDFF), fontSize: 11)),
        const SizedBox(height: 8),
        ..._leapLog.map((log) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.flash_on, color: Color(0xFF44DDFF), size: 14),
            const SizedBox(width: 6),
            Text('${log['time']}  ${log['mode']}  +${log['dist']}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        )),
      ]),
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
        _stat('LEAPS', '$_totalLeaps', Icons.flash_on),
        _stat('MODE', _leapMode.split(' ')[0], Icons.settings),
        _stat('COOLDOWN', '${_cooldownDuration}s', Icons.timer),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFF44DDFF), size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.orbitron(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                color: const Color(0xFF44DDFF), fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Instantly teleports you to a random position\n'
          '• Solo Blink: personal escape/ambush tool\n'
          '• Team Jump: teleports entire squad forward\n'
          '• Enemy Swap: swap positions with a target\n'
          '• 12-second cooldown — fast and tactical',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF44DDFF).withAlpha(20)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
