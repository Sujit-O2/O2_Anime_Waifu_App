import 'package:anime_waifu/services/creative/art_direction_service.dart';
import 'package:flutter/material.dart';

class ArtDirectionPage extends StatefulWidget {
  const ArtDirectionPage({super.key});

  @override
  State<ArtDirectionPage> createState() => _ArtDirectionPageState();
}

class _ArtDirectionPageState extends State<ArtDirectionPage> {
  final _service = ArtDirectionService.instance;
  final _title = TextEditingController();
  final _mood = TextEditingController(text: 'bold');
  final _baseColor = TextEditingController(text: '#FF4DA6');
  DesignType _type = DesignType.ui;
  PaletteType _paletteType = PaletteType.analogous;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _mood.dispose();
    _baseColor.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createProject() async {
    if (_title.text.trim().isEmpty) return;
    await _service.createDesignProject(
      title: _title.text.trim(),
      type: _type,
      description: 'Created from Art Direction dashboard',
      targetAudience: 'App users',
      mood: _mood.text.trim().isEmpty ? 'balanced' : _mood.text.trim(),
    );
    _title.clear();
    if (mounted) setState(() {});
  }

  Future<void> _generatePalette() async {
    await _service.generateColorPalette(
      name: '${_mood.text.trim()} palette',
      baseColor:
          _baseColor.text.trim().isEmpty ? '#FF4DA6' : _baseColor.text.trim(),
      type: _paletteType,
      mood: _mood.text.trim().isEmpty ? 'balanced' : _mood.text.trim(),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final projects = _service.getProjects();
    final palettes = _service.getPalettes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Direction'),
        backgroundColor: Colors.pink.shade600,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.pink.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_service.getArtInsights()),
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
                          controller: _mood,
                          decoration: const InputDecoration(labelText: 'Mood'),
                        ),
                        DropdownButtonFormField<DesignType>(
                          value: _type,
                          decoration:
                              const InputDecoration(labelText: 'Design type'),
                          items: DesignType.values
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type.label),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _type = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _createProject,
                            icon: const Icon(Icons.dashboard_customize_rounded),
                            label: const Text('Create Project'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _baseColor,
                          decoration: const InputDecoration(
                              labelText: 'Base hex color'),
                        ),
                        DropdownButtonFormField<PaletteType>(
                          value: _paletteType,
                          decoration:
                              const InputDecoration(labelText: 'Palette type'),
                          items: PaletteType.values
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type.label),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => _paletteType = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _generatePalette,
                            icon: const Icon(Icons.palette_rounded),
                            label: const Text('Generate Palette'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Projects',
                    style: Theme.of(context).textTheme.titleMedium),
                ...projects.map((project) => Card(
                      child: ListTile(
                        title: Text(project.title),
                        subtitle:
                            Text('${project.type.label} • ${project.mood}'),
                      ),
                    )),
                const SizedBox(height: 16),
                Text('Palettes',
                    style: Theme.of(context).textTheme.titleMedium),
                ...palettes.map((palette) => Card(
                      child: ListTile(
                        title: Text(palette.name),
                        subtitle: Wrap(
                          spacing: 6,
                          children: palette.colors
                              .map((color) => Chip(label: Text(color)))
                              .toList(),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
