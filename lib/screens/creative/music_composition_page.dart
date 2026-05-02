import 'package:anime_waifu/services/creative/music_composition_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class MusicCompositionPage extends StatefulWidget {
  const MusicCompositionPage({super.key});

  @override
  State<MusicCompositionPage> createState() => _MusicCompositionPageState();
}

class _MusicCompositionPageState extends State<MusicCompositionPage> {
  final _service = MusicCompositionService.instance;
  final _title = TextEditingController();
  final _theme = TextEditingController(text: 'connection');
  final _mood = TextEditingController(text: 'dreamy');
  MusicGenre _genre = MusicGenre.pop;
  String _lyrics = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _theme.dispose();
    _mood.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createProject() async {
    if (_title.text.trim().isEmpty) return;
    await _service.createMusicProject(
      title: _title.text.trim(),
      genre: _genre,
      description: 'Created from Music Composition dashboard',
      type: ProjectType.single,
      mood: _mood.text.trim(),
      targetTracks: 1,
    );
    _title.clear();
    if (mounted) setState(() {});
  }

  void _generateLyrics() {
    setState(() {
      _lyrics = _service.generateLyrics(
        theme: _theme.text.trim().isEmpty ? 'connection' : _theme.text.trim(),
        mood: _mood.text.trim().isEmpty ? 'dreamy' : _mood.text.trim(),
        genre: _genre,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = _service.getProjects();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Composition'),
        backgroundColor: Colors.purple.shade800,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.purple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_service.getMusicInsights()),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _title,
                          decoration:
                              const InputDecoration(labelText: 'Project title'),
                        ),
                        TextField(
                          controller: _theme,
                          decoration: const InputDecoration(labelText: 'Theme'),
                        ),
                        TextField(
                          controller: _mood,
                          decoration: const InputDecoration(labelText: 'Mood'),
                        ),
                        DropdownButtonFormField<MusicGenre>(
                          value: _genre,
                          decoration: const InputDecoration(labelText: 'Genre'),
                          items: MusicGenre.values
                              .map((genre) => DropdownMenuItem(
                                    value: genre,
                                    child: Text(genre.label),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _genre = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _createProject,
                                icon: const Icon(Icons.library_music_rounded),
                                label: const Text('Create'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _generateLyrics,
                                icon: const Icon(Icons.lyrics_rounded),
                                label: const Text('Lyrics'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_lyrics.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_lyrics),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Projects',
                    style: Theme.of(context).textTheme.titleMedium),
                ...projects.map((project) => Card(
                      child: ListTile(
                        title: Text(project.title),
                        subtitle:
                            Text('${project.genre.label} • ${project.mood}'),
                      ),
                    )),
              ],
            ),
    );
  }
}
