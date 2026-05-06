import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:math' as math;
import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/database_storage/app_db.dart';

class StressDetectionPage extends StatefulWidget {
  const StressDetectionPage({super.key});

  @override
  State<StressDetectionPage> createState() => _StressDetectionPageState();
}

class _StressDetectionPageState extends State<StressDetectionPage> {
  List<StressRecord> _stressRecords = [];
  bool _isMonitoring = false;
  double _currentStressLevel = 0.0;
  String _stressCategory = 'Calm';
  String _recommendation = 'Take a deep breath and relax';
  int _voiceSamples = 0;
  int _typingSamples = 0;

  @override
  void initState() {
    super.initState();
    unawaited(AppDB.instance.recordUsage('stress_detection'));
    _loadStressData();
  }

  Future<void> _loadStressData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('stress_records');
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        if (!mounted) return;
        setState(() => _stressRecords = list
            .map((e) => StressRecord.fromJson(e as Map<String, dynamic>))
            .toList());
      } catch (_) {}
    }
  }

  Future<void> _saveStressData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'stress_records', jsonEncode(_stressRecords.map((r) => r.toJson()).toList()));
  }

  void _startStressMonitoring() {
    setState(() {
      _isMonitoring = true;
      _currentStressLevel = 0.0;
      _stressCategory = 'Analyzing...';
      _recommendation = 'Monitoring stress levels...';
    });
    HapticFeedback.selectionClick();
    
    // Simulate stress monitoring
    _simulateStressMonitoring();
  }

  void _stopStressMonitoring() {
    setState(() {
      _isMonitoring = false;
    });
    HapticFeedback.selectionClick();
    
    // Save the stress reading
    if (_currentStressLevel > 0) {
      final record = StressRecord(
        id: 'str_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        stressLevel: _currentStressLevel,
        category: _stressCategory,
        recommendation: _recommendation,
        voiceSamples: _voiceSamples,
        typingSamples: _typingSamples,
      );
      
      setState(() {
        _stressRecords.insert(0, record);
        _saveStressData();
      });
    }
  }

  void _simulateStressMonitoring() {
    // Simulate stress detection based on voice and typing patterns
    // In a real app, this would use actual device sensors and ML models
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !_isMonitoring) return;
      
      // Simulate stress level (0-100)
      final stressLevel = 20 + (math.Random().nextDouble() * 60);
      
      setState(() {
        _currentStressLevel = stressLevel;
        _voiceSamples = (math.Random().nextInt(10) + 5);
        _typingSamples = (math.Random().nextInt(20) + 10);
        
        // Categorize stress level
        if (stressLevel < 25) {
          _stressCategory = 'Calm';
          _recommendation = 'You\'re doing great! Keep up the relaxed state.';
        } else if (stressLevel < 45) {
          _stressCategory = 'Low Stress';
          _recommendation = 'Take a short break and practice deep breathing.';
        } else if (stressLevel < 65) {
          _stressCategory = 'Moderate Stress';
          _recommendation = 'Try a 5-minute meditation or go for a short walk.';
        } else if (stressLevel < 85) {
          _stressCategory = 'High Stress';
          _recommendation = 'Practice relaxation techniques and consider taking a break.';
        } else {
          _stressCategory = 'Very High Stress';
          _recommendation = 'It\'s important to rest. Try guided meditation or talk to someone.';
        }
      });
      
      // Continue monitoring if still active
      if (_isMonitoring) {
        _simulateStressMonitoring();
      }
    });
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
        title: Text('Stress Detection',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(children: [
          GlassCard(
            margin: EdgeInsets.zero,
            glow: _isMonitoring,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('😰 STRESS ANALYSIS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                ),
                const SizedBox(height: 12),
                Text('Stress Monitor',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                    ),
                ),
                const SizedBox(height: 8),
                Text('Detect stress levels through voice and typing patterns, and get personalized coping strategies.',
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
                child: _isMonitoring
                    ? ElevatedButton.icon(
                        onPressed: _stopStressMonitoring,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.stop_circle, color: Colors.white),
                        label: Text('Stop Monitoring',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _startStressMonitoring,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.psychology, color: Colors.white),
                        label: Text('Start Monitoring',
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
          if (_isMonitoring) ...[
            const WaifuCommentary(mood: 'focused'),
            const SizedBox(height: 12),
            GlassCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  Text('Analyzing...',
                      style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: _currentStressLevel / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _currentStressLevel < 45
                                ? Colors.greenAccent
                                : _currentStressLevel < 65
                                    ? Colors.amberAccent
                                    : _currentStressLevel < 85
                                        ? Colors.orangeAccent
                                        : Colors.redAccent,
                          ),
                        ),
                        Center(
                          child: Text(
                            _currentStressLevel.toStringAsFixed(0),
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Voice samples: $_voiceSamples | Typing samples: $_typingSamples',
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ] else if (_stressRecords.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  const Text('LATEST READING',
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
                      _buildStressMetric(
                        'Level',
                        _currentStressLevel.toStringAsFixed(0),
                        Icons.psychology,
                        _getStressColor(_currentStressLevel),
                      ),
                      _buildStressMetric(
                        'Category',
                        _stressCategory,
                        Icons.sentiment_satisfied,
                        _getStressColor(_currentStressLevel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Recommendation:',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                      ),
                  ),
                  const SizedBox(height: 4),
                  Text(_recommendation,
                      style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
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
                'No stress data yet. Start monitoring to see your stress patterns.',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_stressRecords.isNotEmpty) ...[
            const Text('STRESS HISTORY',
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
                itemCount: _stressRecords.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final record = _stressRecords[index];
                  return Card(
                    color: Colors.white.withValues(alpha: 0.03),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.psychology, color: _getStressColor(record.stressLevel)),
                      title: Text('${record.stressLevel.toStringAsFixed(0)} - ${record.category}',
                          style: GoogleFonts.outfit(color: Colors.white)),
                      subtitle: Text('${_formatTime(record.timestamp)} | ${record.voiceSamples}v ${record.typingSamples}t',
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

  Widget _buildStressMetric(String label, String value, IconData icon, Color color) {
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

  Color _getStressColor(double stressLevel) {
    if (stressLevel < 25) return Colors.greenAccent;
    if (stressLevel < 45) return Colors.lightGreenAccent;
    if (stressLevel < 65) return Colors.amberAccent;
    if (stressLevel < 85) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class StressRecord {
  final String id;
  final DateTime timestamp;
  final double stressLevel;
  final String category;
  final String recommendation;
  final int voiceSamples;
  final int typingSamples;

  StressRecord({
    required this.id,
    required this.timestamp,
    required this.stressLevel,
    required this.category,
    required this.recommendation,
    required this.voiceSamples,
    required this.typingSamples,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'stressLevel': stressLevel,
        'category': category,
        'recommendation': recommendation,
        'voiceSamples': voiceSamples,
        'typingSamples': typingSamples,
      };

  factory StressRecord.fromJson(Map<String, dynamic> json) => StressRecord(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        stressLevel: json['stressLevel'] as double,
        category: json['category'] as String,
        recommendation: json['recommendation'] as String,
        voiceSamples: json['voiceSamples'] as int,
        typingSamples: json['typingSamples'] as int,
      );
}