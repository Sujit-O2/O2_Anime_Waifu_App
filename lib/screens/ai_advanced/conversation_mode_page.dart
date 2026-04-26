import 'package:flutter/material.dart';

class ConversationModePage extends StatefulWidget {
  const ConversationModePage({super.key});

  @override
  State<ConversationModePage> createState() => _ConversationModePageState();
}

class _ConversationModePageState extends State<ConversationModePage> {
  String _currentMode = 'romantic';

  final Map<String, String> _modeDescriptions = {
    'romantic': 'Sweet and affectionate conversation style',
    'professional': 'Formal and business-like tone',
    'playful': 'Fun and teasing interactions',
    'therapist': 'Supportive and understanding approach',
    'mentor': 'Guiding and educational style',
    'friend': 'Casual and friendly conversations',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Conversation Modes'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Current Mode'),
                subtitle: Text(_currentMode.toUpperCase()),
                trailing: const Icon(Icons.chat),
              ),
            ),
            const SizedBox(height: 16),
            ..._modeDescriptions.entries.map((entry) => Card(
              child: ListTile(
                title: Text(entry.key.toUpperCase()),
                subtitle: Text(entry.value),
                trailing: ElevatedButton(
                  onPressed: () {
                    setState(() => _currentMode = entry.key);
                  },
                  child: const Text('Select'),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
