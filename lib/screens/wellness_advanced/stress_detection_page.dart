import 'package:flutter/material.dart';

class StressDetectionPage extends StatefulWidget {
  const StressDetectionPage({super.key});

  @override
  State<StressDetectionPage> createState() => _StressDetectionPageState();
}

class _StressDetectionPageState extends State<StressDetectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Stress Detection'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Stress Level'),
                subtitle: LinearProgressIndicator(
                  value: 0.45,
                  color: Colors.green,
                ),
                trailing: Text('45'),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text('Status'),
                subtitle: Text('Moderate'),
                trailing: Icon(Icons.sentiment_satisfied),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommendations',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• Take breaks'),
                    Text('• Practice breathing'),
                    Text('• Stay hydrated'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
