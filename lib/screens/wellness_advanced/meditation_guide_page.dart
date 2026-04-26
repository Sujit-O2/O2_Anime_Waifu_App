import 'package:flutter/material.dart';
import '../../services/wellness/meditation_guide_service.dart';

class MeditationGuidePage extends StatefulWidget {
  const MeditationGuidePage({super.key});

  @override
  State<MeditationGuidePage> createState() => _MeditationGuidePageState();
}

class _MeditationGuidePageState extends State<MeditationGuidePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧘 Guided Meditation'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: const ListTile(
                title: Text('Current Session'),
                subtitle: Text('No active session'),
                trailing: Icon(Icons.self_improvement),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Morning Meditation'),
                subtitle: const Text('10 min'),
                trailing: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Start'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
