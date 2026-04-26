import 'package:flutter/material.dart';
import '../../services/ai_personalization/alter_ego_service.dart';

class AlterEgoPage extends StatefulWidget {
  const AlterEgoPage({super.key});

  @override
  State<AlterEgoPage> createState() => _AlterEgoPageState();
}

class _AlterEgoPageState extends State<AlterEgoPage> {
  final _service = AlterEgoService.instance;
  String _currentPersona = 'default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎭 Alter Ego Personas'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Current Persona'),
                subtitle: Text(_currentPersona.toUpperCase()),
                trailing: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            ...['tsundere', 'yandere', 'kuudere', 'deredere', 'default'].map((persona) => Card(
              child: ListTile(
                title: Text(persona.toUpperCase()),
                trailing: ElevatedButton(
                  onPressed: () {
                    setState(() => _currentPersona = persona);
                  },
                  child: const Text('Switch'),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
