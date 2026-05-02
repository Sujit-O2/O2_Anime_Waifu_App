import 'package:anime_waifu/services/memory_context/emotion_memory_timeline_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class EmotionMemoryTimelinePage extends StatefulWidget {
  const EmotionMemoryTimelinePage({super.key});

  @override
  State<EmotionMemoryTimelinePage> createState() =>
      _EmotionMemoryTimelinePageState();
}

class _EmotionMemoryTimelinePageState extends State<EmotionMemoryTimelinePage> {
  final _service = EmotionMemoryTimelineService.instance;
  final _description = TextEditingController();
  final _trigger = TextEditingController();
  EmotionType _emotion = EmotionType.calm;
  double _intensity = 0.5;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _description.dispose();
    _trigger.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _record() async {
    if (_description.text.trim().isEmpty) return;
    await _service.recordEmotionalMoment(
      description: _description.text.trim(),
      emotion: _emotion,
      intensity: _intensity,
      trigger: _trigger.text.trim().isEmpty ? null : _trigger.text.trim(),
    );
    _description.clear();
    _trigger.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final memories = _service.getMemoriesInRange(
      now.subtract(const Duration(days: 30)),
      now.add(const Duration(days: 1)),
    );
    final distribution =
        _service.getEmotionDistribution(period: const Duration(days: 30));
    final anniversaries = _service.getAnniversaries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Timeline'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _EmotionForm(
                  description: _description,
                  trigger: _trigger,
                  emotion: _emotion,
                  intensity: _intensity,
                  onEmotionChanged: (value) => setState(() => _emotion = value),
                  onIntensityChanged: (value) =>
                      setState(() => _intensity = value),
                  onSave: _record,
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.purple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_service.generateTherapeuticInsight()),
                  ),
                ),
                const SizedBox(height: 16),
                Text('30-Day Mood Mix',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (distribution.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('Record a moment to build your timeline.'),
                    ),
                  )
                else
                  ...distribution.entries.map((entry) => Card(
                        child: ListTile(
                          leading: Text(entry.key.emoji,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(entry.key.label),
                          trailing: Text('${entry.value}'),
                        ),
                      )),
                if (anniversaries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Today in Memory',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...anniversaries.map((item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_available_rounded),
                          title: Text(item.message),
                        ),
                      )),
                ],
                const SizedBox(height: 16),
                Text('Recent Moments',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...memories.take(12).map((memory) => Card(
                      child: ListTile(
                        leading: Text(memory.emotion.emoji,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(memory.description),
                        subtitle: Text(
                          'Intensity ${(memory.intensity * 100).round()}%'
                          '${memory.trigger == null ? '' : ' • ${memory.trigger}'}',
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}

class _EmotionForm extends StatelessWidget {
  final TextEditingController description;
  final TextEditingController trigger;
  final EmotionType emotion;
  final double intensity;
  final ValueChanged<EmotionType> onEmotionChanged;
  final ValueChanged<double> onIntensityChanged;
  final VoidCallback onSave;

  const _EmotionForm({
    required this.description,
    required this.trigger,
    required this.emotion,
    required this.intensity,
    required this.onEmotionChanged,
    required this.onIntensityChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: description,
              decoration: const InputDecoration(
                labelText: 'What happened?',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: trigger,
              decoration: const InputDecoration(
                labelText: 'Trigger or context',
                prefixIcon: Icon(Icons.bolt_rounded),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<EmotionType>(
              value: emotion,
              decoration: const InputDecoration(labelText: 'Emotion'),
              items: EmotionType.values
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text('${item.emoji} ${item.label}'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) onEmotionChanged(value);
              },
            ),
            Slider(
              value: intensity,
              label: '${(intensity * 100).round()}%',
              onChanged: onIntensityChanged,
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Record Moment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
