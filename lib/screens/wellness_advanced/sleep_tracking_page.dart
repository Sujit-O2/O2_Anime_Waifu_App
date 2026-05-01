import 'package:anime_waifu/services/wellness/sleep_tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SleepTrackingPage extends StatefulWidget {
  const SleepTrackingPage({super.key});

  @override
  State<SleepTrackingPage> createState() => _SleepTrackingPageState();
}

class _SleepTrackingPageState extends State<SleepTrackingPage> {
  final _service = SleepTrackingService.instance;
  double _quality = 7;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle() async {
    HapticFeedback.mediumImpact();
    if (_service.isTracking) {
      await _service.stopSleepTracking(sleepQuality: _quality);
    } else {
      await _service.startSleepTracking();
    }
    if (mounted) setState(() {});
  }

  Color _qualityColor(double q) {
    if (q >= 7) return Colors.greenAccent;
    if (q >= 5) return Colors.amberAccent;
    return Colors.redAccent;
  }

  String _qualityLabel(double q) {
    if (q >= 8) return 'Excellent 😴';
    if (q >= 6) return 'Good 🙂';
    if (q >= 4) return 'Fair 😐';
    return 'Poor 😔';
  }

  String _durationLabel(double h) {
    if (h >= 8) return 'Optimal';
    if (h >= 6) return 'Adequate';
    return 'Insufficient';
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _service.getSessions();
    final isTracking = _service.isTracking;
    final trackColor = isTracking ? Colors.indigoAccent : Colors.white38;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🌙 Sleep Tracking',
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
          ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (isTracking ? Colors.indigoAccent : Colors.white12)
                            .withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: trackColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: trackColor.withValues(alpha: 0.15),
                        border: Border.all(color: trackColor.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(isTracking ? '😴' : '🌙',
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(isTracking ? 'Tracking Sleep' : 'Not Tracking',
                            style: GoogleFonts.outfit(
                                color: Colors.white54, fontSize: 12)),
                        Text(
                          isTracking
                              ? 'Sleep session in progress...'
                              : 'Start tracking when you go to bed',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text('${sessions.length} sessions recorded',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 11)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // Stats row
                if (sessions.isNotEmpty) ...[
                  Row(children: [
                    Expanded(child: _statCard(
                      'Avg Duration',
                      '${(sessions.map((s) => s.durationHours).reduce((a, b) => a + b) / sessions.length).toStringAsFixed(1)}h',
                      Icons.access_time_rounded,
                      Colors.indigoAccent,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard(
                      'Avg Quality',
                      '${(sessions.map((s) => s.sleepQuality).reduce((a, b) => a + b) / sessions.length).toStringAsFixed(1)}/10',
                      Icons.star_rounded,
                      Colors.amberAccent,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard(
                      'Sessions',
                      '${sessions.length}',
                      Icons.bedtime_rounded,
                      Colors.purpleAccent,
                    )),
                  ]),
                  const SizedBox(height: 16),
                ],

                // Insights
                _infoCard(
                  Icons.insights_rounded,
                  'Sleep Insights',
                  _service.getSleepInsights(),
                  Colors.indigoAccent,
                ),
                const SizedBox(height: 10),
                _infoCard(
                  Icons.tips_and_updates_rounded,
                  'Recommendation',
                  _service.getSleepRecommendation(),
                  Colors.tealAccent,
                ),
                const SizedBox(height: 16),

                // Quality slider (shown when stopping)
                if (isTracking) ...[
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
                        Row(children: [
                          Text('Sleep Quality: ${_quality.toStringAsFixed(0)}/10',
                              style: GoogleFonts.outfit(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(_qualityLabel(_quality),
                              style: GoogleFonts.outfit(
                                  color: _qualityColor(_quality), fontSize: 12)),
                        ]),
                        Slider(
                          value: _quality,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: _quality.toStringAsFixed(0),
                          activeColor: _qualityColor(_quality),
                          inactiveColor: Colors.white12,
                          onChanged: (v) => setState(() => _quality = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Toggle button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggle,
                    icon: Icon(
                      isTracking ? Icons.stop_rounded : Icons.bedtime_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isTracking ? 'Stop & Save Session' : 'Start Sleep Tracking',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTracking ? Colors.redAccent : Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Session history
                if (sessions.isNotEmpty) ...[
                  Text('Sleep History',
                      style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1)),
                  const SizedBox(height: 10),
                  ...sessions.take(7).map((s) {
                    final qColor = _qualityColor(s.sleepQuality);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: qColor.withValues(alpha: 0.12),
                            border: Border.all(color: qColor.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              s.sleepQuality.toStringAsFixed(0),
                              style: GoogleFonts.outfit(
                                  color: qColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Text('${s.durationHours.toStringAsFixed(1)}h',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: qColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _durationLabel(s.durationHours),
                                  style: GoogleFonts.outfit(
                                      color: qColor, fontSize: 10),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 2),
                            Text(
                              'REM ${s.remPercentage.toStringAsFixed(0)}%  •  Deep ${s.deepSleepPercentage.toStringAsFixed(0)}%',
                              style: GoogleFonts.outfit(
                                  color: Colors.white54, fontSize: 11),
                            ),
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

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        Text(label,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _infoCard(IconData icon, String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.outfit(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text(body,
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 13, height: 1.4)),
      ]),
    );
  }
}
