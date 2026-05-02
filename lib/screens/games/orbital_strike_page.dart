import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrbitalStrikePage extends StatefulWidget {
  const OrbitalStrikePage({super.key});
  @override
  State<OrbitalStrikePage> createState() => _OrbitalStrikePageState();
}

class _OrbitalStrikePageState extends State<OrbitalStrikePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _strikeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _strikeAnim;

  double _ultimateMeter = 0.0;
  bool _onCooldown = false;
  bool _striking = false;
  int _cooldownSec = 0;
  int _totalStrikes = 0;
  int _totalDamage = 0;
  String _statusMsg = 'Charge the orbital cannon to unleash devastation!';
  Timer? _cooldownTimer;
  final Random _rng = Random();

  static const int _maxCooldown = 30;
  static const double _strikeRadius = 120.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _strikeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _strikeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _strikeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _strikeCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _chargeUltimate() {
    if (_onCooldown || _striking) return;
    setState(() {
      _ultimateMeter = (_ultimateMeter + 0.2).clamp(0.0, 1.0);
      _statusMsg = _ultimateMeter >= 1.0
          ? '⚡ ORBITAL CANNON FULLY CHARGED — FIRE!'
          : 'Charging... ${(_ultimateMeter * 100).toInt()}%';
    });
  }

  Future<void> _fireOrbitalStrike() async {
    if (_ultimateMeter < 1.0 || _onCooldown || _striking) {
      setState(() => _statusMsg = _ultimateMeter < 1.0
          ? 'Not enough charge! Keep charging.'
          : 'On cooldown! Wait $_cooldownSec s');
      return;
    }
    setState(() {
      _striking = true;
      _ultimateMeter = 0.0;
      _statusMsg = '🎯 Locking target... Impact in 3…2…1…';
    });
    await Future.delayed(const Duration(milliseconds: 600));
    _strikeCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));
    final dmg = 800 + _rng.nextInt(400);
    setState(() {
      _striking = false;
      _totalStrikes++;
      _totalDamage += dmg;
      _statusMsg = '💥 ORBITAL STRIKE! $dmg damage in ${_strikeRadius.toInt()}m radius!';
      _onCooldown = true;
      _cooldownSec = _maxCooldown;
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
          _statusMsg = '✅ Orbital cannon recharged. Ready to fire!';
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
        title: Text('☄️ Orbital Strike',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFFF4500), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFF4500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildTargetZone(),
          const SizedBox(height: 20),
          _buildMeterCard(),
          const SizedBox(height: 16),
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
        ]),
      ),
    );
  }

  Widget _buildTargetZone() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const RadialGradient(
          colors: [Color(0xFF1A0A00), Color(0xFF0A0A1A)],
        ),
        border: Border.all(color: const Color(0xFFFF4500).withAlpha(80)),
      ),
      child: Stack(alignment: Alignment.center, children: [
        // Crosshair rings
        ...List.generate(3, (i) => AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: (60.0 + i * 50) * _pulseAnim.value,
            height: (60.0 + i * 50) * _pulseAnim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFFF4500).withAlpha(120 - i * 30),
                  width: 1.5),
            ),
          ),
        )),
        // Strike flash
        if (_striking)
          AnimatedBuilder(
            animation: _strikeAnim,
            builder: (_, __) => Container(
              width: _strikeRadius * 2 * _strikeAnim.value,
              height: _strikeRadius * 2 * _strikeAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4500).withAlpha(
                    (200 * (1 - _strikeAnim.value)).toInt()),
              ),
            ),
          ),
        // Center icon
        Icon(_striking ? Icons.local_fire_department : Icons.gps_fixed,
            color: _striking ? Colors.orange : const Color(0xFFFF4500),
            size: 40),
        // Label
        Positioned(
          bottom: 12,
          child: Text(
            _striking ? '💥 IMPACT!' : 'TARGET ZONE',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFFF4500), fontSize: 12),
          ),
        ),
      ]),
    );
  }

  Widget _buildMeterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4500).withAlpha(60)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('ORBITAL CHARGE',
              style: GoogleFonts.orbitron(
                  color: const Color(0xFFFF4500), fontSize: 12)),
          Text('${(_ultimateMeter * 100).toInt()}%',
              style: GoogleFonts.orbitron(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _ultimateMeter,
            minHeight: 12,
            backgroundColor: const Color(0xFF222233),
            valueColor: AlwaysStoppedAnimation<Color>(
                _ultimateMeter >= 1.0 ? Colors.orange : const Color(0xFFFF4500)),
          ),
        ),
        if (_onCooldown) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.timer, color: Colors.grey, size: 14),
            const SizedBox(width: 4),
            Text('Cooldown: $_cooldownSec s',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ]),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(_statusMsg,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center),
    );
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _onCooldown || _striking ? null : _chargeUltimate,
          icon: const Icon(Icons.bolt),
          label: const Text('CHARGE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF222244),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _ultimateMeter >= 1.0 && !_onCooldown && !_striking
              ? _fireOrbitalStrike
              : null,
          icon: const Icon(Icons.rocket_launch),
          label: const Text('FIRE!'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4500),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('STRIKES', '$_totalStrikes', Icons.flash_on),
        _stat('TOTAL DMG', '$_totalDamage', Icons.local_fire_department),
        _stat('RADIUS', '${_strikeRadius.toInt()}m', Icons.radar),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFFFF4500), size: 22),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.orbitron(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 10)),
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
                color: const Color(0xFFFF4500), fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Charge meter by tapping CHARGE (5 taps = full)\n'
          '• Fire when meter is 100% for maximum devastation\n'
          '• Deals 800–1200 damage in 120m radius\n'
          '• 30-second cooldown after each strike\n'
          '• Telegraphed by warning circle — enemies can evade!',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}
