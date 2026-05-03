import 'package:anime_waifu/services/creative/music_composition_service.dart';
import 'package:anime_waifu/services/creative/music_gen_service.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MusicCompositionPage extends StatefulWidget {
  const MusicCompositionPage({super.key});

  @override
  State<MusicCompositionPage> createState() => _MusicCompositionPageState();
}

class _MusicCompositionPageState extends State<MusicCompositionPage>
    with SingleTickerProviderStateMixin {
  final _service = MusicCompositionService.instance;
  final _title = TextEditingController();
  final _theme = TextEditingController(text: 'connection');
  final _mood = TextEditingController(text: 'dreamy');
  final _promptCtrl = TextEditingController(
      text: 'Dreamy anime lo-fi, soft piano, gentle rain, peaceful');
  MusicGenre _genre = MusicGenre.pop;
  String _lyrics = '';
  bool _loading = true;

  // Generate tab state
  late TabController _tabCtrl;
  bool _generating = false;
  String? _audioUrl;
  String? _genError;
  int _duration = 15;
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  final List<MusicGenResult> _history = [];
  MusicGenResult? _currentResult;
  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _title.dispose();
    _theme.dispose();
    _mood.dispose();
    _promptCtrl.dispose();
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
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

  Future<void> _generateMusic() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _generating = true;
      _genError = null;
      _audioUrl = null;
      _position = Duration.zero;
      _total = Duration.zero;
    });
    await _player.stop();
    try {
      final result = await MusicGenService.instance.generate(
        prompt: prompt,
        durationSeconds: _duration,
      );
      if (mounted) {
        setState(() {
          _audioUrl = result.audioUrl;
          _currentResult = result;
          _history.insert(0, result);
          if (_history.length > 10) _history.removeLast();
        });
        // Auto-play
        await _player.play(_sourceFor(result.audioUrl));
      }
    } on MusicGenException catch (e) {
      if (mounted) setState(() => _genError = e.message);
    } catch (e) {
      if (mounted) setState(() => _genError = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }


  Source _sourceFor(String url) {
    if (url.startsWith('/') || url.startsWith('file://')) {
      return DeviceFileSource(url.replaceFirst('file://', ''));
    }
    return UrlSource(url);
  }

  Future<void> _togglePlay() async {
    if (_audioUrl == null) return;
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.play(_sourceFor(_audioUrl!));
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Composition'),
        backgroundColor: Colors.purple.shade800,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.music_note_rounded), text: 'Compose'),
            Tab(icon: Icon(Icons.auto_awesome_rounded), text: 'Generate AI'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildComposeTab(),
                _buildGenerateTab(),
              ],
            ),
    );
  }

  // ── Compose tab (original content) ────────────────────────────────────────
  Widget _buildComposeTab() {
    final projects = _service.getProjects();
    return ListView(
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
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _genre = v);
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
        Text('Projects', style: Theme.of(context).textTheme.titleMedium),
        ...projects.map((p) => Card(
              child: ListTile(
                title: Text(p.title),
                subtitle: Text('${p.genre.label} • ${p.mood}'),
              ),
            )),
      ],
    );
  }

  // ── Generate AI tab ────────────────────────────────────────────────────────
  Widget _buildGenerateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade900.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade300.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.purple.shade300, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Powered by Meta MusicGen via Replicate. Free tier: ~1000 generations/month.',
                  style: TextStyle(color: Colors.purple.shade200, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Prompt input
        TextField(
          controller: _promptCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Music prompt',
            hintText: 'e.g. Upbeat anime opening, electric guitar, energetic',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.edit_note_rounded),
          ),
        ),
        const SizedBox(height: 12),

        // Duration slider
        Row(
          children: [
            const Icon(Icons.timer_rounded, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text('Duration: ${_duration}s',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Expanded(
              child: Slider(
                value: _duration.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                label: '${_duration}s',
                activeColor: Colors.purple,
                onChanged: _generating
                    ? null
                    : (v) => setState(() => _duration = v.round()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Generate button
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _generating ? null : _generateMusic,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_generating ? 'Generating…' : 'Generate Music'),
          ),
        ),

        // Error
        if (_genError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_genError!,
                        style: const TextStyle(color: Colors.redAccent))),
              ],
            ),
          ),
        ],

        // Player
        if (_audioUrl != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade900, Colors.deepPurple.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.music_note_rounded,
                        color: Colors.amberAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _promptCtrl.text.trim(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_currentResult != null)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _currentResult!.provider == 'replicate'
                              ? Colors.greenAccent.withValues(alpha: 0.2)
                              : Colors.blueAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _currentResult!.provider == 'replicate'
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : Colors.blueAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _currentResult!.provider == 'replicate'
                              ? 'Replicate' : 'HuggingFace',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _currentResult!.provider == 'replicate'
                                ? Colors.greenAccent : Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.amberAccent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.amberAccent,
                    overlayColor: Colors.amberAccent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _total.inSeconds > 0
                        ? _position.inSeconds
                            .toDouble()
                            .clamp(0, _total.inSeconds.toDouble())
                        : 0,
                    max: _total.inSeconds > 0
                        ? _total.inSeconds.toDouble()
                        : 1,
                    onChanged: (v) =>
                        _player.seek(Duration(seconds: v.round())),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_position),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        _playerState == PlayerState.playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: Colors.amberAccent,
                      ),
                      onPressed: _togglePlay,
                    ),
                    Text(_fmt(_total),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],

        // History
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Recent Generations',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          ..._history.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.music_note_rounded,
                      color: Colors.purple),
                  title: Text(r.prompt,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: () async {
                      setState(() {
                        _audioUrl = r.audioUrl;
                        _promptCtrl.text = r.prompt;
                      });
                      await _player.play(UrlSource(r.audioUrl));
                    },
                  ),
                ),
              )),
        ],
      ],
    );
  }
}
