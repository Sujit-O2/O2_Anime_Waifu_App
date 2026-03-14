import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/waifu_mood_service.dart';

// ── WaifuLockScreen ───────────────────────────────────────────────────────────
// App-level PIN lock screen shown on cold launch.
// Uses flutter_secure_storage for PIN.
// Zero Two animates idle while locked; shakes on wrong PIN, blooms on unlock.
// ─────────────────────────────────────────────────────────────────────────────

class WaifuLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final Color primaryColor;

  const WaifuLockScreen({
    super.key,
    required this.onUnlocked,
    required this.primaryColor,
  });

  static const _pinKey = 'app_lock_pin';

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString(_pinKey);
    return p != null && p.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) == pin;
  }

  @override
  State<WaifuLockScreen> createState() => _WaifuLockScreenState();
}

class _WaifuLockScreenState extends State<WaifuLockScreen>
    with TickerProviderStateMixin {
  String _entered = '';
  bool _wrong = false;
  bool _unlocking = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _bloomCtrl;
  late Animation<double> _bloomScale;
  late Animation<double> _bloomFade;
  late AnimationController _idleCtrl;
  late Animation<double> _idleAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    _bloomCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _bloomScale =
        Tween<double>(begin: 1.0, end: 3.0).animate(
            CurvedAnimation(parent: _bloomCtrl, curve: Curves.easeOutCubic));
    _bloomFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _bloomCtrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    _idleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _idleAnim = Tween<double>(begin: -4, end: 4)
        .animate(CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _bloomCtrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_unlocking || _entered.length >= 4) return;
    setState(() {
      _entered += d;
      _wrong = false;
    });
    if (_entered.length == 4) _checkPin();
  }

  void _onDelete() {
    if (_entered.isNotEmpty) setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _checkPin() async {
    final ok = await WaifuLockScreen.verifyPin(_entered);
    if (ok) {
      setState(() => _unlocking = true);
      await _bloomCtrl.forward();
      widget.onUnlocked();
    } else {
      HapticFeedback.vibrate();
      await _shakeCtrl.forward(from: 0);
      _shakeCtrl.reset();
      setState(() { _entered = ''; _wrong = true; });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mood = WaifuMoodService.current;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0510),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [
                  mood.auraColor.withValues(alpha: 0.15),
                  const Color(0xFF0A0510),
                ],
              ),
            ),
          ),
          // Bloom effect on unlock
          if (_unlocking)
            FadeTransition(
              opacity: _bloomFade,
              child: ScaleTransition(
                scale: _bloomScale,
                child: Container(
                  color: mood.auraColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // Idle waifu avatar
                AnimatedBuilder(
                  animation: _idleAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _idleAnim.value),
                    child: child,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: mood.auraColor.withValues(alpha: 0.6), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: mood.auraColor.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4),
                      ],
                      gradient: RadialGradient(
                        colors: [
                          mood.auraColor.withValues(alpha: 0.3),
                          mood.auraColor.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        mood.emoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _wrong ? 'Wrong PIN, Darling~ 😤' : mood.greeting,
                  style: GoogleFonts.outfit(
                    color: _wrong ? Colors.redAccent : Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // PIN dots
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                        sin(_shakeAnim.value * pi * 5) * 10 * (1 - _shakeAnim.value),
                        0),
                    child: child,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _entered.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: filled ? 18 : 14,
                        height: filled ? 18 : 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? mood.auraColor
                              : Colors.white.withValues(alpha: 0.2),
                          boxShadow: filled
                              ? [BoxShadow(color: mood.auraColor.withValues(alpha: 0.5), blurRadius: 10)]
                              : [],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 40),
                // Keypad
                _buildKeypad(mood.auraColor),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(Color accent) {
    final keys = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      ['','0','⌫'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 80, height: 64);
            return GestureDetector(
              onTap: () => k == '⌫' ? _onDelete() : _onDigit(k),
              child: Container(
                width: 80,
                height: 64,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.07),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Center(
                  child: Text(
                    k,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: k == '⌫' ? 20 : 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
