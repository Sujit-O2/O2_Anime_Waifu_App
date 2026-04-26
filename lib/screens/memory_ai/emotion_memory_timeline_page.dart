import 'package:flutter/material.dart';
import 'package:anime_waifu/services/memory_context/emotion_memory_timeline_service.dart';

class EmotionMemoryTimelinePage extends StatefulWidget {
  const EmotionMemoryTimelinePage({super.key});

  @override
  State<EmotionMemoryTimelinePage> createState() => _EmotionMemoryTimelinePageState();
}

class _EmotionMemoryTimelinePageState extends State<EmotionMemoryTimelinePage> {
  final _service = EmotionMemoryTimelineService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎭 Emotion Timeline'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Emotional timeline data"),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Emotional insights: Positive trend"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
