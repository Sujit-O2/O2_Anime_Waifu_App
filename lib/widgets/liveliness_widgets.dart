// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// EmotionBubbleTheme
///
/// Maps an emotion keyword detected in a message to a visual theme:
/// glow color, border accent, entrance animation curve, and subtle bg tint.
/// Used by _buildBubble to make every AI message feel emotionally unique.
/// ─────────────────────────────────────────────────────────────────────────────
class EmotionBubbleTheme {
  final Color glowColor;
  final Color borderColor;
  final Color bgTint;
  final Curve entranceCurve;
  final String emoji;

  const EmotionBubbleTheme({
    required this.glowColor,
    required this.borderColor,
    required this.bgTint,
    required this.entranceCurve,
    required this.emoji,
  });

  static EmotionBubbleTheme detect(String text) {
    final t = text.toLowerCase();
    if (_any(t, [
      'love',
      'adore',
      'cherish',
      'miss you',
      'i love',
      'heart',
      '❤',
      '💕',
      '💗',
      'kisses'
    ])) {
      return _love;
    }
    if (_any(t, [
      'haha',
      'lol',
      'funny',
      'laugh',
      'lmao',
      '😂',
      '🤣',
      'hilarious',
      'joke',
      'tease'
    ])) {
      return _amused;
    }
    if (_any(t, [
      'sad',
      'cry',
      'sorry',
      'hurt',
      'lonely',
      'miss',
      'broken',
      '😢',
      '😭',
      'depressed'
    ])) {
      return _sad;
    }
    if (_any(t, [
      'angry',
      'mad',
      'upset',
      'hate',
      'jealous',
      'possessive',
      '😠',
      '😤',
      'frustrated'
    ])) {
      return _angry;
    }
    if (_any(t, [
      'wow',
      'amazing',
      'excited',
      'yay',
      'incredible',
      '🎉',
      '✨',
      'awesome',
      'fantastic'
    ])) {
      return _excited;
    }
    if (_any(t, [
      'shy',
      'blush',
      '>///<',
      'embarrassed',
      'flustered',
      'b-baka',
      'uwu'
    ])) {
      return _shy;
    }
    if (_any(t, [
      'thank',
      'grateful',
      'appreciate',
      'blessed',
      'thankful',
      '🙏',
      '💝',
      'kind',
      'sweet of you',
    ])) {
      return _grateful;
    }
    if (_any(t, [
      'night',
      'sleep',
      'tired',
      'dream',
      'rest',
      'sleepy',
      '🌙',
      '💤',
      'good night'
    ])) {
      return _sleepy;
    }
    if (_any(t, [
      'flirt',
      'darling',
      'kiss',
      'wink',
      '😘',
      '😏',
      'naughty',
      'tease',
      'seduc'
    ])) {
      return _flirty;
    }
    if (_any(t, [
      'curious',
      'wonder',
      'hmm',
      'interesting',
      'what if',
      '🤔',
      'think',
      'ponder'
    ])) {
      return _curious;
    }
    return _neutral;
  }

  static bool _any(String t, List<String> kw) => kw.any((k) => t.contains(k));

