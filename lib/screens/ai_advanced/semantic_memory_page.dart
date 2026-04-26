import 'package:flutter/material.dart';
import '../../services/memory_context/semantic_memory_service.dart';

class SemanticMemoryPage extends StatefulWidget {
  const SemanticMemoryPage({super.key});

  @override
  State<SemanticMemoryPage> createState() => _SemanticMemoryPageState();
}

class _SemanticMemoryPageState extends State<SemanticMemoryPage> {
  final _service = SemanticMemoryService.instance;
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Semantic Memory'),
        backgroundColor: Colors.deepPurple.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search Memories',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _results = [
                  {'topic': 'Conversation', 'content': 'Found memory about ${_controller.text}', 'relevance': 95},
                  {'topic': 'Memory', 'content': 'Related discussion', 'relevance': 80},
                ]);
              },
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            ..._results.map((result) => Card(
              child: ListTile(
                title: Text(result['topic'] ?? 'Memory'),
                subtitle: Text(result['content'] ?? ''),
                trailing: Text('${result['relevance']}%'),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
