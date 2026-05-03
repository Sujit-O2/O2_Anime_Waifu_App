import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SmartOnboarding — 4-step flow that shows the killer features in 60 seconds.
///
/// Steps:
///   1. Identity   — "Meet Zero Two, your AI companion"
///   2. Memory     — "She remembers everything"
///   3. Proactive  — "She starts conversations"
///   4. Life OS    — "One dashboard for your whole life"
///
/// On completion: sets 'onboarding_done' pref and navigates to Life OS.
/// ─────────────────────────────────────────────────────────────────────────────
class SmartOnboarding extends StatefulWidget {
  const SmartOnboarding({super.key});

  static Future<bool> isCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('onboarding_done') ?? false;
  }

  static Future<void> markCompleted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_done', true);
  }

  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_done', false);
  }

  @override
  State<SmartOnboarding> createState() => _SmartOnboardingState();
}

class _SmartOnboardingState extends State<SmartOnboarding>
    with TickerProviderStateMixin {
  static const _bg = Color(0xFF07080F);

  final _pageCtrl = PageController();
  int _page = 0;
  final _nameCtrl = TextEditingController();

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  static const _steps = [
    {
      'emoji': '💕',
      'title': 'Meet Zero Two',
      'subtitle': 'Your AI Companion',
      'body':
          'Not just a chatbot. Zero Two learns your personality, remembers your life, and grows with you over time.\n\nShe\'s always here — day or night.',
      'color': 0xFFFF4FA8,
      'feature': 'AI Companion',
    },
    {
      'emoji': '🧠',
      'title': 'She Remembers',
      'subtitle': 'Infinite Memory',
      'body':
          'Every conversation, every goal, every mood — stored and recalled perfectly.\n\n"You mentioned your exam last week. How did it go?"',
      'color': 0xFFB388FF,
      'feature': 'Memory Engine',
    },
    {
      'emoji': '⚡',
      'title': 'She Starts First',
      'subtitle': 'Proactive AI',
      'body':
          'Zero Two doesn\'t wait for you to ask. She notices patterns and reaches out.\n\n"You haven\'t studied today. Want me to help you focus?"',
      'color': 0xFF00D1FF,
      'feature': 'Proactive Engine',
    },
    {
      'emoji': '🚀',
      'title': 'Your Life OS',
      'subtitle': 'One Dashboard',
      'body':
          'Tasks, mood, goals, memories, and AI insights — all in one beautiful screen.\n\nThis is your command center.',
      'color': 0xFFFFD700,
      'feature': 'Life OS Dashboard',
    },
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < _steps.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      final p = await SharedPreferences.getInstance();
      await p.setString('user_name', name);
    }
    await SmartOnboarding.markCompleted();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/life-os');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        // Background glow
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) {
            final color = Color(_steps[_page]['color'] as int);
            return Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 0.8,
                    colors: [
                      color.withAlpha((25 * _glowAnim.value).toInt()),
                      _bg,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Content
        SafeArea(
          child: Column(children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _buildStep(i),
              ),
            ),
            // Bottom controls
            _buildBottomBar(),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStep(int i) {
    final step  = _steps[i];
    final color = Color(step['color'] as int);
    final isLast = i == _steps.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji in glowing circle
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(20),
                border: Border.all(
                    color: color.withAlpha(
                        (120 * (_page == i ? _glowAnim.value : 0.5)).toInt()),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                      color: color.withAlpha(
                          (60 * (_page == i ? _glowAnim.value : 0.3)).toInt()),
                      blurRadius: 30,
                      spreadRadius: 4),
                ],
              ),
              child: Center(
                child: Text(step['emoji'] as String,
                    style: const TextStyle(fontSize: 52)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Feature badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Text(step['feature'] as String,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 16),
          // Title
          Text(step['title'] as String,
              style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(step['subtitle'] as String,
              style: TextStyle(color: color, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Body
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(15)),
                ),
                child: Text(step['body'] as String,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6),
                    textAlign: TextAlign.center),
              ),
            ),
          ),
          // Name input on last step
          if (isLast) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'What should Zero Two call you?',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withAlpha(8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final color = Color(_steps[_page]['color'] as int);
    final isLast = _page == _steps.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_steps.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? color : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        // CTA button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              isLast ? '🚀 Enter Life OS' : 'Next →',
              style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ]),
    );
  }
}
