import 'package:anime_waifu/services/ai_personalization/voice_clone_training_service.dart';
import 'package:flutter/material.dart';

class VoiceCloneTrainingPage extends StatefulWidget {
  const VoiceCloneTrainingPage({super.key});

  @override
  State<VoiceCloneTrainingPage> createState() => _VoiceCloneTrainingPageState();
}

class _VoiceCloneTrainingPageState extends State<VoiceCloneTrainingPage> {
  final _service = VoiceCloneTrainingService.instance;
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _samplePath = TextEditingController();
  final _transcript = TextEditingController();
  double _sampleDuration = 8;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _samplePath.dispose();
    _transcript.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createProfile() async {
    if (_name.text.trim().isEmpty) return;
    await _service.createProfile(
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty
          ? 'Custom companion voice'
          : _description.text.trim(),
    );
    _name.clear();
    _description.clear();
    if (mounted) setState(() {});
  }

  Future<void> _addSample(String profileId) async {
    if (_samplePath.text.trim().isEmpty) return;
    await _service.addSample(
      profileId: profileId,
      audioPath: _samplePath.text.trim(),
      durationSeconds: _sampleDuration.round(),
      transcript:
          _transcript.text.trim().isEmpty ? null : _transcript.text.trim(),
    );
    _samplePath.clear();
    _transcript.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _service.getAllProfiles();
    final requirements = _service.getTrainingRequirements();
    final active = _service.getActiveProfile();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Training'),
        backgroundColor: Colors.deepPurple.shade700,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Need ${requirements['min_samples']}-${requirements['max_samples']} samples, '
                      '${requirements['min_duration_seconds']}-${requirements['max_duration_seconds']} seconds each. '
                      'Recommended: ${requirements['recommended_samples']} clean clips.',
                    ),
                  ),
                ),
                if (active != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.record_voice_over_rounded),
                      title: Text('Active: ${active.name}'),
                      subtitle: Text(active.status.name),
                    ),
                  ),
                const SizedBox(height: 12),
                _CreateProfileCard(
                  name: _name,
                  description: _description,
                  onCreate: _createProfile,
                ),
                const SizedBox(height: 16),
                Text('Profiles',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (profiles.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                          'Create a voice profile to start collecting samples.'),
                    ),
                  )
                else
                  ...profiles.map((profile) => _ProfileCard(
                        profile: profile,
                        samplePath: _samplePath,
                        transcript: _transcript,
                        sampleDuration: _sampleDuration,
                        onDurationChanged: (value) =>
                            setState(() => _sampleDuration = value),
                        onAddSample: () => _addSample(profile.id),
                        onActivate: () async {
                          await _service.setActiveProfile(profile.id);
                          if (mounted) setState(() {});
                        },
                        onTrain: () async {
                          await _service.startTraining(profile.id, 'local');
                          if (mounted) setState(() {});
                        },
                        onDelete: () async {
                          await _service.deleteProfile(profile.id);
                          if (mounted) setState(() {});
                        },
                      )),
              ],
            ),
    );
  }
}

class _CreateProfileCard extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController description;
  final VoidCallback onCreate;

  const _CreateProfileCard({
    required this.name,
    required this.description,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Profile name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Voice style goal'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final VoiceProfile profile;
  final TextEditingController samplePath;
  final TextEditingController transcript;
  final double sampleDuration;
  final ValueChanged<double> onDurationChanged;
  final VoidCallback onAddSample;
  final VoidCallback onActivate;
  final VoidCallback onTrain;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.samplePath,
    required this.transcript,
    required this.sampleDuration,
    required this.onDurationChanged,
    required this.onAddSample,
    required this.onActivate,
    required this.onTrain,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = profile.samples.length / 8;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(profile.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Use profile',
                  onPressed: onActivate,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                ),
                IconButton(
                  tooltip: 'Delete profile',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            Text(profile.description),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
            const SizedBox(height: 6),
            Text('${profile.samples.length} samples • ${profile.status.name}'),
            const SizedBox(height: 12),
            TextField(
              controller: samplePath,
              decoration: const InputDecoration(
                labelText: 'Audio file path',
                prefixIcon: Icon(Icons.audio_file_rounded),
              ),
            ),
            TextField(
              controller: transcript,
              decoration: const InputDecoration(labelText: 'Transcript'),
            ),
            Slider(
              value: sampleDuration,
              min: 3,
              max: 30,
              divisions: 27,
              label: '${sampleDuration.round()}s',
              onChanged: onDurationChanged,
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddSample,
                icon: const Icon(Icons.library_add_rounded),
                label: const Text('Add Sample'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: profile.samples.length >= 5 ? onTrain : null,
                icon: const Icon(Icons.model_training_rounded),
                label: const Text('Run Training Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
