import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/conversation/conversation_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
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
    _service.onModeChanged = (m) { if (mounted) setState(() => _current = m); };
  }

  @override
  void dispose() {
    _service.onModeChanged = null;
    super.dispose();
  }

  void _select(ConversationMode mode) {
    HapticFeedback.mediumImpact();
    _service.setMode(mode);
    setState(() => _current = mode);
    showSuccessSnackbar(context, '${mode.emoji} ${mode.label} mode activated');
  }

  Color _colorFor(ConversationMode m) => _modeColors[m] ?? V2Theme.primaryColor;
  IconData _iconFor(ConversationMode m) => _modeIcons[m] ?? Icons.chat_rounded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final activeColor = _colorFor(_current);

    return FeaturePageV2(
      title: 'CONVERSATION MODES',
      subtitle: '${_current.emoji} ${_current.label} active',
      onBack: () => Navigator.pop(context),
      content: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Active mode hero ─────────────────────────────────────────────
          AnimatedEntry(
            index: 0,
            child: GlassCard(
              margin: EdgeInsets.zero,
              glow: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor.withValues(alpha: 0.15),
                      border: Border.all(color: activeColor.withValues(alpha: 0.5), width: 2),
                    ),
                    child: Center(child: Text(_current.emoji, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Active mode', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(_current.label, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                  ])),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: activeColor.withValues(alpha: 0.2))),
                  child: Text(_service.getSystemPromptModifier(), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12, height: 1.4)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── Stats ────────────────────────────────────────────────────────
          AnimatedEntry(
            index: 1,
            child: Row(children: [
              Expanded(child: StatCard(title: 'Modes', value: '${ConversationMode.values.length}', icon: Icons.chat_bubble_rounded, color: theme.colorScheme.primary)),
              Expanded(child: StatCard(title: 'Active', value: _current.emoji, icon: _iconFor(_current), color: activeColor)),
              Expanded(child: StatCard(title: 'Style', value: _current.label, icon: Icons.tune_rounded, color: Colors.amberAccent)),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Waifu commentary ─────────────────────────────────────────────
          const AnimatedEntry(index: 2, child: WaifuCommentary(mood: 'neutral')),
          const SizedBox(height: 16),

          // ── Mode list ────────────────────────────────────────────────────
          AnimatedEntry(
            index: 3,
            child: Text('SELECT MODE', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 10),
          ...ConversationMode.values.toList().asMap().entries.map((entry) {
            final mode = entry.value;
            final isActive = _current == mode;
            final color = _colorFor(mode);
            final icon = _iconFor(mode);
            return AnimatedEntry(
              index: 4 + entry.key,
              child: GestureDetector(
                onTap: () => _select(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.1) : tokens.panelMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isActive ? color.withValues(alpha: 0.5) : tokens.outline, width: isActive ? 1.5 : 1),
                    boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))] : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: isActive ? 0.2 : 0.08)),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(mode.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(mode.label, style: GoogleFonts.outfit(color: isActive ? color : theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 15)),
                      ]),
                      const SizedBox(height: 2),
                      Text(_service.getModeDescriptionFor(mode), style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
                    ])),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text('Active', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                      )
                    else
                      Icon(Icons.chevron_right_rounded, color: tokens.textSoft, size: 20),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
