import 'package:flutter/material.dart';
import 'package:anime_waifu/services/ai_personalization/voice_clone_training_service.dart';

class VoiceCloneTrainingPage extends StatefulWidget {
  const VoiceCloneTrainingPage({super.key});

  @override
  State<VoiceCloneTrainingPage> createState() => _VoiceCloneTrainingPageState();
}

class _VoiceCloneTrainingPageState extends State<VoiceCloneTrainingPage> {
  final _service = VoiceCloneTrainingService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎙️ Voice Clone Training'),
        backgroundColor: Colors.deepPurple.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Training status: Ready to train"),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Instructions: Upload 5-10 voice samples"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