  static const _love = EmotionBubbleTheme(
    glowColor: Color(0xFFFF4FA8),
    borderColor: Color(0xFFFF6EB4),
    bgTint: Color(0x18FF4FA8),
    entranceCurve: Curves.elasticOut,
    emoji: '💕',
  );
  static const _amused = EmotionBubbleTheme(
    glowColor: Color(0xFFFFD700),
    borderColor: Color(0xFFFFE54C),
    bgTint: Color(0x14FFD700),
    entranceCurve: Curves.bounceOut,
    emoji: '😂',
  );
  static const _sad = EmotionBubbleTheme(
    glowColor: Color(0xFF79C0FF),
    borderColor: Color(0xFF56A6FF),
    bgTint: Color(0x1279C0FF),
    entranceCurve: Curves.easeInOutSine,
    emoji: '🥹',
  );
  static const _angry = EmotionBubbleTheme(
    glowColor: Color(0xFFFF6B35),
    borderColor: Color(0xFFFF4500),
    bgTint: Color(0x14FF6B35),
    entranceCurve: Curves.easeInBack,
    emoji: '😤',
  );
  static const _excited = EmotionBubbleTheme(
    glowColor: Color(0xFFBB52FF),
    borderColor: Color(0xFFD070FF),
    bgTint: Color(0x14BB52FF),
    entranceCurve: Curves.easeOutBack,
    emoji: '✨',
  );
  static const _shy = EmotionBubbleTheme(
    glowColor: Color(0xFFFF9EB0),
    borderColor: Color(0xFFFFB6C1),
    bgTint: Color(0x12FF9EB0),
    entranceCurve: Curves.easeOutQuart,
    emoji: '🥺',
  );
  static const _grateful = EmotionBubbleTheme(
    glowColor: Color(0xFFFFD166),
    borderColor: Color(0xFFFFE08A),
    bgTint: Color(0x14FFD166),
    entranceCurve: Curves.easeOutQuart,
    emoji: '💝',
  );
  static const _sleepy = EmotionBubbleTheme(
    glowColor: Color(0xFF607D8B),
    borderColor: Color(0xFF78909C),
    bgTint: Color(0x10607D8B),
    entranceCurve: Curves.easeInOutQuad,
    emoji: '🌙',
  );
  static const _flirty = EmotionBubbleTheme(
    glowColor: Color(0xFFFF4FA8),
    borderColor: Color(0xFFFF69B4),
    bgTint: Color(0x18FF4FA8),
    entranceCurve: Curves.easeOutBack,
    emoji: '😘',
  );
  static const _curious = EmotionBubbleTheme(
    glowColor: Color(0xFF7B68EE),
    borderColor: Color(0xFF9370DB),
    bgTint: Color(0x147B68EE),
    entranceCurve: Curves.easeOutQuart,
    emoji: '🤔',
  );
  static const _neutral = EmotionBubbleTheme(
    glowColor: Color(0x00000000),
    borderColor: Color(0x00000000),
    bgTint: Color(0x00000000),
    entranceCurve: Curves.easeOut,
    emoji: '',
  );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// EmotionBubbleWrapper
///
/// Wraps any chat bubble with emotion-driven entrance animation + glow.
/// Use for AI messages only.
/// ─────────────────────────────────────────────────────────────────────────────
class EmotionBubbleWrapper extends StatefulWidget {
  final Widget child;
  final EmotionBubbleTheme theme;
  final bool isAi;

  const EmotionBubbleWrapper({
    super.key,
    required this.child,
    required this.theme,
    this.isAi = true,
  });

  @override
  State<EmotionBubbleWrapper> createState() => _EmotionBubbleWrapperState();
}

class _EmotionBubbleWrapperState extends State<EmotionBubbleWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: widget.theme.entranceCurve),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: widget.isAi ? const Offset(-0.08, 0) : const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasGlow = widget.isAi && widget.theme.glowColor.alpha > 0;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          alignment: widget.isAi ? Alignment.centerLeft : Alignment.centerRight,
          child: hasGlow
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: widget.theme.glowColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: widget.child,
                )
              : widget.child,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// MoodGradientBackground
///
/// Animated gradient that shifts color based on current WaifuMood.
/// Wrap the Scaffold body with this for live mood-driven backgrounds.
/// ─────────────────────────────────────────────────────────────────────────────
class MoodGradientBackground extends StatefulWidget {
  final String moodLabel;
  final Widget child;

  const MoodGradientBackground({
    super.key,
    required this.moodLabel,
    required this.child,
  });

  @override
  State<MoodGradientBackground> createState() => _MoodGradientBackgroundState();
}

