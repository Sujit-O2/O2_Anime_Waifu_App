import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class FinalJudgmentPage extends StatefulWidget {
  const FinalJudgmentPage({super.key});
  @override
  State<FinalJudgmentPage> createState() => _FinalJudgmentPageState();
}

class _FinalJudgmentPageState extends State<FinalJudgmentPage>
    with TickerProviderStateMixin {
  late AnimationController _swordCtrl;
  late AnimationController _executeCtrl;
  late Animation<double> _swordAnim;
  late Animation<double> _executeAnim;

  bool _executing = false;
  bool _onCooldown = false;
  int _cooldownSec = 0;
  int _totalExecutions = 0;
  Timer? _cooldownTimer;
  final Random _rng = Random();

  static const int _cooldownDuration = 30;
  static const double _executeThreshold = 0.2;

  final List<Map<String, dynamic>> _targets = [
    {'name': 'KLAXOSAUR α', 'hp': 15, 'maxHp': 100, 'icon': Icons.bug_report, 'dead': false},
    {'name': 'KLAXOSAUR β', 'hp': 55, 'maxHp': 100, 'icon': Icons.bug_report, 'dead': false},
    {'name': 'KLAXOSAUR γ', 'hp': 8, 'maxHp': 100, 'icon': Icons.bug_report, 'dead': false},
    {'name': 'BOSS UNIT', 'hp': 18, 'maxHp': 500, 'icon': Icons.dangerous, 'dead': false},
    {'name': 'ELITE GUARD', 'hp': 45, 'maxHp': 100, 'icon': Icons.shield, 'dead': false},
  ];

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('final_judgment'));
    _swordCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _executeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _swordAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _swordCtrl, curve: Curves.easeInOut));
    _executeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _executeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _swordCtrl.dispose();
    _executeCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  bool _isExecutable(Map<String, dynamic> target) {
    if (target['dead'] == true) return false;
    final hp = target['hp'] as int;
    final maxHp = target['maxHp'] as int;
    return hp / maxHp <= _executeThreshold;
  }

  Future<void> _executeTarget(int index) async {
    if (_onCooldown || _executing) return;
    final target = _targets[index];
    if (!_isExecutable(target)) return;

    setState(() { _executing = true; });
    _executeCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      target['dead'] = true;
      target['hp'] = 0;
      _executing = false;
      _totalExecutions++;
      _onCooldown = true;
      _cooldownSec = _cooldownDuration;
    });
    _startCooldown();
  }

  void _damageTarget(int index) {
    final target = _targets[index];
    if (target['dead'] == true) return;
    final dmg = 5 + _rng.nextInt(15);
    setState(() {
      target['hp'] = max(0, (target['hp'] as int) - dmg);
      if (target['hp'] == 0) target['dead'] = true;
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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text('⚔️ Final Judgment',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFFF2244), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFF2244)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildSwordDisplay(),
          const SizedBox(height: 20),
          _buildTargetList(),
          const SizedBox(height: 16),
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
        ]),
      ),
    );
  }

  Widget _buildSwordDisplay() {
    return AnimatedBuilder(
      animation: _swordAnim,
      builder: (_, __) => Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: RadialGradient(
            colors: _executing
                ? [const Color(0xFFFF2244).withAlpha(80), const Color(0xFF0A0A0A)]
                : [const Color(0xFF1A1111), const Color(0xFF0A0A0A)],
          ),
          border: Border.all(
              color: _executing
                  ? const Color(0xFFFF2244).withAlpha(200)
                  : Colors.white12),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _executeAnim,
              builder: (_, __) => Transform.rotate(
                angle: _executing ? _executeAnim.value * -0.5 : 0,
                child: Icon(
                  Icons.gavel,
                  size: 60 * _swordAnim.value,
                  color: _executing
                      ? const Color(0xFFFF2244)
                      : _onCooldown
                          ? Colors.grey
                          : const Color(0xFFFF2244).withAlpha(180),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _executing
                  ? '⚔️ EXECUTE!'
                  : _onCooldown
                      ? 'RECHARGING: $_cooldownSec s'
                      : 'SELECT A TARGET BELOW 20% HP',
              style: GoogleFonts.orbitron(
                  color: _executing
                      ? const Color(0xFFFF2244)
                      : Colors.white38,
                  fontSize: 11),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTargetList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TARGETS',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFFF2244), fontSize: 11)),
        const SizedBox(height: 10),
        ...List.generate(_targets.length, (i) {
          final t = _targets[i];
          final dead = t['dead'] as bool;
          final hp = t['hp'] as int;
          final maxHp = t['maxHp'] as int;
          final executable = _isExecutable(t);
          final hpPct = dead ? 0.0 : hp / maxHp;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(t['icon'] as IconData,
                  color: dead
                      ? Colors.white12
                      : executable
                          ? const Color(0xFFFF2244)
                          : Colors.white38,
                  size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t['name'] as String,
                        style: TextStyle(
                            color: dead
                                ? Colors.white24
                                : executable
                                    ? const Color(0xFFFF2244)
                                    : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: dead ? TextDecoration.lineThrough : null)),
                    Text(dead ? 'DEAD' : '$hp/$maxHp',
                        style: TextStyle(
                            color: dead
                                ? Colors.white24
                                : executable
                                    ? const Color(0xFFFF2244)
                                    : Colors.white38,
                            fontSize: 11)),
                  ]),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: hpPct,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          dead
                              ? Colors.white12
                              : executable
                                  ? const Color(0xFFFF2244)
                                  : Colors.green),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              if (!dead) ...[
                // Damage button
                GestureDetector(
                  onTap: () => _damageTarget(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('HIT',
                        style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 6),
                // Execute button
                GestureDetector(
                  onTap: executable && !_onCooldown && !_executing
                      ? () => _executeTarget(i)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: executable && !_onCooldown
                          ? const Color(0xFFFF2244)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'EXECUTE',
                      style: TextStyle(
                          color: executable && !_onCooldown
                              ? Colors.white
                              : Colors.white24,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ]),
          );
        }),
        const SizedBox(height: 4),
        const Text('Tap HIT to damage enemies. EXECUTE appears when HP \u226420%',
            style: TextStyle(color: Colors.white24, fontSize: 10)),
      ]),
    );
  }

  Widget _buildStatusCard() {
    final executableCount = _targets.where(_isExecutable).length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        _executing
            ? '⚔️ FINAL JUDGMENT DELIVERED!'
            : _onCooldown
                ? '⏳ Judgment recharging: $_cooldownSec s'
                : executableCount > 0
                    ? '⚔️ $executableCount target(s) ready for execution!'
                    : 'Damage enemies below 20% HP to unlock execution',
        style: TextStyle(
            color: executableCount > 0 && !_onCooldown
                ? const Color(0xFFFF2244)
                : Colors.white54,
            fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('EXECUTIONS', '$_totalExecutions', Icons.gavel),
        _stat('THRESHOLD', '≤20%', Icons.percent),
        _stat('COOLDOWN', '${_cooldownDuration}s', Icons.timer),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFFFF2244), size: 20),
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
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ABILITY INFO',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFFF2244), fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Instantly kills a target at or below 20% HP\n'
          '• Tap HIT to damage enemies, then EXECUTE to finish\n'
          '• Cannot execute healthy targets — requires setup!\n'
          '• 30-second cooldown after each execution\n'
          '• High skill ceiling: requires strategic damage setup',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}
