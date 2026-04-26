import 'package:flutter/material.dart';
import 'package:anime_waifu/services/memory_context/conversation_bookmarks_service.dart';

class ConversationBookmarksPage extends StatefulWidget {
  const ConversationBookmarksPage({super.key});

  @override
  State<ConversationBookmarksPage> createState() => _ConversationBookmarksPageState();
}

class _ConversationBookmarksPageState extends State<ConversationBookmarksPage> {
  final _service = ConversationBookmarksService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⭐ Conversation Bookmarks'),
        backgroundColor: Colors.amber.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bookmarked conversations list'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bookmark summary: 5 important moments'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
