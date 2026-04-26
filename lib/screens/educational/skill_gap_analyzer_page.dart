import 'package:flutter/material.dart';
import 'package:anime_waifu/services/educational/skill_gap_analyzer_service.dart';

class SkillGapAnalyzerPage extends StatefulWidget {
  const SkillGapAnalyzerPage({super.key});

  @override
  State<SkillGapAnalyzerPage> createState() => _SkillGapAnalyzerPageState();
}

class _SkillGapAnalyzerPageState extends State<SkillGapAnalyzerPage> {
  final _service = SkillGapAnalyzerService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Skill Gap Analyzer'),
        backgroundColor: Colors.teal.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Skill analysis: Strengths and areas for growth"),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Improvement plan: Practice daily..."),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
