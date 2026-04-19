import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';
import 'package:anime_waifu/services/ai_personalization/proactive_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Inner thought bubble widget — shows what she's "thinking but not saying".
/// Displayed as a semi-transparent floating bubble near the avatar with
/// a thought connector (dots leading to the bubble).
class InnerThoughtsBubble extends StatefulWidget {
  final String thought;
  final bool visible;
  final VoidCallback? onDismiss;

  const InnerThoughtsBubble({
    super.key,
    required this.thought,
    required this.visible,
    this.onDismiss,
  });

  @override
  State<InnerThoughtsBubble> createState() => _InnerThoughtsBubbleState();
}

class _InnerThoughtsBubbleState extends State<InnerThoughtsBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeScale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    if (widget.visible) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant InnerThoughtsBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _ctrl.forward();
    if (!widget.visible && oldWidget.visible) _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeScale,
      builder: (_, __) => Opacity(
        opacity: _ctrl.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.7 + _ctrl.value * 0.3,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thought bubble
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A0E2E).withValues(alpha: 0.95),
                        const Color(0xFF120820).withValues(alpha: 0.92),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFBB52FF).withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBB52FF).withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: const Color(0xFFBB52FF).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💭 ', style: const TextStyle(fontSize: 13)),
                      Flexible(
                        child: Text(
                          widget.thought,
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dot connector
                const ThoughtDotsIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThoughtDotsIndicator extends StatefulWidget {
  const ThoughtDotsIndicator({super.key});
  @override
  State<ThoughtDotsIndicator> createState() => _ThoughtDotsState();
}

class _ThoughtDotsState extends State<ThoughtDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
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
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
          final size = 4.0 + phase * 2.0;
          return Container(
            margin: EdgeInsets.all(size * 0.3),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  const Color(0xFFBB52FF).withValues(alpha: 0.4 + phase * 0.4),
            ),
          );
        }),
      ),
    );
  }
}

/// Generates an inner thought for the current mood and shows it.
/// Call this from the chat screen when AI is thinking.
class InnerThoughtsManager extends StatefulWidget {
  final Widget child;
  const InnerThoughtsManager({super.key, required this.child});

  @override
  State<InnerThoughtsManager> createState() => _InnerThoughtsManagerState();
}

class _InnerThoughtsManagerState extends State<InnerThoughtsManager> {
  String _thought = '';
  bool _visible = false;

  void showThought() {
    final mood = PersonalityEngine.instance.mood;
    final t = ProactiveAIService.generateInnerThought(mood);
    setState(() {
      _thought = t;
      _visible = true;
    });
    Future.delayed(const Duration(seconds: 4), hide);
  }

  void hide() {
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: InnerThoughtsBubble(
                thought: _thought,
                visible: _visible,
                onDismiss: hide,
              ),
            ),
          ),
      ],
    );
  }
}
