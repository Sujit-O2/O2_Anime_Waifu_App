import 'package:anime_waifu/services/conversation/conversation_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversationModePage extends StatefulWidget {
  const ConversationModePage({super.key});

  @override
  State<ConversationModePage> createState() => _ConversationModePageState();
}

class _ConversationModePageState extends State<ConversationModePage> {
  final _service = ConversationModeService.instance;
  ConversationMode _current = ConversationMode.romantic;

  static const _modeColors = {
    ConversationMode.romantic: Color(0xFFFF4FA8),
    ConversationMode.professional: Color(0xFF79C0FF),
    ConversationMode.playful: Color(0xFFFFD700),
    ConversationMode.therapist: Color(0xFF4CAF50),
    ConversationMode.mentor: Color(0xFFFF9800),
    ConversationMode.friend: Color(0xFF9C27B0),
  };

  static const _modeIcons = {
    ConversationMode.romantic: Icons.favorite_rounded,
    ConversationMode.professional: Icons.work_rounded,
    ConversationMode.playful: Icons.sports_esports_rounded,
    ConversationMode.therapist: Icons.psychology_rounded,
    ConversationMode.mentor: Icons.school_rounded,
    ConversationMode.friend: Icons.people_rounded,
  };

  @override
  void initState() {
    super.initState();
    _current = _service.currentMode;
    _service.onModeChanged = (mode) {
      if (mounted) setState(() => _current = mode);
    };
  }

  @override
  void dispose() {
    _service.onModeChanged = null;
    super.dispose();
  }

  void _selectMode(ConversationMode mode) {
    HapticFeedback.mediumImpact();
    _service.setMode(mode);
    setState(() => _current = mode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${mode.emoji} ${mode.label} mode activated'),
        backgroundColor: (_modeColors[mode] ?? Colors.pinkAccent)
            .withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _modeColors[_current] ?? Colors.pinkAccent;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('💬 Conversation Modes',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active mode card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeColor.withValues(alpha: 0.2),
                  activeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activeColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(_current.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Active Mode',
                        style: GoogleFonts.outfit(
                            color: Colors.white54, fontSize: 12)),
                    Text(_current.label,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                  ]),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _service.getSystemPromptModifier(),
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Select Mode',
              style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          ...ConversationMode.values.map((mode) {
            final isActive = _current == mode;
            final color = _modeColors[mode] ?? Colors.pinkAccent;
            final icon = _modeIcons[mode] ?? Icons.chat_rounded;
            return GestureDetector(
              onTap: () => _selectMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? color.withValues(alpha: 0.5)
                        : Colors.white12,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: isActive ? 0.2 : 0.1),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Text(mode.emoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(mode.label,
                            style: GoogleFonts.outfit(
                                color: isActive ? color : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ]),
                      const SizedBox(height: 2),
                      Text(_service.getModeDescription(),
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 11)),
                    ]),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Active',
                          style: GoogleFonts.outfit(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
