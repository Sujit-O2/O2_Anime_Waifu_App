import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NullZonePage extends StatefulWidget {
  const NullZonePage({super.key});
  @override
  State<NullZonePage> createState() => _NullZonePageState();
}

class _NullZonePageState extends State<NullZonePage>
    with TickerProviderStateMixin {
  late AnimationController _zoneCtrl;
  late Animation<double> _zoneAnim;

  bool _zoneActive = false;
  bool _onCooldown = false;
  int _cooldownSec = 0;
  int _zoneSec = 0;
  int _timesUsed = 0;
  int _totalEnemiesCC = 0;
  String _ccType = 'Stun';
  Timer? _zoneTimer;
  Timer? _cooldownTimer;

  static const int _zoneDuration = 3;
  static const int _cooldownDuration = 60;

  final List<String> _ccTypes = ['Stun', 'Slow', 'Silence', 'Root'];

  final List<Map<String, dynamic>> _enemies = [
    {'name': 'KLAXOSAUR α', 'status': 'Active', 'icon': Icons.bug_report},
    {'name': 'KLAXOSAUR β', 'status': 'Active', 'icon': Icons.bug_report},
    {'name': 'KLAXOSAUR γ', 'status': 'Active', 'icon': Icons.bug_report},
    {'name': 'BOSS UNIT', 'status': 'Active', 'icon': Icons.dangerous},
  ];

  @override
  void initState() {
    super.initState();
    _zoneCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _zoneAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _zoneCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _zoneCtrl.dispose();
    _zoneTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _activateNullZone() {
    if (_onCooldown || _zoneActive) return;
    final affected = _enemies.length;
    setState(() {
      _zoneActive = true;
      _zoneSec = _zoneDuration;
      _timesUsed++;
      _totalEnemiesCC += affected;
      for (final e in _enemies) { e['status'] = _ccType; }
    });
    _zoneTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _zoneSec--;
        if (_zoneSec <= 0) {
          _zoneActive = false;
          for (final e in _enemies) { e['status'] = 'Active'; }
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

  Color get _ccColor {
    switch (_ccType) {
      case 'Stun': return const Color(0xFFFFDD00);
      case 'Slow': return const Color(0xFF44AAFF);
      case 'Silence': return const Color(0xFFAA44FF);
      case 'Root': return const Color(0xFF44FF88);
      default: return const Color(0xFFFFDD00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: Text('🌀 Null Zone',
            style: GoogleFonts.orbitron(
                color: _ccColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: _ccColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildZoneDisplay(),
          const SizedBox(height: 20),
          _buildCCTypeSelector(),
          const SizedBox(height: 16),
          _buildEnemyList(),
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

  Widget _buildZoneDisplay() {
    return AnimatedBuilder(
      animation: _zoneAnim,
      builder: (_, __) => Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: RadialGradient(
            colors: _zoneActive
                ? [_ccColor.withAlpha((60 * _zoneAnim.value).toInt()), const Color(0xFF0A0A1A)]
                : [const Color(0xFF111122), const Color(0xFF0A0A1A)],
          ),
          border: Border.all(
              color: _zoneActive ? _ccColor.withAlpha(200) : Colors.white12),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Concentric rings
            Stack(alignment: Alignment.center, children: [
              Container(
                width: 120 * (_zoneActive ? _zoneAnim.value : 0.5),
                height: 120 * (_zoneActive ? _zoneAnim.value : 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _zoneActive ? _ccColor.withAlpha(120) : Colors.white12,
                      width: 2),
                ),
              ),
              Container(
                width: 70 * (_zoneActive ? _zoneAnim.value : 0.5),
                height: 70 * (_zoneActive ? _zoneAnim.value : 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _zoneActive ? _ccColor.withAlpha(40) : Colors.transparent,
                  border: Border.all(
                      color: _zoneActive ? _ccColor : Colors.white24, width: 2),
                ),
              ),
              Icon(Icons.block,
                  color: _zoneActive ? _ccColor : Colors.white24, size: 28),
            ]),
            const SizedBox(height: 8),
            Text(
              _zoneActive ? '$_ccType ZONE ACTIVE — $_zoneSec s' : 'NULL ZONE READY',
              style: GoogleFonts.orbitron(
                  color: _zoneActive ? _ccColor : Colors.white38, fontSize: 12),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildCCTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CC TYPE',
            style: GoogleFonts.orbitron(color: _ccColor, fontSize: 11)),
        const SizedBox(height: 10),
        Row(
          children: _ccTypes.map((t) {
            final selected = t == _ccType;
            Color c;
            switch (t) {
              case 'Stun': c = const Color(0xFFFFDD00); break;
              case 'Slow': c = const Color(0xFF44AAFF); break;
              case 'Silence': c = const Color(0xFFAA44FF); break;
              default: c = const Color(0xFF44FF88);
            }
            return Expanded(
              child: GestureDetector(
                onTap: _zoneActive ? null : () => setState(() => _ccType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? c.withAlpha(40) : const Color(0xFF1A1A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? c : Colors.white12),
                  ),
                  child: Text(t,
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

  Widget _buildEnemyList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ENEMIES IN ZONE',
            style: GoogleFonts.orbitron(color: _ccColor, fontSize: 11)),
        const SizedBox(height: 10),
        ..._enemies.map((e) {
          final cc = e['status'] != 'Active';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(e['icon'] as IconData,
                  color: cc ? _ccColor : Colors.white38, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(e['name'] as String,
                    style: TextStyle(
                        color: cc ? Colors.white : Colors.white54,
                        fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cc ? _ccColor.withAlpha(40) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: cc ? _ccColor : Colors.white24),
                ),
                child: Text(e['status'] as String,
                    style: TextStyle(
                        color: cc ? _ccColor : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildFireButton() {
    final canFire = !_onCooldown && !_zoneActive;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canFire ? _activateNullZone : null,
        icon: const Icon(Icons.block, size: 22),
        label: Text(
          _zoneActive
              ? '🌀 ZONE ACTIVE ($_zoneSec s)'
              : _onCooldown
                  ? 'COOLDOWN: $_cooldownSec s'
                  : '🌀 NULL ZONE!',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canFire ? _ccColor : const Color(0xFF111122),
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
        _stat('USED', '$_timesUsed', Icons.block),
        _stat('CC\'d', '$_totalEnemiesCC', Icons.people),
        _stat('DURATION', '${_zoneDuration}s', Icons.timer),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: _ccColor, size: 20),
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
            style: GoogleFonts.orbitron(color: _ccColor, fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Creates an AoE zone that disables all enemies inside\n'
          '• Choose CC type: Stun, Slow, Silence, or Root\n'
          '• Affects all enemies in 10m radius for 3 seconds\n'
          '• 60-second cooldown — powerful battlefield control\n'
          '• Allies are unaffected — coordinate your team!',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}
