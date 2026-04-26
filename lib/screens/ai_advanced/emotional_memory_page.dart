import 'package:flutter/material.dart';
import '../../services/ai_personalization/emotional_memory_service.dart';

class EmotionalMemoryPage extends StatefulWidget {
  const EmotionalMemoryPage({super.key});

  @override
  State<EmotionalMemoryPage> createState() => _EmotionalMemoryPageState();
}

class _EmotionalMemoryPageState extends State<EmotionalMemoryPage> {
  final _service = EmotionalMemoryService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Emotional Memory'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                title: Text('Total Memories'),
                subtitle: Text('15 emotional events'),
                trailing: Icon(Icons.memory),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (i) => Card(
              child: ListTile(
                title: Text('Memory ${i + 1}'),
                subtitle: const Text('Emotional moment recorded'),
                trailing: const Text('Today'),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
