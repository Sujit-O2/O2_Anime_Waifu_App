import 'package:flutter/material.dart';

class AiCopilotPage extends StatefulWidget {
  const AiCopilotPage({super.key});

  @override
  State<AiCopilotPage> createState() => _AiCopilotPageState();
}

class _AiCopilotPageState extends State<AiCopilotPage> {
  final _controller = TextEditingController();
  String _suggestion = '';
  bool _isActive = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 AI Copilot'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Copilot Status'),
                subtitle: Text(_isActive ? 'Active' : 'Inactive'),
                trailing: Switch(
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Ask Copilot',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _suggestion = 'Suggestion for: ${_controller.text}');
              },
              child: const Text('Get Suggestion'),
            ),
            const SizedBox(height: 16),
            if (_suggestion.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_suggestion),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
