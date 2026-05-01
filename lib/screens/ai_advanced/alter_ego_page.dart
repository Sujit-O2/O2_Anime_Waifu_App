import 'package:anime_waifu/services/ai_personalization/alter_ego_service.dart';
import 'package:flutter/material.dart';
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
    _load();
  }

  Future<void> _load() async {
    // Give service time to load from prefs
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _current = _service.currentMode;
        _autoMode = _service.isAutoMode;
      });
    }
  }

  Future<void> _switchMode(AlterEgoMode mode) async {
    HapticFeedback.mediumImpact();
    await _service.setMode(mode);
    if (mounted) setState(() => _current = mode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${mode.emoji} Switched to ${mode.label}'),
          backgroundColor: Color(mode.color).withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleAuto(bool val) async {
    await _service.setAutoMode(val);
    if (mounted) setState(() => _autoMode = val);
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('🎭 Alter Ego Personas',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active mode banner
          _buildActiveBanner(),
          const SizedBox(height: 16),
          // Auto mode toggle
          _buildAutoToggle(),
          const SizedBox(height: 16),
          // Mode cards
          Text('Choose Persona',
              style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          ...AlterEgoMode.values.map((mode) => _buildModeCard(mode)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActiveBanner() {
    final color = Color(_current.color);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(_current.emoji,
                style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Active Persona',
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 12)),
            Text(_current.label,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
            const SizedBox(height: 4),
            Text(_current.description,
                style: GoogleFonts.outfit(
                    color: Colors.white60, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAutoToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded,
            color: Colors.amberAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Auto Mode',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            Text('Persona switches automatically based on mood',
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 11)),
          ]),
        ),
        Switch(
          value: _autoMode,
          onChanged: _toggleAuto,
          activeColor: Colors.amberAccent,
        ),
      ]),
    );
  }

  Widget _buildModeCard(AlterEgoMode mode) {
    final isActive = _current == mode;
    final color = Color(mode.color);
    return GestureDetector(
      onTap: () => _switchMode(mode),
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
            color: isActive ? color.withValues(alpha: 0.5) : Colors.white12,
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
            child: Center(
              child: Text(mode.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mode.label,
                  style: GoogleFonts.outfit(
                      color: isActive ? color : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              Text(mode.description,
                  style: GoogleFonts.outfit(
                      color: Colors.white54, fontSize: 12)),
              if (mode.promptDirective.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  mode.promptDirective.length > 80
                      ? '${mode.promptDirective.substring(0, 80)}...'
                      : mode.promptDirective,
                  style: GoogleFonts.outfit(
                      color: Colors.white30, fontSize: 10),
                ),
              ],
            ]),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Active',
                  style: GoogleFonts.outfit(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Text('Switch',
                  style: GoogleFonts.outfit(
                      color: Colors.white54, fontSize: 11)),
            ),
        ]),
      ),
    );
  }
}
