import 'package:flutter/material.dart';
import '../../services/wellness/sleep_tracking_service.dart';

class SleepTrackingPage extends StatefulWidget {
  const SleepTrackingPage({super.key});

  @override
  State<SleepTrackingPage> createState() => _SleepTrackingPageState();
}

class _SleepTrackingPageState extends State<SleepTrackingPage> {
  final _service = SleepTrackingService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('😴 Sleep Tracking'),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: const ListTile(
                title: Text('Sleep Quality'),
                subtitle: LinearProgressIndicator(value: 0.85),
                trailing: Text('85%'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: const ListTile(
                title: Text('Average Sleep'),
                subtitle: Text('7.5 hours'),
                trailing: Icon(Icons.bedtime),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: const ListTile(
                title: Text('Today'),
                subtitle: Text('7h 30m'),
                trailing: Text('Good'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
