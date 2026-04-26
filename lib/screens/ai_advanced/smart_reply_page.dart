import 'package:flutter/material.dart';
import '../../services/ai_personalization/smart_reply_service.dart';

class SmartReplyPage extends StatefulWidget {
  const SmartReplyPage({super.key});

  @override
  State<SmartReplyPage> createState() => _SmartReplyPageState();
}

class _SmartReplyPageState extends State<SmartReplyPage> {
  final _service = SmartReplyService.instance;
  final _controller = TextEditingController();
  List<String> _suggestions = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Smart Reply'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                title: Text('Prediction Accuracy'),
                subtitle: Text('85%'),
                trailing: Icon(Icons.analytics),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Message Context',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _suggestions = [
                  'That sounds great!',
                  'I agree with you',
                  'Tell me more',
                ]);
              },
              child: const Text('Get Suggestions'),
            ),
            const SizedBox(height: 16),
            ..._suggestions.map((suggestion) => Card(
              child: ListTile(
                title: Text(suggestion),
                trailing: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
