import 'package:anime_waifu/services/ai_personalization/ai_content_service.dart';
import 'package:flutter/material.dart';

class AiContentPage extends StatefulWidget {
  const AiContentPage({super.key});

  @override
  State<AiContentPage> createState() => _AiContentPageState();
}

class _AiContentPageState extends State<AiContentPage> {
  String _type = 'affirmations';
  bool _loading = false;
  List<String> _items = [];
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = switch (_type) {
        'fortunes' => await AiContentService.getFortunes(),
        'facts' => await AiContentService.getZeroTwoFacts(),
        'workouts' => (await AiContentService.getWorkouts())
            .map((item) => '${item['name']}: ${item['desc']}')
            .toList(),
        _ => await AiContentService.getAffirmations(),
      };
      if (mounted) setState(() => _items = result.cast<String>());
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = const [];
          _error = 'Could not generate content right now: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await AiContentService.forceRefresh(_type);
    await _generate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Content Generator'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            tooltip: 'Refresh cache',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.deepPurple.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Generates cached daily content using the app AI service and falls back gracefully when unavailable.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Content type'),
            items: const [
              DropdownMenuItem(
                  value: 'affirmations', child: Text('Affirmations')),
              DropdownMenuItem(value: 'fortunes', child: Text('Fortunes')),
              DropdownMenuItem(value: 'facts', child: Text('Zero Two facts')),
              DropdownMenuItem(value: 'workouts', child: Text('Workouts')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _type = value);
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _generate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(_loading ? 'Generating...' : 'Generate'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ..._items.map((item) => Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: Text(item),
                ),
              )),
        ],
      ),
    );
  }
}
