import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A fully-animated waifu character display widget.
///
/// Layers (bottom to top):
///   1. Aura glow rings  — driven by isSpeaking / isListening / idle state
///   2. Character image  — breathing scale + hair-float translate
///   3. Blink overlay    — scaleY flash every 4-7 seconds
///   4. Speaking bloom   — radial pink glow when isSpeaking
///
/// All animation controllers share this widget's [TickerProviderStateMixin].
/// The whole widget is wrapped in a [RepaintBoundary] so it can repaint at
/// 60 fps without triggering parent repaints.
class WaifuCharacterWidget extends StatefulWidget {
  final String imagePath;
  final String? customImagePath; // nullable — overrides imagePath
  final bool isSpeaking;
  final bool isListening;
  final double size;
  final Color auraColor;

  const WaifuCharacterWidget({
    super.key,
    required this.imagePath,
    this.customImagePath,
    required this.isSpeaking,
    required this.isListening,
    this.size = 150,
    this.auraColor = const Color(0xFFFF4D8D),
  });

  @override
  State<WaifuCharacterWidget> createState() => _WaifuCharacterWidgetState();
}

class _WaifuCharacterWidgetState extends State<WaifuCharacterWidget>
    with TickerProviderStateMixin {
  // ── Breathing (idle scale 1.0 → 1.022) ────────────────────────────────────
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  // ── Hair float (translateX ±3px) ──────────────────────────────────────────
  late final AnimationController _hairCtrl;
  late final Animation<double> _hairAnim;

  // ── Eye blink (scaleY 1.0 → 0.05 → 1.0) ─────────────────────────────────
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkAnim;

  // ── Aura rings (opacity + scale pulse) ───────────────────────────────────
  late final AnimationController _auraCtrl;
  late final Animation<double> _auraAnim;

  // ── Entrance slide-up + fade ───────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  // ── Speaking jaw bloom ─────────────────────────────────────────────────────
  late final AnimationController _speakCtrl;
  late final Animation<double> _speakAnim;

  // Blink random timer
  late Duration _nextBlinkIn;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();

    // Breathing
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 1.0, end: 1.022).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOutSine),
    );

    // Hair float (offset from breathing for organic feel)
    _hairCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _hairAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _hairCtrl, curve: Curves.easeInOutSine),
    );

    // Eye blink
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _blinkAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
    _scheduleNextBlink();

    // Aura rings
    _auraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _auraAnim = CurvedAnimation(parent: _auraCtrl, curve: Curves.easeInOutSine);

    // Speak bloom
    _speakCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _speakAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _speakCtrl, curve: Curves.easeInOutSine),
    );

    // Entrance
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut),
    );
    _entranceCtrl.forward();
  }

  void _scheduleNextBlink() {
    _nextBlinkIn = Duration(
      milliseconds: 4000 + math.Random().nextInt(3000), // 4–7s
    );
    Future.delayed(_nextBlinkIn, _doBlink);
  }

  Future<void> _doBlink() async {
    if (!mounted || _isBlinking) return;
    _isBlinking = true;
    await _blinkCtrl.forward(from: 0);
    _blinkCtrl.reset();
    _isBlinking = false;
    _scheduleNextBlink();
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _hairCtrl.dispose();
    _blinkCtrl.dispose();
    _auraCtrl.dispose();
    _speakCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _entranceFade,
        child: SlideTransition(
          position: _entranceSlide,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _breathCtrl,
              _hairCtrl,
              _blinkCtrl,
              _auraCtrl,
              _speakCtrl,
            ]),
            builder: (context, _) {
              return SizedBox(
                width: widget.size + 60,
                height: widget.size + 60,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // ── Layer 1: Aura rings ──────────────────────────────
                    ..._buildAuraRings(),

                    // ── Layer 2: Speaking bloom ──────────────────────────
                    if (widget.isSpeaking) _buildSpeakBloom(),

                    // ── Layer 3: Character image with breathing + hair ───
                    _buildCharacterImage(),

                    // ── Layer 4: Blink overlay ───────────────────────────
                    _buildBlinkOverlay(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Aura Rings ────────────────────────────────────────────────────────────

  List<Widget> _buildAuraRings() {
    final isActive = widget.isSpeaking || widget.isListening;
    final baseOpacity = widget.isSpeaking
        ? 0.55
        : widget.isListening
            ? 0.38
            : 0.18;
    final pulseScale = isActive ? 1.0 + _auraAnim.value * 0.18 : 1.0 + _auraAnim.value * 0.06;

    return List.generate(3, (i) {
      final ringScale = pulseScale + i * 0.14;
      final ringOpacity = (baseOpacity / (i + 1)) * (1.0 - _auraAnim.value * 0.4);
      final ringSize = widget.size * ringScale;
      return Transform.scale(
        scale: ringScale,
        child: Container(
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.auraColor.withValues(alpha: ringOpacity.clamp(0.0, 1.0)),
                widget.auraColor.withValues(alpha: 0.0),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),
      );
    });
  }

  // ── Speaking bloom ────────────────────────────────────────────────────────

  Widget _buildSpeakBloom() {
    return Container(
      width: widget.size * 1.15,
      height: widget.size * 1.15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.auraColor.withValues(alpha: 0.30 * _speakAnim.value),
            blurRadius: 28 + _speakAnim.value * 14,
            spreadRadius: 2 + _speakAnim.value * 4,
          ),
          BoxShadow(
            color: const Color(0xFFFF90BB).withValues(alpha: 0.15 * _speakAnim.value),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }

  // ── Character image ───────────────────────────────────────────────────────

  Widget _buildCharacterImage() {
    final imgPath = widget.customImagePath ?? widget.imagePath;
    final isFile = imgPath.startsWith('/') || imgPath.startsWith('file:');

    return Transform.translate(
      offset: Offset(_hairAnim.value, 0), // hair float X
      child: Transform.scale(
        scale: _breathAnim.value, // breathing scale
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.auraColor.withValues(
                alpha: widget.isSpeaking
                    ? 0.7 * _speakAnim.value
                    : widget.isListening
                        ? 0.5 * _auraAnim.value
                        : 0.25,
              ),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.auraColor.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: isFile
                ? Image.asset(
                    imgPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(),
                  )
                : Image.asset(
                    imgPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Blink overlay ─────────────────────────────────────────────────────────

  Widget _buildBlinkOverlay() {
    if (_blinkAnim.value >= 0.98) return const SizedBox.shrink();
    return ClipOval(
      child: Transform.scale(
        scaleY: _blinkAnim.value,
        child: Container(
          width: widget.size,
          height: widget.size * 0.3,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: (1.0 - _blinkAnim.value) * 0.85),
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: widget.auraColor.withValues(alpha: 0.2),
      child: Icon(
        Icons.favorite_rounded,
        color: widget.auraColor,
        size: widget.size * 0.4,
      ),
    );
  }
}


/// Exported convenience wrapper: animates equalizer-style bars.
/// Drop this anywhere to show an audio-reactive microphone indicator.
class WaifuEqualizerBars extends StatefulWidget {
  final bool isActive;
  final bool isHighEnergy; // true = speaking, false = listening
  final Color color;
  final double width;
  final double height;

  const WaifuEqualizerBars({
    super.key,
    required this.isActive,
    this.isHighEnergy = false,
    this.color = const Color(0xFFFF4D8D),
    this.width = 48,
    this.height = 32,
  });

  @override
  State<WaifuEqualizerBars> createState() => _WaifuEqualizerBarsState();
}

class _WaifuEqualizerBarsState extends State<WaifuEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barCtrl;
  static const int _barCount = 5;
  static const List<double> _phases = [0.0, 0.4, 0.8, 0.2, 0.6];

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.isActive) _barCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(WaifuEqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_barCtrl.isAnimating) {
      _barCtrl.repeat(reverse: true);
    } else if (!widget.isActive && _barCtrl.isAnimating) {
      _barCtrl.animateTo(0.1, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _barCtrl,
        builder: (_, __) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_barCount, (i) {
                final t = _barCtrl.value;
                final phase = _phases[i];
                final raw = math.sin((t + phase) * math.pi);
                final minH = widget.isHighEnergy ? 0.25 : 0.12;
                final maxH = widget.isHighEnergy ? 1.0 : 0.55;
                final fraction = widget.isActive
                    ? minH + (raw.abs() * (maxH - minH))
                    : 0.12;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: (widget.width / _barCount) - 2.5,
                  height: (widget.height * fraction).clamp(3.0, widget.height),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: widget.isActive ? 0.85 : 0.38,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
