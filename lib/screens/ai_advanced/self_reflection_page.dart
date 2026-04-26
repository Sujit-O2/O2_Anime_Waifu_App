import 'package:flutter/material.dart';

class SelfReflectionPage extends StatefulWidget {
  const SelfReflectionPage({super.key});

  @override
  State<SelfReflectionPage> createState() => _SelfReflectionPageState();
}

class _SelfReflectionPageState extends State<SelfReflectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🪞 Self Reflection'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Observations',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 8),
                    Text(
                        'You tend to chat more in the evenings. Your conversations are thoughtful and engaging.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
                5,
                (i) => Card(
                      child: ListTile(
                        title: Text('Reflection ${i + 1}'),
                        subtitle: const Text('Insightful observation'),
                        trailing: const Text('Today'),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}
