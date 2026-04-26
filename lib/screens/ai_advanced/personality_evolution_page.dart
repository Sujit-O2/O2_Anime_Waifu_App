import 'package:flutter/material.dart';

class PersonalityEvolutionPage extends StatefulWidget {
  const PersonalityEvolutionPage({super.key});

  @override
  State<PersonalityEvolutionPage> createState() =>
      _PersonalityEvolutionPageState();
}

class _PersonalityEvolutionPageState extends State<PersonalityEvolutionPage> {
  final Map<String, double> _traits = {
    'Affection': 75.0,
    'Playfulness': 60.0,
    'Trust': 85.0,
    'Curiosity': 70.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧬 Personality Evolution'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                title: Text('Evolution Stage'),
                subtitle: Text('Developing'),
                trailing: Icon(Icons.trending_up),
              ),
            ),
            const SizedBox(height: 16),
            ..._traits.entries.map((trait) => Card(
                  child: ListTile(
                    title: Text(trait.key),
                    subtitle: LinearProgressIndicator(value: trait.value / 100),
                    trailing: Text('${trait.value.toInt()}'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
