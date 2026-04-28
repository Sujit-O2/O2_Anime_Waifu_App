import 'package:flutter/material.dart';
import 'package:anime_waifu/services/educational/debate_critical_thinking_service.dart';

class DebateCriticalThinkingPage extends StatefulWidget {
  const DebateCriticalThinkingPage({super.key});

  @override
  State<DebateCriticalThinkingPage> createState() => _DebateCriticalThinkingPageState();
}

class _DebateCriticalThinkingPageState extends State<DebateCriticalThinkingPage> {
  final _service = DebateCriticalThinkingService.instance;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Debate & Critical Thinking'),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.red.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Debate topic: Technology and society'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Argumentation tips: Use evidence and logic...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