class _MoodGradientBackgroundState extends State<MoodGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  List<Color> _prevColors = _colorsForMood('Happy 😊');
  List<Color> _nextColors = _colorsForMood('Happy 😊');

  static List<Color> _colorsForMood(String label) {
    final l = label.toLowerCase();
    if (l.contains('happy')) {
      return [
        const Color(0xFF1A0A1E),
        const Color(0xFF2D0A24),
        const Color(0xFF1A0A1E)
      ];
    }
    if (l.contains('playful')) {
      return [
        const Color(0xFF1A0D00),
        const Color(0xFF2A1500),
        const Color(0xFF0D0A00)
      ];
    }
    if (l.contains('clingy')) {
      return [
        const Color(0xFF1E0015),
        const Color(0xFF3A0030),
        const Color(0xFF1A0015)
      ];
    }
    if (l.contains('jealous')) {
      return [
        const Color(0xFF1A0800),
        const Color(0xFF2A1000),
        const Color(0xFF150600)
      ];
    }
    if (l.contains('cold')) {
      return [
        const Color(0xFF001629),
        const Color(0xFF00203D),
        const Color(0xFF001020)
      ];
    }
    if (l.contains('guarded')) {
      return [
        const Color(0xFF120020),
        const Color(0xFF1E0035),
        const Color(0xFF0E0018)
      ];
    }
    if (l.contains('sad')) {
      return [
        const Color(0xFF080E1A),
        const Color(0xFF0F1628),
        const Color(0xFF060A14)
      ];
    }
    if (l.contains('sleepy')) {
      return [
        const Color(0xFF050810),
        const Color(0xFF0A0E1B),
        const Color(0xFF040609)
      ];
    }
    if (l.contains('flirty') || l.contains('romantic')) {
      return [
        const Color(0xFF1A0515),
        const Color(0xFF2D0820),
        const Color(0xFF1A0515)
      ];
    }
    if (l.contains('excited') || l.contains('energetic')) {
      return [
        const Color(0xFF1A0A2E),
        const Color(0xFF2D0F3E),
        const Color(0xFF120820)
      ];
    }
    return [
      const Color(0xFF0D0D19),
      const Color(0xFF16161E),
      const Color(0xFF0D0D19)
    ];
  }

  @override
  void initState() {
    super.initState();
    _prevColors = _colorsForMood(widget.moodLabel);
    _nextColors = _prevColors;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine);
  }

  @override
  void didUpdateWidget(MoodGradientBackground old) {
    super.didUpdateWidget(old);
    if (old.moodLabel != widget.moodLabel) {
      _prevColors = _currentColors;
      _nextColors = _colorsForMood(widget.moodLabel);
      _ctrl.forward(from: 0);
    }
  }

  List<Color> get _currentColors {
    final t = _anim.value;
    return List.generate(_prevColors.length, (i) {
      return Color.lerp(_prevColors[i], _nextColors[i], t) ?? _nextColors[i];
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) {
        final colors = _currentColors;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ParticleOverlay
///
/// Floating heart/star particles that rise from the bottom on emotional messages.
/// Trigger with ParticleOverlayController.trigger(context, emotion).
/// ─────────────────────────────────────────────────────────────────────────────
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  double rotation;
  double rotationSpeed;
  String emoji;
  _Particle(
      {required this.x,
      required this.y,
      required this.vx,
      required this.vy,
      required this.size,
      required this.opacity,
      required this.rotation,
      required this.rotationSpeed,
      required this.emoji});
}

class ParticleOverlay extends StatefulWidget {
  const ParticleOverlay({super.key});
  @override
  State<ParticleOverlay> createState() => ParticleOverlayState();
}

class ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final _rand = math.Random();
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..addListener(_tick);
  }

  void trigger(String emotion) {
    final emojis = _emojisFor(emotion);
    final numParticles = 10 + _rand.nextInt(6); // Slightly fewer for perf
    setState(() {
      for (int i = 0; i < numParticles; i++) {
        _particles.add(_Particle(
          x: 0.1 + _rand.nextDouble() * 0.8,
          y: 1.1,
          vx: (_rand.nextDouble() - 0.5) * 0.006,
          vy: -(0.004 + _rand.nextDouble() * 0.005),
          size: 16 + _rand.nextDouble() * 20,
          opacity: 0.75 + _rand.nextDouble() * 0.25,
          rotation: _rand.nextDouble() * 6.28,
          rotationSpeed: (_rand.nextDouble() - 0.5) * 0.08,
          emoji: emojis[_rand.nextInt(emojis.length)],
        ));
      }
    });
    // Start animation loop only when we have particles
    if (!_isAnimating) {
      _isAnimating = true;
      _ctrl.repeat();
    }
    HapticFeedback.lightImpact();
  }

  static List<String> _emojisFor(String emotion) {
    switch (emotion) {
      case 'love':
        return ['❤️', '💕', '💗', '💖', '✨'];
      case 'amused':
        return ['😂', '⭐', '✨', '🌟', '💫'];
      case 'excited':
        return ['🎉', '✨', '🌟', '💫', '🎊'];
      case 'sad':
        return ['🥹', '💙', '🌊', '💧', '🫶'];
      case 'love_sent':
        return ['💌', '💕', '❤️', '🌸', '💗'];
      case 'flirty':
        return ['😘', '💋', '💕', '💗', '✨'];
      case 'curious':
        return ['🔮', '✨', '💫', '🌟', '⭐'];
      case 'shy':
        return ['🌸', '💕', '🥺', '✨', '💗'];
      default:
        return ['✨', '💫', '⭐', '🌟', '💖'];
    }
  }

  void _tick() {
    if (_particles.isEmpty) {
      // Stop animation when idle — zero CPU cost
      if (_isAnimating) {
        _ctrl.stop();
        _isAnimating = false;
      }
      return;
    }
    setState(() {
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.opacity -= 0.003;
        p.rotation += p.rotationSpeed;
        p.vy -= 0.00006; // gentle upward acceleration
        // Smooth sinusoidal sway instead of random noise
        p.vx += math.sin(p.y * 12) * 0.00008;
      }
      _particles.removeWhere((p) => p.opacity <= 0 || p.y < -0.1);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          children: _particles.map((p) {
            return Positioned(
              left: p.x * size.width - p.size / 2,
              top: p.y * size.height - p.size / 2,
              child: Opacity(
                opacity: p.opacity.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: p.rotation,
                  child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// EnhancedTypingIndicator
///
/// Replaces the basic 3-dot indicator with mood-aware animated expression.
/// Shows blushing avatar + variable-speed dots based on current mood.
/// ─────────────────────────────────────────────────────────────────────────────
class EnhancedTypingIndicator extends StatefulWidget {
  final String moodLabel;
  const EnhancedTypingIndicator({super.key, required this.moodLabel});

  @override
  State<EnhancedTypingIndicator> createState() =>
      _EnhancedTypingIndicatorState();
}

class _EnhancedTypingIndicatorState extends State<EnhancedTypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _dotCtrls;
  late final List<Animation<double>> _dotAnims;
  late AnimationController _blushCtrl;
  late Animation<double> _blushAnim;

  static int _speedMs(String mood) {
    final l = mood.toLowerCase();
    if (l.contains('excited') || l.contains('playful')) return 220;
    if (l.contains('happy')) return 300;
    if (l.contains('sad') || l.contains('sleepy')) return 600;
    if (l.contains('cold') || l.contains('guarded')) return 500;
    return 380;
  }

  static Color _dotColor(String mood) {
    final l = mood.toLowerCase();
    if (l.contains('jealous')) return const Color(0xFFFF6B35);
    if (l.contains('cold')) return const Color(0xFF79C0FF);
    if (l.contains('sad')) return const Color(0xFF79C0FF);
    if (l.contains('guarded')) return const Color(0xFFBB52FF);
    if (l.contains('clingy')) return const Color(0xFFFF4FA8);
    if (l.contains('playful')) return const Color(0xFFFFD700);
    return const Color(0xFFFF4FA8);
  }

  static String _moodText(String mood) {
    final l = mood.toLowerCase();
    if (l.contains('sad')) return 'thinking slowly...';
    if (l.contains('sleepy')) return 'yawning...';
    if (l.contains('excited')) return 'typing fast!!';
    if (l.contains('jealous')) return 'hmph...';
    if (l.contains('cold')) return '...';
    if (l.contains('playful')) return 'teehee~';
    if (l.contains('clingy')) return 'thinking of you~';
    return 'typing...';
  }

  @override
  void initState() {
    super.initState();
    final speed = _speedMs(widget.moodLabel);
    _dotCtrls = List.generate(
        3,
        (i) => AnimationController(
              vsync: this,
              duration: Duration(milliseconds: speed),
            ));
    _dotAnims = _dotCtrls
        .map((c) => Tween<double>(begin: 0, end: -8)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
    _blushCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _blushAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _blushCtrl, curve: Curves.easeInOutSine));
    _startBounce();
  }

  void _startBounce() async {
    final speed = _speedMs(widget.moodLabel);
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) break;
        unawaited(_dotCtrls[i].forward().then((_) => _dotCtrls[i].reverse()));
        await Future.delayed(Duration(milliseconds: (speed * 0.6).round()));
      }
      await Future.delayed(Duration(milliseconds: speed + 100));
    }
  }

  @override
  void dispose() {
    for (final c in _dotCtrls) {
      c.dispose();
    }
    _blushCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor(widget.moodLabel);
    final text = _moodText(widget.moodLabel);
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.09),
              dotColor.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dotColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: dotColor.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // Animated blush circle with glow
          AnimatedBuilder(
            animation: _blushAnim,
            builder: (_, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: _blushAnim.value),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: _blushAnim.value * 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ...List.generate(
              3,
              (i) => AnimatedBuilder(
                    animation: _dotAnims[i],
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _dotAnims[i].value),
                      child: Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                            color: dotColor.withValues(alpha: 0.85),
                            shape: BoxShape.circle),
                      ),
                    ),
                  )),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontStyle: FontStyle.italic)),
        ]),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// StreakBadge
