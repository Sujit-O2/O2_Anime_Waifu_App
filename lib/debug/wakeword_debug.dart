import 'package:anime_waifu/load_wakeword_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Simple developer debug page for wake-word state and manual triggers.
class WakewordDebugPage extends StatelessWidget {
  const WakewordDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = ModalRoute.of(context)?.settings.arguments as WakeWordService?;

    final keywords = svc?.loadedKeywords ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wakeword Debug'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loaded Keywords',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (keywords.isEmpty)
              const Text('No keywords available (service not passed).')
            else
              for (var i = 0; i < keywords.length; i++)
                ListTile(
                  title: Text(keywords[i].split('/').last),
                  trailing: ElevatedButton(
                    onPressed: svc == null
                        ? null
                        : () {
                            try {
                              svc.testTriggerByIndex(i);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Triggered: $i')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Trigger error: $e')),
                              );
                            }
                          },
                    child: const Text('Test'),
                  ),
                ),
            const SizedBox(height: 16),
            const Text(
              'Notes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use the app toolbar debug button to open this page. '
              'Manual triggers call the running WakeWordService callback.',
            ),
            const SizedBox(height: 12),
            if (kDebugMode)
              const Text('Debug mode: ON')
            else
              const Text('Debug mode: OFF'),
          ],
        ),
      ),
    );
  }
}
