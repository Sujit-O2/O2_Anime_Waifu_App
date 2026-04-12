import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fullscreen waifu voice call screen — mimics a video call UI.
/// Integrates with the calling context's STT/TTS by invoking [onMicPressed]
/// which the parent can hook into the existing speech pipeline.
class WaifuVoiceCallScreen extends StatefulWidget {
  final String waifuImageAsset;
  final String waifuName;
  final VoidCallback? onMicPressed;
  final VoidCallback? onEndCall;

  const WaifuVoiceCallScreen({
    super.key,
    this.waifuImageAsset = 'assets/img/z2s.jpg',
    this.waifuName = 'Zero Two',
    this.onMicPressed,
    this.onEndCall,
  });

  @override
  State<WaifuVoiceCallScreen> createState() => _WaifuVoiceCallScreenState();
}

class _WaifuVoiceCallScreenState extends State<WaifuVoiceCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rippleCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _rippleAnim;

  bool _muted = false;
  bool _speakerOn = true;
  bool _talking = false;
  Timer? _callTimer;
  int _callSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1, milliseconds: 500))
      ..repeat();
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rippleAnim = Tween<double>(begin: 0.85, end: 1.25)
        .animate(CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));

    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  String get _callDuration {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleMute() => setState(() => _muted = !_muted);
  void _toggleSpeaker() => setState(() => _speakerOn = !_speakerOn);

  void _handleMic() {
    setState(() => _talking = !_talking);
    widget.onMicPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: blurred waifu
          Positioned.fill(
            child: Image.asset(
              widget.waifuImageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A0028), Color(0xFF0D000F)],
                    ),
                  )),
            ),
          ),
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Call status
                Text(
                  widget.waifuName,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent,
                      boxShadow: [
                        BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.6), blurRadius: 8)
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_callDuration,
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
                ]),
                const Spacer(),
                // Avatar with pulse rings
                _buildAvatar(),
                const Spacer(),
                // Talking indicator
                AnimatedOpacity(
                  opacity: _talking ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => _buildSoundBar(i)),
                    ),
                  ),
                ),
                // Buttons
                _buildControls(),
                const SizedBox(height: 24),
                // End call button
                _buildEndCallButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ripple ring
          AnimatedBuilder(
            animation: _rippleAnim,
            builder: (_, __) => Transform.scale(
              scale: _rippleAnim.value,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF4FA8).withValues(alpha: (1.25 - _rippleAnim.value).clamp(0, 1)),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          // Pulse ring
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4FA8).withValues(alpha: 0.08),
                  border: Border.all(
                    color: const Color(0xFFFF4FA8).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          // Avatar
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4FA8).withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                widget.waifuImageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2A0040),
                  child: const Icon(Icons.person_rounded, color: Colors.pink, size: 64),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundBar(int index) {
    final delay = index * 0.15;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final t = (_pulseCtrl.value + delay) % 1.0;
        final height = 10.0 + math.sin(t * math.pi) * 22.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 4,
            height: height.clamp(8.0, 32.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4FA8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute
          _ControlBtn(
            icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: _muted ? 'Unmute' : 'Mute',
            isActive: !_muted,
            color: Colors.white,
            onTap: _toggleMute,
          ),
          // Mic (main action)
          GestureDetector(
            onTap: _handleMic,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4FA8), Color(0xFFAA00FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4FA8).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _talking ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          // Speaker
          _ControlBtn(
            icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            label: _speakerOn ? 'Speaker' : 'Earpiece',
            isActive: _speakerOn,
            color: Colors.white,
            onTap: _toggleSpeaker,
          ),
        ],
      ),
    );
  }

  /// End call button — CRITICAL: was missing before
  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: () {
        widget.onEndCall?.call();
        Navigator.pop(context);
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.redAccent,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: isActive ? color : Colors.white38, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}



