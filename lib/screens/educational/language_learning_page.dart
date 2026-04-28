import 'package:flutter/material.dart';
import 'package:anime_waifu/services/educational/language_learning_service.dart';

class LanguageLearningPage extends StatefulWidget {
  const LanguageLearningPage({super.key});

  @override
  State<LanguageLearningPage> createState() => _LanguageLearningPageState();
}

class _LanguageLearningPageState extends State<LanguageLearningPage> {
  final _service = LanguageLearningService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 Language Learning'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.purple.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Learning progress: 65%'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Daily lesson: Practice vocabulary...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
