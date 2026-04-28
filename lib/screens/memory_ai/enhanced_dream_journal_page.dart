import 'package:flutter/material.dart';
import 'package:anime_waifu/services/ai_personalization/enhanced_dream_journal_service.dart';

class EnhancedDreamJournalPage extends StatefulWidget {
  const EnhancedDreamJournalPage({super.key});

  @override
  State<EnhancedDreamJournalPage> createState() => _EnhancedDreamJournalPageState();
}

class _EnhancedDreamJournalPageState extends State<EnhancedDreamJournalPage> {
  final _service = EnhancedDreamJournalService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌙 Dream Journal'),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Dream analysis: Patterns detected'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Dream patterns: Recurring themes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
