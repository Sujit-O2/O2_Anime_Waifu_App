import 'package:flutter/material.dart';
import 'package:anime_waifu/services/social/conflict_resolution_service.dart';

class ConflictResolutionPage extends StatefulWidget {
  const ConflictResolutionPage({super.key});

  @override
  State<ConflictResolutionPage> createState() => _ConflictResolutionPageState();
}

class _ConflictResolutionPageState extends State<ConflictResolutionPage> {
  final _service = ConflictResolutionService.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  ConflictType _selectedType = ConflictType.miscommunication;
  int _intensity = 5;
  List<CommunicationStrategy>? _strategies;

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _getStrategies() async {
    if (!_formKey.currentState!.validate()) return;

    final strategies = await _service.getStrategiesForConflict(
      type: _selectedType,
      intensity: _intensity,
      involvedParties: ['You', 'Other'],
    );

    setState(() => _strategies = strategies);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤝 Conflict Resolution'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Describe the Conflict',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ConflictType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Conflict Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: ConflictType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                      const SizedBox(height: 16),
                      Text('Intensity: $_intensity/10'),
                      Slider(
                        value: _intensity.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _intensity.toString(),
                        onChanged: (v) => setState(() => _intensity = v.toInt()),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getStrategies,
                        icon: const Icon(Icons.psychology),
                        label: const Text('Get Resolution Strategies'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_strategies != null) ...[
                const SizedBox(height: 16),
                ..._strategies!.map((strategy) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: Icon(
                      _getStrategyIcon(strategy.category),
                      color: Colors.teal.shade700,
                    ),
                    title: Text(
                      strategy.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(strategy.description),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Effectiveness: ${strategy.effectiveness}/10',
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Steps:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...strategy.steps.map((step) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(step)),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                Card(
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 Quick Tips',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_service.getDeEscalationTechniques()),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStrategyIcon(StrategyCategory category) {
    switch (category) {
      case StrategyCategory.communication:
        return Icons.chat;
      case StrategyCategory.deEscalation:
        return Icons.trending_down;
      case StrategyCategory.empathy:
        return Icons.favorite;
      case StrategyCategory.collaboration:
        return Icons.handshake;
      case StrategyCategory.relationship:
        return Icons.people;
    }
  }
}
