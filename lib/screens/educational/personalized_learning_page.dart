import 'package:flutter/material.dart';
import 'package:anime_waifu/services/educational/personalized_learning_service.dart';

class PersonalizedLearningPage extends StatefulWidget {
  const PersonalizedLearningPage({super.key});

  @override
  State<PersonalizedLearningPage> createState() => _PersonalizedLearningPageState();
}

class _PersonalizedLearningPageState extends State<PersonalizedLearningPage> {
  final _service = PersonalizedLearningService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎓 Personalized Learning'),
        backgroundColor: Colors.indigo.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Learning path: Beginner to Advanced'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Recommendations: Focus on fundamentals...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
