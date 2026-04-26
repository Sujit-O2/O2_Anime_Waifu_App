import 'package:flutter/material.dart';

class SleepTrackingPage extends StatefulWidget {
  const SleepTrackingPage({super.key});

  @override
  State<SleepTrackingPage> createState() => _SleepTrackingPageState();
}

class _SleepTrackingPageState extends State<SleepTrackingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('😴 Sleep Tracking'),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Sleep Quality'),
                subtitle: LinearProgressIndicator(value: 0.85),
                trailing: Text('85%'),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text('Average Sleep'),
                subtitle: Text('7.5 hours'),
                trailing: Icon(Icons.bedtime),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
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
