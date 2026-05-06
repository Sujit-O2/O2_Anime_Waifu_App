import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class GuardianSummonPage extends StatefulWidget {
  const GuardianSummonPage({super.key});
  @override
  State<GuardianSummonPage> createState() => _GuardianSummonPageState();
}

class _GuardianSummonPageState extends State<GuardianSummonPage>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  int _ultimateMeter = 0;
  bool _summonActive = false;
  bool _onCooldown = false;
  int _cooldownSec = 0;
  int _lifespanSec = 0;
  int _summonHp = 0;
  int _totalSummons = 0;
  int _totalDamageDealt = 0;
  String _selectedGuardian = 'Steel Golem';
  Timer? _lifespanTimer;
  Timer? _cooldownTimer;
  Timer? _attackTimer;
  final Random _rng = Random();

  static const int _maxMeter = 100;
  static const int _lifespan = 20;
  static const int _cooldown = 120;

  final List<Map<String, dynamic>> _guardians = [
    {'name': 'Steel Golem', 'hp': 1000, 'dmg': '80-120', 'icon': Icons.shield, 'color': 0xFF888888},
    {'name': 'Spirit Wolf', 'hp': 600, 'dmg': '60-90', 'icon': Icons.pets, 'color': 0xFF8888FF},
    {'name': 'Fire Drake', 'hp': 800, 'dmg': '100-150', 'icon': Icons.local_fire_department, 'color': 0xFFFF4400},
    {'name': 'Thunder Bird', 'hp': 700, 'dmg': '90-130', 'icon': Icons.bolt, 'color': 0xFFFFDD00},
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('guardian_summon'));
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _lifespanTimer?.cancel();
    _cooldownTimer?.cancel();
    _attackTimer?.cancel();
    super.dispose();
  }

  void _chargeMeter() {
    if (_onCooldown || _summonActive) return;
    setState(() {
      _ultimateMeter = (_ultimateMeter + 20).clamp(0, _maxMeter);
    });
  }

  void _summonGuardian() {
    if (_ultimateMeter < _maxMeter || _onCooldown || _summonActive) return;
    final guardian = _guardians.firstWhere((g) => g['name'] == _selectedGuardian);
    setState(() {
      _summonActive = true;
      _ultimateMeter = 0;
      _lifespanSec = _lifespan;
      _summonHp = guardian['hp'] as int;
      _totalSummons++;
    });
    _startLifespan();
    _startAttacking();
  }

  void _startLifespan() {
    _lifespanTimer?.cancel();
    _lifespanTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _lifespanSec--;
        if (_lifespanSec <= 0 || _summonHp <= 0) {
          _despawnGuardian();
          t.cancel();
        }
      });
    });
  }

  void _startAttacking() {
    _attackTimer?.cancel();
    _attackTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (!mounted || !_summonActive) { t.cancel(); return; }
      final guardian = _guardians.firstWhere((g) => g['name'] == _selectedGuardian);
      final dmgStr = guardian['dmg'] as String;
      final parts = dmgStr.split('-');
      final min = int.parse(parts[0]);
      final max = int.parse(parts[1]);
      final dmg = min + _rng.nextInt(max - min);
      setState(() => _totalDamageDealt += dmg);
    });
  }

  void _despawnGuardian() {
    _attackTimer?.cancel();
    setState(() {
      _summonActive = false;
      _summonHp = 0;
      _onCooldown = true;
      _cooldownSec = _cooldown;
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
    final guardian = _guardians.firstWhere((g) => g['name'] == _selectedGuardian);
    final guardianColor = Color(guardian['color'] as int);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: Text('🛡️ Guardian Summon',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF8844FF), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF8844FF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildSummonDisplay(guardian, guardianColor),
          const SizedBox(height: 20),
          _buildGuardianSelector(),
          const SizedBox(height: 16),
          _buildMeterCard(),
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

  Widget _buildSummonDisplay(Map<String, dynamic> guardian, Color color) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: RadialGradient(
            colors: _summonActive
                ? [color.withAlpha((60 * _glowAnim.value).toInt()), const Color(0xFF0A0A1A)]
                : [const Color(0xFF111122), const Color(0xFF0A0A1A)],
          ),
          border: Border.all(
              color: _summonActive ? color.withAlpha(180) : Colors.white12),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              guardian['icon'] as IconData,
              size: _summonActive ? 70 * _glowAnim.value : 50,
              color: _summonActive ? color : Colors.white24,
            ),
            const SizedBox(height: 8),
            Text(
              _summonActive ? _selectedGuardian : 'NO GUARDIAN',
              style: GoogleFonts.orbitron(
                  color: _summonActive ? color : Colors.white24,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            if (_summonActive) ...[
              const SizedBox(height: 6),
              Text('HP: $_summonHp  |  ${_lifespanSec}s left',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text('⚔️ Attacking enemies... +$_totalDamageDealt dmg total',
                  style: TextStyle(color: color, fontSize: 11)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildGuardianSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECT GUARDIAN',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF8844FF), fontSize: 11)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _guardians.map((g) {
            final selected = g['name'] == _selectedGuardian;
            final c = Color(g['color'] as int);
            return GestureDetector(
              onTap: _summonActive ? null : () => setState(() => _selectedGuardian = g['name'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? c.withAlpha(40) : const Color(0xFF1A1A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? c : Colors.white12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(g['icon'] as IconData, color: selected ? c : Colors.white38, size: 16),
                  const SizedBox(width: 6),
                  Text(g['name'] as String,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white38,
                          fontSize: 12)),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildMeterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SUMMON METER',
              style: GoogleFonts.orbitron(
                  color: const Color(0xFF8844FF), fontSize: 12)),
          Text('$_ultimateMeter / $_maxMeter',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _ultimateMeter / _maxMeter,
            minHeight: 12,
            backgroundColor: const Color(0xFF222233),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8844FF)),
          ),
        ),
        if (_onCooldown) ...[
          const SizedBox(height: 8),
          Text('Cooldown: $_cooldownSec s',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ]),
    );
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _onCooldown || _summonActive ? null : _chargeMeter,
          icon: const Icon(Icons.add_circle),
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
          onPressed: _ultimateMeter >= _maxMeter && !_onCooldown && !_summonActive
              ? _summonGuardian
              : null,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('SUMMON!'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8844FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ]);
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
        _stat('SUMMONS', '$_totalSummons', Icons.auto_awesome),
        _stat('DMG DEALT', '$_totalDamageDealt', Icons.flash_on),
        _stat('LIFESPAN', '${_lifespan}s', Icons.timer),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFF8844FF), size: 20),
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
                color: const Color(0xFF8844FF), fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Choose your guardian type before summoning\n'
          '• Charge meter to 100% then summon\n'
          '• Guardian attacks enemies autonomously every 2s\n'
          '• Despawns after 20 seconds or when HP reaches 0\n'
          '• 2-minute cooldown — use wisely!',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}
