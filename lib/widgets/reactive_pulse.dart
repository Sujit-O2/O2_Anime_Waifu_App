import 'package:flutter/material.dart';

class ReactivePulse extends StatefulWidget {
  final bool isSpeaking;
  final bool isListening;
  final Color baseColor;
  final Widget child;

  const ReactivePulse({
    super.key,
    required this.isSpeaking,
    required this.isListening,
    required this.baseColor,
    required this.child,
  });

  @override
  State<ReactivePulse> createState() => _ReactivePulseState();
}

class _ReactivePulseState extends State<ReactivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 +
            (widget.isSpeaking ? 0.2 : (widget.isListening ? 0.1 : 0.05)) *
                _pulseController.value;
        final opacity =
            (widget.isSpeaking ? 0.6 : (widget.isListening ? 0.4 : 0.25)) *
                (1.0 - _pulseController.value);

        return Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              Transform.scale(
                scale: scale + (i * 0.15),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.baseColor.withOpacity(opacity / (i + 1)),
                        widget.baseColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }
}
