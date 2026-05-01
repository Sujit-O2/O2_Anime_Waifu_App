import 'package:anime_waifu/services/ai_personalization/emotional_recovery_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EmotionalRecoveryPage extends StatefulWidget {
  const EmotionalRecoveryPage({super.key});

  @override
  State<EmotionalRecoveryPage> createState() => _EmotionalRecoveryPageState();
}

class _EmotionalRecoveryPageState extends State<EmotionalRecoveryPage> {
  final _service = EmotionalRecoveryService.instance;
  bool _loading = true;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.loadPhase();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _triggerRecovery() async {
    HapticFeedback.mediumImpact();
    await _service.checkAndTrigger(
      gapSinceLastInteraction: const Duration(hours: 4),
      ignoredStreak: 0,
      trustScore: 50,
    );
    if (mounted) setState(() {});
  }

  Future<void> _reset() async {
    HapticFeedback.mediumImpact();
    setState(() => _resetting = true);
    await _service.resetRecovery();
    if (mounted) {
      setState(() => _resetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recovery arc reset'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _phaseColor(RecoveryPhase phase) {
    switch (phase) {
      case RecoveryPhase.none:
        return Colors.greenAccent;
      case RecoveryPhase.soften:
        return Colors.lightBlueAccent;
      case RecoveryPhase.acknowledge:
        return Colors.amberAccent;
      case RecoveryPhase.reduce:
        return Colors.orangeAccent;
      case RecoveryPhase.rebuild:
        return Colors.tealAccent;
    }
  }

  String _phaseEmoji(RecoveryPhase phase) {
    switch (phase) {
      case RecoveryPhase.none:
        return '💚';
      case RecoveryPhase.soften:
        return '🌸';
      case RecoveryPhase.acknowledge:
        return '💬';
      case RecoveryPhase.reduce:
        return '🌊';
      case RecoveryPhase.rebuild:
        return '🏗️';
    }
  }

  String _phaseLabel(RecoveryPhase phase) {
    switch (phase) {
      case RecoveryPhase.none:
        return 'Healthy — No Recovery Needed';
      case RecoveryPhase.soften:
        return 'Phase 1: Soften';
      case RecoveryPhase.acknowledge:
        return 'Phase 2: Acknowledge';
      case RecoveryPhase.reduce:
        return 'Phase 3: Reduce';
      case RecoveryPhase.rebuild:
        return 'Phase 4: Rebuild';
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = _service.phase;
    final color = _phaseColor(phase);
    final progress = _service.progress;

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
        title: Text('💚 Emotional Recovery',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.teal))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(_phaseEmoji(phase),
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Recovery Status',
                                style: GoogleFonts.outfit(
                                    color: Colors.white54, fontSize: 12)),
                            Text(_phaseLabel(phase),
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Text('Recovery Progress',
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 12)),
                        const Spacer(),
                        Text('${(progress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(
                                color: color, fontSize: 12)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Current hint
                if (_service.isInRecovery) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('AI Behavior Hint',
                                style: GoogleFonts.outfit(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(_service.getCurrentPhaseHint(),
                                style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // All phases
                Text('Recovery Arc',
                    style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                ...RecoveryPhase.values.where((p) => p != RecoveryPhase.none).map((p) {
                  final isActive = phase == p;
                  final isPast = phase.index > p.index;
                  final c = _phaseColor(p);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isActive
                          ? c.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? c.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPast || isActive
                              ? c.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Center(
                          child: Text(_phaseEmoji(p),
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(_phaseLabel(p),
                              style: GoogleFonts.outfit(
                                  color: isActive ? c : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(
                            EmotionalRecoveryService
                                    .instance.getCurrentPhaseHint(),
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                      ),
                      if (isPast)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.greenAccent, size: 18),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Active',
                              style: GoogleFonts.outfit(
                                  color: c, fontSize: 10)),
                        ),
                    ]),
                  );
                }),

                const SizedBox(height: 16),

                // Triggers info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recovery Triggers',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 8),
                      ...[
                        '⏰ User returns after 3+ hour gap',
                        '🔇 AI ignored 3+ times in a row',
                        '📉 Trust score drops below 25',
                        '❄️ Conversation becomes cold/short',
                      ].map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(t,
                                style: GoogleFonts.outfit(
                                    color: Colors.white60, fontSize: 12)),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _triggerRecovery,
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Simulate Trigger'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.tealAccent,
                        side: BorderSide(
                            color: Colors.teal.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetting ? null : _reset,
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: Text(_resetting ? 'Resetting...' : 'Reset Arc'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
