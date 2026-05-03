import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/ai_personalization/alter_ego_service.dart';
import 'package:flutter/material.dart';
import 'package:anime_waifu/config/app_themes.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AlterEgoPage extends StatefulWidget {
  const AlterEgoPage({super.key});
  @override
  State<AlterEgoPage> createState() => _AlterEgoPageState();
}

class _AlterEgoPageState extends State<AlterEgoPage> {
  final _service = AlterEgoService.instance;
  AlterEgoMode _current = AlterEgoMode.normal;
  bool _autoMode = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() { _current = _service.currentMode; _autoMode = _service.isAutoMode; });
    });
  }

  Future<void> _switch(AlterEgoMode mode) async {
    HapticFeedback.mediumImpact();
    await _service.setMode(mode);
    if (mounted) {
      setState(() => _current = mode);
      showSuccessSnackbar(context, '${mode.emoji} Switched to ${mode.label}');
    }
  }

  Future<void> _toggleAuto(bool v) async {
    await _service.setAutoMode(v);
    if (mounted) setState(() => _autoMode = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appTokens;
    final primary = theme.colorScheme.primary;
    final activeColor = Color(_current.color);

    return FeaturePageV2(
      title: 'ALTER EGO',
      subtitle: _current.label,
      onBack: () => Navigator.pop(context),
      content: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Active persona hero ──────────────────────────────────────────
          AnimatedEntry(
            index: 0,
            child: GlassCard(
              margin: EdgeInsets.zero,
              glow: true,
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeColor.withValues(alpha: 0.15),
                    border: Border.all(color: activeColor.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Center(child: Text(_current.emoji, style: const TextStyle(fontSize: 30))),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Active persona', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_current.label, style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(_current.description, style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── Stats ────────────────────────────────────────────────────────
          AnimatedEntry(
            index: 1,
            child: Row(children: [
              Expanded(child: StatCard(title: 'Personas', value: '${AlterEgoMode.values.length}', icon: Icons.theater_comedy_rounded, color: primary)),
              Expanded(child: StatCard(title: 'Auto Mode', value: _autoMode ? 'On' : 'Off', icon: Icons.auto_awesome_rounded, color: Colors.amberAccent)),
              Expanded(child: StatCard(title: 'Active', value: _current.emoji, icon: Icons.person_rounded, color: activeColor)),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Auto mode toggle ──────────────────────────────────────────────
          AnimatedEntry(
            index: 2,
            child: GlassCard(
              margin: EdgeInsets.zero,
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.amberAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Auto Mode', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700)),
                  Text('Persona switches automatically based on mood', style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 11)),
                ])),
                Switch(value: _autoMode, onChanged: _toggleAuto),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Persona list ──────────────────────────────────────────────────
          AnimatedEntry(
            index: 3,
            child: Text('CHOOSE PERSONA', style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 10),
          ...AlterEgoMode.values.toList().asMap().entries.map((entry) {
            final mode = entry.value;
            final isActive = _current == mode;
            final color = Color(mode.color);
            return AnimatedEntry(
              index: 4 + entry.key,
              child: GestureDetector(
                onTap: () => _switch(mode),
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
                      child: Center(child: Text(mode.emoji, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(mode.label, style: GoogleFonts.outfit(color: isActive ? color : theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(mode.description, style: GoogleFonts.outfit(color: tokens.textMuted, fontSize: 12)),
                      if (mode.promptDirective.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          mode.promptDirective.length > 70 ? '${mode.promptDirective.substring(0, 70)}…' : mode.promptDirective,
                          style: GoogleFonts.outfit(color: tokens.textSoft, fontSize: 10),
                        ),
                      ],
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
