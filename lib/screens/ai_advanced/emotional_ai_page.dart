import 'package:flutter/material.dart';

class EmotionalAiPage extends StatefulWidget {
  const EmotionalAiPage({super.key});

  @override
  State<EmotionalAiPage> createState() => _EmotionalAiPageState();
}

class _EmotionalAiPageState extends State<EmotionalAiPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💖 Emotional AI'),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                title: Text('Current Emotion'),
                subtitle: Text('Happy'),
                trailing: Icon(Icons.favorite),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Emotional Intelligence'),
                subtitle: const LinearProgressIndicator(value: 0.75),
                trailing: const Text('75%'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Emotions', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Happy', 'Excited', 'Calm', 'Loving'].map((e) => Chip(label: Text(e))).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
