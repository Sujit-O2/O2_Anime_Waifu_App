import 'package:anime_waifu/services/ai_personalization/smart_reply_service.dart';
import 'package:flutter/material.dart';

class SmartReplyPage extends StatefulWidget {
  const SmartReplyPage({super.key});

  @override
  State<SmartReplyPage> createState() => _SmartReplyPageState();
}

class _SmartReplyPageState extends State<SmartReplyPage> {
  final _service = SmartReplyService.instance;
  final _message = TextEditingController();
  final _context = TextEditingController();
  List<SmartReplySuggestion> _suggestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    _context.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _generate() async {
    if (_message.text.trim().isEmpty) return;
    final context = _context.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final suggestions = await _service.generateReplies(
      lastMessage: _message.text.trim(),
      conversationContext: context,
    );
    if (mounted) setState(() => _suggestions = suggestions);
  }

  Future<void> _select(SmartReplySuggestion suggestion) async {
    await _service.recordUsage(suggestion.text, _message.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Learned: ${suggestion.text}')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Reply'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.orange.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Replies are ranked by context, sentiment, time, and your selected style.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _message,
                  decoration: const InputDecoration(
                    labelText: 'Latest message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _context,
                  decoration: const InputDecoration(
                    labelText: 'Earlier context, one line each',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generate Replies'),
                ),
                const SizedBox(height: 16),
                ..._suggestions.map((suggestion) => Card(
                      child: ListTile(
                        title: Text(suggestion.text),
                        subtitle: Text(
                          '${suggestion.type.name} • ${(suggestion.confidence * 100).round()}%',
                        ),
                        trailing: IconButton(
                          tooltip: 'Use and learn',
                          icon: const Icon(Icons.check_rounded),
                          onPressed: () => _select(suggestion),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
