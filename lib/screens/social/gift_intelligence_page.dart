import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anime_waifu/services/social/gift_intelligence_service.dart';

class GiftIntelligencePage extends StatefulWidget {
  const GiftIntelligencePage({super.key});

  @override
  State<GiftIntelligencePage> createState() => _GiftIntelligencePageState();
}

class _GiftIntelligencePageState extends State<GiftIntelligencePage> {
  final _service = GiftIntelligenceService.instance;
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _occasionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _interestsController = TextEditingController();
  GiftIdea? _lastIdea;

  @override
  void initState() {
    super.initState();
    unawaited(_service.initialize());
  }

  @override
  void dispose() {
    _personController.dispose();
    _occasionController.dispose();
    _budgetController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _generateIdea() async {
    if (!_formKey.currentState!.validate()) return;

    final interests = _interestsController.text.split(',').map((e) => e.trim()).toList();
    final budget = double.tryParse(_budgetController.text) ?? 50;

    final idea = await _service.generateGiftIdea(
      forPerson: _personController.text,
      occasion: _occasionController.text,
      budget: budget,
      interests: interests,
    );

    setState(() => _lastIdea = idea);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎁 Gift Intelligence'),
        backgroundColor: Colors.pink.shade700,
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
                    children: [
                      TextFormField(
                        controller: _personController,
                        decoration: const InputDecoration(
                          labelText: 'For Person',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _occasionController,
                        decoration: const InputDecoration(
                          labelText: 'Occasion',
                          prefixIcon: Icon(Icons.celebration),
                          hintText: 'Birthday, Anniversary, etc.',
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(
                          labelText: 'Budget (\$)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _interestsController,
                        decoration: const InputDecoration(
                          labelText: 'Interests (comma-separated)',
                          prefixIcon: Icon(Icons.favorite),
                          hintText: 'music, books, gaming',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _generateIdea,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate Gift Ideas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_lastIdea != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.pink.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎁 Gift Ideas for ${_lastIdea!.forPerson}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Occasion: ${_lastIdea!.occasion}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Budget: \$${_lastIdea!.budget.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Divider(height: 24),
                        ..._lastIdea!.suggestedGifts.take(10).map((gift) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 18)),
                              Expanded(child: Text(gift)),
                            ],
                          ),
                        )),
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
}
