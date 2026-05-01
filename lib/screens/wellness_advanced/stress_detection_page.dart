import 'package:anime_waifu/services/wellness/stress_detection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class StressDetectionPage extends StatefulWidget {
  const StressDetectionPage({super.key});

  @override
  State<StressDetectionPage> createState() => _StressDetectionPageState();
}

class _StressDetectionPageState extends State<StressDetectionPage> {
  final _service = StressDetectionService.instance;
  double _voice = 0.35;
  double _typing = 0.35;
  bool _loading = true;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _record() async {
    HapticFeedback.mediumImpact();
    setState(() => _recording = true);
    await _service.recordStressReading(
      voiceStress: _voice,
      typingStress: _typing,
      context: 'Manual wellness check',
    );
    if (mounted) setState(() => _recording = false);
  }

  Color _stressColor(double stress) {
    if (stress < 0.3) return Colors.greenAccent;
    if (stress < 0.6) return Colors.amberAccent;
    return Colors.redAccent;
  }

  String _stressLabel(double stress) {
    if (stress < 0.3) return 'Low 😌';
    if (stress < 0.6) return 'Moderate 😐';
    return 'High 😰';
  }

  @override
  Widget build(BuildContext context) {
    final latest = _service.latestReading;
    final stress = latest?.combinedStress ?? 0;
    final stressColor = _stressColor(stress);
    final readings = _service.getReadings();

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
        title: Text('🧘 Stress Detection',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current stress gauge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        stressColor.withValues(alpha: 0.15),
                        stressColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stressColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Text('Current Stress Level',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 12)),
                      const Spacer(),
                      Text(_stressLabel(stress),
                          style: GoogleFonts.outfit(
                              color: stressColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ]),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: stress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(stressColor),
                        minHeight: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${(stress * 100).round()}%',
                        style: GoogleFonts.outfit(
                            color: stressColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 28)),
                  ]),
                ),
                const SizedBox(height: 16),

                // Insights
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.insights_rounded,
                            color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 8),
                        Text('Stress Insights',
                            style: GoogleFonts.outfit(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                      const SizedBox(height: 8),
                      Text(_service.getStressInsights(),
                          style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Coping strategies
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.tealAccent.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.self_improvement_rounded,
                            color: Colors.tealAccent, size: 16),
                        const SizedBox(width: 8),
                        Text('Coping Strategies',
                            style: GoogleFonts.outfit(
                                color: Colors.tealAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                      const SizedBox(height: 8),
                      Text(_service.getCopingStrategies(),
                          style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Manual input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manual Stress Check',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Text('Voice Stress: ${(_voice * 100).round()}%',
                            style: GoogleFonts.outfit(
                                color: Colors.white60, fontSize: 12)),
                        const Spacer(),
                        Text(_stressLabel(_voice),
                            style: GoogleFonts.outfit(
                                color: _stressColor(_voice), fontSize: 11)),
                      ]),
                      Slider(
                        value: _voice,
                        onChanged: (v) => setState(() => _voice = v),
                        activeColor: _stressColor(_voice),
                        inactiveColor: Colors.white12,
                      ),
                      Row(children: [
                        Text('Typing Stress: ${(_typing * 100).round()}%',
                            style: GoogleFonts.outfit(
                                color: Colors.white60, fontSize: 12)),
                        const Spacer(),
                        Text(_stressLabel(_typing),
                            style: GoogleFonts.outfit(
                                color: _stressColor(_typing), fontSize: 11)),
                      ]),
                      Slider(
                        value: _typing,
                        onChanged: (v) => setState(() => _typing = v),
                        activeColor: _stressColor(_typing),
                        inactiveColor: Colors.white12,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _recording ? null : _record,
                          icon: _recording
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.monitor_heart_rounded,
                                  size: 18),
                          label: Text(
                              _recording ? 'Recording...' : 'Record Stress Check',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // History
                if (readings.isNotEmpty) ...[
                  Text('Reading History',
                      style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...readings.take(5).map((r) {
                    final c = _stressColor(r.combinedStress);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: Text('${(r.combinedStress * 100).round()}%',
                                style: GoogleFonts.outfit(
                                    color: c,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(r.context,
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 13)),
                            Text(_stressLabel(r.combinedStress),
                                style: GoogleFonts.outfit(
                                    color: c, fontSize: 11)),
                          ]),
                        ),
                      ]),
                    );
                  }),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
