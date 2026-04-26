import 'package:flutter/material.dart';

class AiContentPage extends StatefulWidget {
  const AiContentPage({super.key});

  @override
  State<AiContentPage> createState() => _AiContentPageState();
}

class _AiContentPageState extends State<AiContentPage> {
  final _controller = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI Content Generator'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('AI Content Generation Service\n\nGenerate creative content using AI.'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Content Prompt',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _result = 'Generated content for: ${_controller.text}');
              },
              child: const Text('Generate'),
            ),
            const SizedBox(height: 16),
            if (_result.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_result),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
