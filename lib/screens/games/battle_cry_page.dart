import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class BattleCryPage extends StatefulWidget {
  const BattleCryPage({super.key});
  @override
  State<BattleCryPage> createState() => _BattleCryPageState();
}

class _BattleCryPageState extends State<BattleCryPage>
    with TickerProviderStateMixin {
  late AnimationController _auraCtrl;
  late Animation<double> _auraAnim;

  bool _buffActive = false;
  bool _onCooldown = false;
  int _cooldownSec = 0;
  int _buffSec = 0;
  int _timesUsed = 0;
  Timer? _buffTimer;
  Timer? _cooldownTimer;

  static const int _buffDuration = 8;
  static const int _cooldownDuration = 45;

  final List<Map<String, dynamic>> _allies = [
    {'name': 'Zero Two', 'role': 'Striker', 'buffed': false, 'icon': Icons.favorite},
    {'name': 'Ichigo', 'role': 'Support', 'buffed': false, 'icon': Icons.shield},
    {'name': 'Hiro', 'role': 'Pilot', 'buffed': false, 'icon': Icons.flight},
    {'name': 'Miku', 'role': 'Ranger', 'buffed': false, 'icon': Icons.arrow_upward},
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('battle_cry'));
    _auraCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _auraAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _auraCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _auraCtrl.dispose();
    _buffTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _activateBattleCry() {
    if (_onCooldown || _buffActive) return;
    setState(() {
      _buffActive = true;
      _buffSec = _buffDuration;
      _timesUsed++;
      for (final a in _allies) {
        a['buffed'] = true;
      }
    });
    _buffTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _buffSec--;
        if (_buffSec <= 0) {
          _buffActive = false;
          for (final a in _allies) { a['buffed'] = false; }
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
      backgroundColor: const Color(0xFF0A1A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1A0A),
        title: Text('📯 Battle Cry',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF00FF88), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF00FF88)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildAuraDisplay(),
          const SizedBox(height: 20),
          _buildAllyGrid(),
          const SizedBox(height: 16),
          _buildBuffStatus(),
          const SizedBox(height: 16),
          _buildFireButton(),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 16),
          _buildInfoCard(),
        ]),
      ),
    );
  }

  Widget _buildAuraDisplay() {
    return AnimatedBuilder(
      animation: _auraAnim,
      builder: (_, __) => Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: RadialGradient(
            colors: _buffActive
                ? [
                    const Color(0xFF00FF88).withAlpha((80 * _auraAnim.value).toInt()),
                    const Color(0xFF0A1A0A),
                  ]
                : [const Color(0xFF111A11), const Color(0xFF0A1A0A)],
          ),
          border: Border.all(
              color: _buffActive
                  ? const Color(0xFF00FF88).withAlpha(180)
                  : Colors.white12),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              Icons.campaign,
              size: 60 * (_buffActive ? _auraAnim.value : 0.8),
              color: _buffActive ? const Color(0xFF00FF88) : Colors.white38,
            ),
            const SizedBox(height: 8),
            Text(
              _buffActive ? '⚔️ BATTLE CRY ACTIVE!' : 'FOR HONOR!',
              style: GoogleFonts.orbitron(
                color: _buffActive ? const Color(0xFF00FF88) : Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_buffActive)
              Text('$_buffSec s remaining',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildAllyGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: _allies.map((ally) {
        final buffed = ally['buffed'] as bool;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: buffed ? const Color(0xFF00FF88).withAlpha(30) : const Color(0xFF111A11),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: buffed ? const Color(0xFF00FF88) : Colors.white12),
          ),
          child: Row(children: [
            Icon(ally['icon'] as IconData,
                color: buffed ? const Color(0xFF00FF88) : Colors.white38,
                size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(ally['name'] as String,
                        style: TextStyle(
                            color: buffed ? Colors.white : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    Text(buffed ? '+30% DMG ⚡' : ally['role'] as String,
                        style: TextStyle(
                            color: buffed
                                ? const Color(0xFF00FF88)
                                : Colors.white38,
                            fontSize: 10)),
                  ]),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildBuffStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111A11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: [
        _buffRow('Damage Boost', '+30%', _buffActive),
        const SizedBox(height: 6),
        _buffRow('Armor Buff', 'Active', _buffActive),
        const SizedBox(height: 6),
        _buffRow('Speed Boost', '+15%', _buffActive),
        if (_onCooldown) ...[
          const Divider(color: Colors.white12, height: 16),
          Row(children: [
            const Icon(Icons.timer, color: Colors.grey, size: 14),
            const SizedBox(width: 6),
            Text('Cooldown: $_cooldownSec s',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ]),
    );
  }

  Widget _buffRow(String label, String value, bool active) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF00FF88).withAlpha(40)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: active ? const Color(0xFF00FF88) : Colors.white24),
        ),
        child: Text(value,
            style: TextStyle(
                color: active ? const Color(0xFF00FF88) : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Widget _buildFireButton() {
    final canFire = !_onCooldown && !_buffActive;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canFire ? _activateBattleCry : null,
        icon: const Icon(Icons.campaign, size: 24),
        label: Text(
          _buffActive
              ? 'BATTLE CRY ACTIVE ($_buffSec s)'
              : _onCooldown
                  ? 'COOLDOWN: $_cooldownSec s'
                  : '⚔️ BATTLE CRY!',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canFire ? const Color(0xFF00FF88) : const Color(0xFF1A2A1A),
          foregroundColor: canFire ? Colors.black : Colors.white38,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111A11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('USED', '$_timesUsed', Icons.campaign),
        _stat('ALLIES', '${_allies.length}', Icons.group),
        _stat('BUFF DUR', '${_buffDuration}s', Icons.timer),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFF00FF88), size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.orbitron(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
    ]);
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ABILITY INFO',
            style: GoogleFonts.orbitron(
                color: const Color(0xFF00FF88), fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Rallies all nearby allies with a powerful war cry\n'
          '• Grants +30% damage, armor buff, and +15% speed\n'
          '• Lasts 8 seconds — coordinate your team push!\n'
          '• 45-second cooldown after buff expires\n'
          '• Affects all allies within 20m radius',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}
