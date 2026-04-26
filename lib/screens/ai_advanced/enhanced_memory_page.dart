import 'package:flutter/material.dart';

class EnhancedMemoryPage extends StatefulWidget {
  const EnhancedMemoryPage({super.key});

  @override
  State<EnhancedMemoryPage> createState() => _EnhancedMemoryPageState();
}

class _EnhancedMemoryPageState extends State<EnhancedMemoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Enhanced Memory'),
        backgroundColor: Colors.cyan.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                title: Text('Memory Capacity'),
                subtitle: Text('150 / 1000'),
                trailing: Icon(Icons.storage),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                title: Text('Consolidation Status'),
                subtitle: Text('Idle'),
                trailing: Icon(Icons.check_circle),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
                5,
                (i) => Card(
                      child: ListTile(
                        title: Text('Memory ${i + 1}'),
                        subtitle: const Text('Important conversation'),
                        trailing: Text('${90 - i * 5}'),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}
