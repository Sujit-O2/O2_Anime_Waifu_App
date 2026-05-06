import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class SleepTrackingPage extends StatefulWidget {
  const SleepTrackingPage({super.key});

  @override
  State<SleepTrackingPage> createState() => _SleepTrackingPageState();
}

class _SleepTrackingPageState extends State<SleepTrackingPage> {
  List<SleepRecord> _sleepRecords = [];
  bool _isTracking = false;
  DateTime? _sleepStartTime;
  double _sleepScore = 0.0;
  int _deepSleepMinutes = 0;
  int _remSleepMinutes = 0;
  int _lightSleepMinutes = 0;
  int _awakeMinutes = 0;
  String _sleepQuality = 'Unknown';

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('sleep_tracking'));
    _loadSleepData();
  }

  Future<void> _loadSleepData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sleep_records');
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        if (!mounted) return;
        setState(() => _sleepRecords = list
            .map((e) => SleepRecord.fromJson(e as Map<String, dynamic>))
            .toList());
      } catch (_) {}
    }
  }

  Future<void> _saveSleepData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'sleep_records', jsonEncode(_sleepRecords.map((r) => r.toJson()).toList()));
  }

  void _startSleepTracking() {
    setState(() {
      _isTracking = true;
      _sleepStartTime = DateTime.now();
      _deepSleepMinutes = 0;
      _remSleepMinutes = 0;
      _lightSleepMinutes = 0;
      _awakeMinutes = 0;
    });
    HapticFeedback.selectionClick();
  }

  void _stopSleepTracking() {
    if (_sleepStartTime == null) return;
    
    final sleepEndTime = DateTime.now();
    final duration = sleepEndTime.difference(_sleepStartTime!);
    final totalMinutes = duration.inMinutes;
    
    // Simulate sleep stages (in real app, this would come from device sensors)
    _deepSleepMinutes = (totalMinutes * 0.2).round(); // 20% deep sleep
    _remSleepMinutes = (totalMinutes * 0.25).round(); // 25% REM sleep
    _lightSleepMinutes = (totalMinutes * 0.45).round(); // 45% light sleep
    _awakeMinutes = totalMinutes - _deepSleepMinutes - _remSleepMinutes - _lightSleepMinutes;
    
    // Calculate sleep score (0-100)
    _sleepScore = (_deepSleepMinutes * 0.3 + _remSleepMinutes * 0.3 + _lightSleepMinutes * 0.2) / totalMinutes * 100;
    _sleepScore = _sleepScore.clamp(0, 100);
    
    // Determine sleep quality
    if (_sleepScore >= 85) _sleepQuality = 'Excellent';
    else if (_sleepScore >= 70) _sleepQuality = 'Good';
    else if (_sleepScore >= 50) _sleepQuality = 'Fair';
    else _sleepQuality = 'Poor';
    
    final record = SleepRecord(
      id: 's_${DateTime.now().millisecondsSinceEpoch}',
      startTime: _sleepStartTime!,
      endTime: sleepEndTime,
      durationHours: duration.inHours.toDouble(),
      deepSleepMinutes: _deepSleepMinutes,
      remSleepMinutes: _remSleepMinutes,
      lightSleepMinutes: _lightSleepMinutes,
      awakeMinutes: _awakeMinutes,
      sleepScore: _sleepScore,
      sleepQuality: _sleepQuality,
    );
    
    setState(() {
      _isTracking = false;
      _sleepRecords.insert(0, record);
      _saveSleepData();
    });
    
    HapticFeedback.selectionClick();
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  String _formatTimeOfDay(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sleep Tracking',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(children: [
          GlassCard(
            margin: EdgeInsets.zero,
            glow: _isTracking,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('😴 SLEEP ANALYSIS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                ),
                const SizedBox(height: 12),
                Text('Sleep Tracker',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                    ),
                ),
                const SizedBox(height: 8),
                Text('Monitor your sleep patterns and get personalized insights for better rest.',
                    style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                    ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _isTracking
                    ? ElevatedButton.icon(
                        onPressed: _stopSleepTracking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.stop_circle, color: Colors.white),
                        label: Text('Stop Tracking',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _startSleepTracking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.bedtime, color: Colors.white),
                        label: Text('Start Tracking',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isTracking) ...[
            const WaifuCommentary(mood: 'relaxed'),
            const SizedBox(height: 12),
            GlassCard(
              margin: EdgeInsets.zero,
              child: Text(
                'Tracking sleep... ${_formatTimeOfDay(_sleepStartTime!)}',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ] else if (_sleepRecords.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  const Text('LAST NIGHT\'S SLEEP',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSleepMetric(
                        'Score',
                        _sleepScore.toStringAsFixed(0),
                        Icons.star_rounded,
                        _sleepScore >= 80 ? Colors.greenAccent : _sleepScore >= 60 ? Colors.amberAccent : Colors.redAccent,
                      ),
                      _buildSleepMetric(
                        'Deep',
                        _formatDuration(_deepSleepMinutes),
                        Icons.nights_stay,
                        Colors.blueAccent,
                      ),
                      _buildSleepMetric(
                        'REM',
                        _formatDuration(_remSleepMinutes),
                        Icons.sentiment_satisfied_alt,
                        Colors.purpleAccent,
                      ),
                      _buildSleepMetric(
                        'Light',
                        _formatDuration(_lightSleepMinutes),
                        Icons.wb_sunny_outlined,
                        Colors.orangeAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Quality: $_sleepQuality',
                      style: GoogleFonts.outfit(
                          color: _sleepScore >= 70 ? Colors.greenAccent : _sleepScore >= 50 ? Colors.amberAccent : Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                      ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            GlassCard(
              margin: EdgeInsets.zero,
              child: Text(
                'No sleep data yet. Start tracking to see your sleep patterns.',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_sleepRecords.isNotEmpty) ...[
            const Text('SLEEP HISTORY',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _sleepRecords.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final record = _sleepRecords[index];
                  return Card(
                    color: Colors.white.withValues(alpha: 0.03),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.bedtime, color: Colors.pinkAccent),
                      title: Text('${_formatTimeOfDay(record.startTime)} - ${_formatTimeOfDay(record.endTime)}',
                          style: GoogleFonts.outfit(color: Colors.white)),
                      subtitle: Text('Score: ${record.sleepScore.toStringAsFixed(0)} | ${record.sleepQuality}',
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                    ),
                  );
                },
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildSleepMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
            ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 10,
            ),
        ),
      ],
    );
  }
}

class SleepRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;
  final int deepSleepMinutes;
  final int remSleepMinutes;
  final int lightSleepMinutes;
  final int awakeMinutes;
  final double sleepScore;
  final String sleepQuality;

  SleepRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.deepSleepMinutes,
    required this.remSleepMinutes,
    required this.lightSleepMinutes,
    required this.awakeMinutes,
    required this.sleepScore,
    required this.sleepQuality,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationHours': durationHours,
        'deepSleepMinutes': deepSleepMinutes,
        'remSleepMinutes': remSleepMinutes,
        'lightSleepMinutes': lightSleepMinutes,
        'awakeMinutes': awakeMinutes,
        'sleepScore': sleepScore,
        'sleepQuality': sleepQuality,
      };

  factory SleepRecord.fromJson(Map<String, dynamic> json) => SleepRecord(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        durationHours: json['durationHours'] as double,
        deepSleepMinutes: json['deepSleepMinutes'] as int,
        remSleepMinutes: json['remSleepMinutes'] as int,
        lightSleepMinutes: json['lightSleepMinutes'] as int,
        awakeMinutes: json['awakeMinutes'] as int,
        sleepScore: json['sleepScore'] as double,
        sleepQuality: json['sleepQuality'] as String,
      );
}