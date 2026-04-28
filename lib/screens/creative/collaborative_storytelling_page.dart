import 'package:flutter/material.dart';
import 'package:anime_waifu/services/creative/collaborative_storytelling_service.dart';

class CollaborativeStorytellingPage extends StatefulWidget {
  const CollaborativeStorytellingPage({super.key});

  @override
  State<CollaborativeStorytellingPage> createState() => _CollaborativeStorytellingPageState();
}

class _CollaborativeStorytellingPageState extends State<CollaborativeStorytellingPage> {
  final _service = CollaborativeStorytellingService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 Collaborative Storytelling'),
        backgroundColor: Colors.deepPurple.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.deepPurple.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Current story in progress...'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Story prompt: Create an engaging narrative...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
