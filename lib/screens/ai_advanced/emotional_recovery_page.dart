import 'package:flutter/material.dart';

class EmotionalRecoveryPage extends StatefulWidget {
  const EmotionalRecoveryPage({super.key});

  @override
  State<EmotionalRecoveryPage> createState() => _EmotionalRecoveryPageState();
}

class _EmotionalRecoveryPageState extends State<EmotionalRecoveryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💚 Emotional Recovery'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                title: Text('Recovery Phase'),
                subtitle: Text('Active Recovery'),
                trailing: Icon(Icons.healing),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Recovery Progress'),
                subtitle: const LinearProgressIndicator(value: 0.6),
                trailing: const Text('60%'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recovery Tips',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...[
                      'Take deep breaths',
                      'Practice mindfulness',
                      'Stay positive'
                    ].map((tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('• $tip'),
                        )),
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