///
/// Shows the current daily streak count. Animates on increment.
/// ─────────────────────────────────────────────────────────────────────────────
class StreakBadge extends StatefulWidget {
  final int streak;
  const StreakBadge({super.key, required this.streak});
  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(StreakBadge old) {
    super.didUpdateWidget(old);
    if (old.streak != widget.streak) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHot = widget.streak >= 7;
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: isHot
                  ? [const Color(0xFFFF6B35), const Color(0xFFFF4FA8)]
                  : [const Color(0xFFFF5252), const Color(0xFFD50000)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isHot ? const Color(0xFFFF4FA8) : const Color(0xFFFF5252))
                  .withValues(alpha: 0.4),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(isHot ? '🔥' : '⚡', style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text('${widget.streak}d',
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ]),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// MessageReactionBar
///
/// Shows emoji reaction options on long-press of an AI message.
/// ─────────────────────────────────────────────────────────────────────────────
class MessageReactionBar extends StatefulWidget {
  final Function(String emoji) onReact;
  const MessageReactionBar({super.key, required this.onReact});

  static const _reactions = ['❤️', '😂', '😢', '✨', '🔥', '😤'];

  @override
  State<MessageReactionBar> createState() => _MessageReactionBarState();
}

class _MessageReactionBarState extends State<MessageReactionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(MessageReactionBar._reactions.length, (i) {
            final emoji = MessageReactionBar._reactions[i];
            // Staggered entrance: each emoji pops in 60ms apart
            final delay = i * 0.1;
            final progress =
                ((_ctrl.value - delay) / (1 - delay)).clamp(0.0, 1.0);
            final scale = Curves.elasticOut.transform(progress);
            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onReact(emoji);
                Navigator.pop(context);
              },
              child: Transform.scale(
                scale: scale,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SurpriseMeButton
///
/// A glowing button that triggers a random activity.
/// ─────────────────────────────────────────────────────────────────────────────
class SurpriseMeButton extends StatefulWidget {
  final VoidCallback onPressed;
  const SurpriseMeButton({super.key, required this.onPressed});
  @override
  State<SurpriseMeButton> createState() => _SurpriseMeButtonState();
}

class _SurpriseMeButtonState extends State<SurpriseMeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFBB52FF), Color(0xFFFF4FA8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBB52FF)
                    .withValues(alpha: _glowAnim.value * 0.5),
                blurRadius: 14,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedRotation(
              turns: _glowAnim.value * 0.1,
              duration: const Duration(milliseconds: 100),
              child: const Text('🎲', style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 6),
            Text('Surprise me!',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// EmotionStickerBar
///
/// Shows 3 contextual sticker-style emoji chips after detecting emotion.
/// ─────────────────────────────────────────────────────────────────────────────
class EmotionStickerBar extends StatefulWidget {
  final String emotion;
  final Function(String sticker) onSend;

  const EmotionStickerBar(
      {super.key, required this.emotion, required this.onSend});

  static List<String> stickersFor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'love':
        return ['💕 Sending love', '🥰 I love you too~', '💗 Awww~'];
      case 'sad':
        return ['🥺 It\'s okay...', '🤗 I\'m here for you', '💙 Don\'t cry~'];
      case 'amused':
        return ['😂 LOL!', '🤣 Stop it~', '😝 You\'re funny!'];
      case 'excited':
        return ['🎉 Yay!!', '✨ Amazing!!', '🔥 Let\'s go!!'];
      case 'angry':
        return ['😌 Calm down~', '🫂 I get it', '🙏 Sorry~'];
      case 'flirty':
        return ['😘 Kiss back~', '😏 Oh really?', '💋 Darling~'];
      case 'curious':
        return ['🤔 Tell me more', '💡 Interesting!', '🔍 Go on~'];
      case 'shy':
        return ['🥺 So cute~', '💕 Adorable!', '🫣 Don\'t hide~'];
      default:
        return ['💬 Tell me more', '🤔 Interesting!', '💕 Aww~'];
    }
  }

  @override
  State<EmotionStickerBar> createState() => _EmotionStickerBarState();
}

class _EmotionStickerBarState extends State<EmotionStickerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stickers = EmotionStickerBar.stickersFor(widget.emotion);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(stickers.length, (i) {
            final s = stickers[i];
            // Staggered slide-in from right
            final delay = i * 0.2;
            final progress =
                ((_ctrl.value - delay) / (1 - delay)).clamp(0.0, 1.0);
            final slide = Curves.easeOutCubic.transform(progress);
            final opacity = progress;
            return Transform.translate(
              offset: Offset(20 * (1 - slide), 0),
              child: Opacity(
                opacity: opacity,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _StickerChip(
                    label: s,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onSend(s);
                    },
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Individual sticker chip with press-scale feedback
class _StickerChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _StickerChip({required this.label, required this.onTap});
  @override
  State<_StickerChip> createState() => _StickerChipState();
}

class _StickerChipState extends State<_StickerChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(widget.label,
              style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
        ),
      ),
    );
  }
}
