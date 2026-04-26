import 'package:flutter/material.dart';

class VoiceEmotionPage extends StatefulWidget {
  const VoiceEmotionPage({super.key});

  @override
  State<VoiceEmotionPage> createState() => _VoiceEmotionPageState();
}

class _VoiceEmotionPageState extends State<VoiceEmotionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Voice Emotion'),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                title: Text('Detection Accuracy'),
                subtitle: Text('95%'),
                trailing: Icon(Icons.mic),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                title: Text('Current Emotion'),
                subtitle: Text('Happy'),
                trailing: Icon(Icons.sentiment_satisfied),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Voice Metrics',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Pitch: 220.0 Hz'),
                    Text('Tempo: 120.0 BPM'),
                    Text('Volume: 65.0 dB'),
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
