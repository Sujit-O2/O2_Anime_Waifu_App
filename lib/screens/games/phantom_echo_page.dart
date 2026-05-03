import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhantomEchoPage extends StatefulWidget {
  const PhantomEchoPage({super.key});
  @override
  State<PhantomEchoPage> createState() => _PhantomEchoPageState();
}

class _PhantomEchoPageState extends State<PhantomEchoPage>
    with TickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  bool _clonesActive = false;
  bool _onCooldown = false;
  int _cooldownSec = 0;
  int _cloneSec = 0;
  int _timesUsed = 0;
  int _totalCloneDamage = 0;
  int _activeClones = 0;
  Timer? _cloneTimer;
  Timer? _cooldownTimer;
  Timer? _attackTimer;
  final Random _rng = Random();

  static const int _cloneDuration = 6;
  static const int _cooldownDuration = 40;
  static const int _numClones = 2;

  final List<Map<String, dynamic>> _cloneList = [];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _cloneTimer?.cancel();
    _cooldownTimer?.cancel();
    _attackTimer?.cancel();
    super.dispose();
  }

  void _activatePhantomEcho() {
    if (_onCooldown || _clonesActive) return;
    _cloneList.clear();
    for (int i = 0; i < _numClones; i++) {
      _cloneList.add({'id': i + 1, 'hp': 100, 'active': true});
    }
    setState(() {
      _clonesActive = true;
      _cloneSec = _cloneDuration;
      _activeClones = _numClones;
      _timesUsed++;
    });
    _startCloneLife();
    _startCloneAttacks();
  }

  void _startCloneLife() {
    _cloneTimer?.cancel();
    _cloneTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cloneSec--;
        if (_cloneSec <= 0) {
          _endClones();
          t.cancel();
        }
      });
    });
  }

  void _startCloneAttacks() {
    _attackTimer?.cancel();
    _attackTimer = Timer.periodic(const Duration(milliseconds: 1500), (t) {
      if (!mounted || !_clonesActive) { t.cancel(); return; }
      final dmg = 30 + _rng.nextInt(40);
      setState(() => _totalCloneDamage += dmg * _activeClones);
    });
  }

  void _destroyClone(int id) {
    if (!_clonesActive) return;
    setState(() {
      final clone = _cloneList.firstWhere((c) => c['id'] == id, orElse: () => {});
      if (clone.isNotEmpty && clone['active'] == true) {
        clone['active'] = false;
        _activeClones--;
        if (_activeClones <= 0) _endClones();
      }
    });
  }

  void _endClones() {
    _attackTimer?.cancel();
    _cloneTimer?.cancel();
    setState(() {
      _clonesActive = false;
      _activeClones = 0;
      _onCooldown = true;
      _cooldownSec = _cooldownDuration;
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
        title: Text('👻 Phantom Echo',
            style: GoogleFonts.orbitron(
                color: const Color(0xFFCC44FF), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFCC44FF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildCloneDisplay(),
          const SizedBox(height: 20),
          _buildCloneCards(),
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

  Widget _buildCloneDisplay() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: RadialGradient(
          colors: _clonesActive
              ? [const Color(0xFFCC44FF).withAlpha(50), const Color(0xFF0A0A1A)]
              : [const Color(0xFF111122), const Color(0xFF0A0A1A)],
        ),
        border: Border.all(
            color: _clonesActive
                ? const Color(0xFFCC44FF).withAlpha(180)
                : Colors.white12),
      ),
      child: AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Original
            _avatarIcon(
                label: 'YOU',
                opacity: 1.0,
                color: Colors.white,
                active: true),
            // Clones
            ...List.generate(_numClones, (i) {
              final active = _clonesActive &&
                  i < _cloneList.length &&
                  (_cloneList[i]['active'] as bool);
              return _avatarIcon(
                  label: 'CLONE ${i + 1}',
                  opacity: active ? _shimmerAnim.value : 0.2,
                  color: const Color(0xFFCC44FF),
                  active: active);
            }),
          ],
        ),
      ),
    );
  }

  Widget _avatarIcon(
      {required String label,
      required double opacity,
      required Color color,
      required bool active}) {
    return Opacity(
      opacity: opacity,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person, color: color, size: 48),
        Text(label,
            style: GoogleFonts.orbitron(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        if (active && label != 'YOU')
          const Text('⚔️ attacking',
              style: TextStyle(color: Colors.white38, fontSize: 9)),
      ]),
    );
  }

  Widget _buildCloneCards() {
    if (!_clonesActive) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111122),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Text('No clones active',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ),
      );
    }
    return Column(
      children: _cloneList.map((clone) {
        final active = clone['active'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFCC44FF).withAlpha(20)
                  : const Color(0xFF111122),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: active ? const Color(0xFFCC44FF) : Colors.white12),
            ),
            child: Row(children: [
              Icon(Icons.person,
                  color: active ? const Color(0xFFCC44FF) : Colors.white24,
                  size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Clone ${clone['id']}',
                      style: TextStyle(
                          color: active ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold)),
                  Text(active ? 'Attacking enemies...' : 'Destroyed',
                      style: TextStyle(
                          color: active ? const Color(0xFFCC44FF) : Colors.red,
                          fontSize: 12)),
                ]),
              ),
              if (active)
                TextButton(
                  onPressed: () => _destroyClone(clone['id'] as int),
                  child: const Text('DESTROY',
                      style: TextStyle(color: Colors.red, fontSize: 11)),
                ),
            ]),
          ),
        );
      }).toList(),
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
        _clonesActive
            ? '👻 $_activeClones clone(s) active! Confusing enemies... $_cloneSec s left'
            : _onCooldown
                ? '⏳ Phantom energy recharging... $_cooldownSec s'
                : '👻 Ready to split into phantom echoes!',
        style: const TextStyle(color: Colors.white70, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFireButton() {
    final canFire = !_onCooldown && !_clonesActive;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canFire ? _activatePhantomEcho : null,
        icon: const Icon(Icons.copy, size: 22),
        label: Text(
          _clonesActive
              ? '👻 CLONES ACTIVE ($_cloneSec s)'
              : _onCooldown
                  ? 'RECHARGING: $_cooldownSec s'
                  : '👻 PHANTOM ECHO!',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canFire ? const Color(0xFFCC44FF) : const Color(0xFF111122),
          foregroundColor: canFire ? Colors.white : Colors.white38,
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
        _stat('USED', '$_timesUsed', Icons.copy),
        _stat('CLONE DMG', '$_totalCloneDamage', Icons.flash_on),
        _stat('CLONES', '$_numClones', Icons.person),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: const Color(0xFFCC44FF), size: 20),
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
                color: const Color(0xFFCC44FF), fontSize: 11)),
        const SizedBox(height: 8),
        const Text(
          '• Spawns 2 phantom clones that mimic your attacks\n'
          '• Clones deal 30-70 damage every 1.5 seconds each\n'
          '• Enemies may target clones instead of you!\n'
          '• Clones last 6 seconds or until destroyed\n'
          '• 40-second cooldown — high skill ceiling ability',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
        ),
      ]),
    );
  }
}
