import 'package:anime_waifu/services/ai_personalization/self_reflection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SelfReflectionPage extends StatefulWidget {
  const SelfReflectionPage({super.key});

  @override
  State<SelfReflectionPage> createState() => _SelfReflectionPageState();
}

class _SelfReflectionPageState extends State<SelfReflectionPage> {
  final _service = SelfReflectionService.instance;
  bool _loading = true;
  List<String> _observations = [];
  String _behaviourBlock = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _service.loadModel();
    final obs = <String>[];
    // Pop up to 5 observations
    for (int i = 0; i < 5; i++) {
      final o = await _service.popNextObservation();
      if (o == null) break;
      obs.add(o);
    }
    final block = _service.getBehaviourContextBlock();
    if (mounted) {
      setState(() {
        _observations = obs;
        _behaviourBlock = block;
        _loading = false;
      });
    }
  }

  Future<void> _simulateSession() async {
    HapticFeedback.mediumImpact();
    await _service.recordSession(
      messageCount: 12,
      topEmotion: 'happy',
      totalCharsTyped: 450,
      sessionStart: DateTime.now(),
    );
    await _service.recordTopicMentioned('anime');
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session recorded — check for new observations'),
          backgroundColor: Colors.blueGrey,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        title: Text('🪞 Self Reflection',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Intro card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.withValues(alpha: 0.2),
                        Colors.blueGrey.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.blueGrey.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🪞', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AI Observations',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                  'Zero Two notices patterns in how you interact. These are her real observations about you.',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      height: 1.4)),
                            ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Observations
                if (_observations.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(children: [
                      const Text('💭', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No observations yet',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                          'Keep chatting and Zero Two will start noticing things about you.',
                          style: GoogleFonts.outfit(
                              color: Colors.white30, fontSize: 12),
                          textAlign: TextAlign.center),
                    ]),
                  )
                else ...[
                  Text('What I\'ve Noticed',
                      style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ..._observations.asMap().entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.blueGrey.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueGrey.withValues(alpha: 0.2),
                            ),
                            child: Center(
                              child: Text('${entry.key + 1}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.blueGrey.shade200,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(entry.value,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4,
                                    fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),

                // Behaviour context block
                if (_behaviourBlock.isNotEmpty) ...[
                  Text('Behaviour Insights',
                      style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      _behaviourBlock
                          .replaceAll('// [USER BEHAVIOUR INSIGHTS', '')
                          .replaceAll(']:', '')
                          .trim(),
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Simulate button
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
                      Text('Record a Session',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                          'Observations are generated automatically as you chat. Tap below to simulate a session for testing.',
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _simulateSession,
                          icon: const Icon(Icons.psychology_rounded, size: 16),
                          label: const Text('Simulate Session'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueGrey.shade300,
                            side: BorderSide(
                                color: Colors.blueGrey.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
