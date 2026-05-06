import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class MassResurgencePage extends StatefulWidget {
  const MassResurgencePage({super.key});
  @override
  State<MassResurgencePage> createState() => _MassResurgencePageState();
}

class _MassResurgencePageState extends State<MassResurgencePage>
    with TickerProviderStateMixin {
  late AnimationController _lightCtrl;
  late Animation<double> _lightAnim;

  bool _reviving = false;
  bool _onCooldown = false;
  int _cooldownSec = 0;
  int _timesUsed = 0;
  int _totalRevived = 0;
  Timer? _cooldownTimer;

  static const int _cooldownDuration = 120;

  final List<Map<String, dynamic>> _team = [
    {'name': 'Zero Two', 'role': 'Striker', 'hp': 0, 'maxHp': 100, 'dead': true, 'icon': Icons.favorite},
    {'name': 'Ichigo', 'role': 'Support', 'hp': 45, 'maxHp': 100, 'dead': false, 'icon': Icons.shield},
    {'name': 'Hiro', 'role': 'Pilot', 'hp': 0, 'maxHp': 100, 'dead': true, 'icon': Icons.flight},
    {'name': 'Miku', 'role': 'Ranger', 'hp': 20, 'maxHp': 100, 'dead': false, 'icon': Icons.arrow_upward},
    {'name': 'Zorome', 'role': 'Tank', 'hp': 0, 'maxHp': 100, 'dead': true, 'icon': Icons.security},
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('mass_resurgence'));
    _lightCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _lightAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _lightCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _lightCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _activateMassResurgence() async {
    if (_onCooldown || _reviving) return;
    setState(() { _reviving = true; });
    await Future.delayed(const Duration(milliseconds: 800));
    int revived = 0;
    setState(() {
      for (final m in _team) {
        if (m['dead'] == true) {
          m['dead'] = false;
          m['hp'] = 50;
          revived++;
        } else {
          m['hp'] = m['maxHp'];
        }
      }
      _reviving = false;
      _timesUsed++;
      _totalRevived += revived;
      _onCooldown = true;
      _cooldownSec = _cooldownDuration;
    });
    _startCooldown();
  }

  void _killMember(int index) {
    setState(() {
      _team[index]['dead'] = true;
      _team[index]['hp'] = 0;
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

  int get _deadCount => _team.where((m) => m['dead'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        title: Text('✨ Mass Resurgence',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFFFDD44), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFFDD44)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildResurgenceDisplay(),
          const SizedBox(height: 20),
          _buildTeamList(),
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

  Widget _buildResurgenceDisplay() {
    return AnimatedBuilder(
      animation: _lightAnim,
      builder: (_, __) => Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: RadialGradient(
            colors: _reviving
                ? [
                    const Color(0xFFFFDD44).withAlpha((100 * _lightAnim.value).toInt()),
                    const Color(0xFF0A0A1A),
                  ]
                : [const Color(0xFF111122), const Color(0xFF0A0A1A)],
          ),
          border: Border.all(
              color: _reviving
                  ? const Color(0xFFFFDD44).withAlpha(200)
                  : Colors.white12),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              _reviving ? Icons.auto_awesome : Icons.healing,
              size: _reviving ? 70 * _lightAnim.value : 55,
              color: _reviving ? const Color(0xFFFFDD44) : Colors.white38,
            ),
            const SizedBox(height: 8),
            Text(
              _reviving ? '✨ RISE!' : '$_deadCount fallen — ready to revive',
              style: GoogleFonts.orbitron(
                  color: _reviving ? const Color(0xFFFFDD44) : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTeamList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TEAM STATUS',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFFFDD44), fontSize: 11)),
        const SizedBox(height: 10),
        ...List.generate(_team.length, (i) {
          final m = _team[i];
          final dead = m['dead'] as bool;
          final hp = m['hp'] as int;
          final maxHp = m['maxHp'] as int;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(m['icon'] as IconData,
                  color: dead ? Colors.red : const Color(0xFFFFDD44), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(m['name'] as String,
                        style: TextStyle(
                            color: dead ? Colors.red : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text(dead ? 'DEAD' : '$hp/$maxHp HP',
                        style: TextStyle(
                            color: dead ? Colors.red : Colors.white54,
                            fontSize: 11)),
                  ]),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: dead ? 0 : hp / maxHp,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          dead ? Colors.red : const Color(0xFFFFDD44)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              if (!dead)
                GestureDetector(
                  onTap: () => _killMember(i),
                  child: const Icon(Icons.close, color: Colors.red, size: 18),
                ),
            ]),
          );
        }),
        const SizedBox(height: 4),
        const Text('Tap ✕ to simulate a team member dying',
            style: TextStyle(color: Colors.white24, fontSize: 10)),
      ]),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        _reviving
            ? '✨ Channeling resurrection energy...'
            : _onCooldown
                ? '⏳ Resurgence recharging: $_cooldownSec s'
                : _deadCount > 0
                    ? '✨ $_deadCount fallen ally(s) — activate to revive all!'
                    : '💚 All allies alive — activate to fully heal everyone!',
        style: const TextStyle(color: Colors.white70, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFireButton() {
    final canFire = !_onCooldown && !_reviving;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canFire ? _activateMassResurgence : null,
        icon: const Icon(Icons.auto_awesome, size: 22),
        label: Text(
          _reviving
              ? '✨ REVIVING...'
              : _onCooldown
                  ? 'COOLDOWN: $_cooldownSec s'
                  : '✨ MASS RESURGENCE!',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canFire ? const Color(0xFFFFDD44) : const Color(0xFF111122),
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
        _stat('USED', '$_timesUsed', Icons.auto_awesome),
        _stat('REVIVED', '$_totalRevived', Icons.healing),
        _stat('COOLDOWN', '${_cooldownDuration}s', Icons.timer),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFFFFDD44), size: 20),
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
                color: const Color(0xFFFFDD44), fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Revives ALL fallen allies at 50% HP\n'
          '• Fully heals all living allies to max HP\n'
          '• The ultimate turnaround ability!\n'
          '• 2-minute cooldown — use only when critical\n'
          '• Tap ✕ on a team member to simulate death',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}
