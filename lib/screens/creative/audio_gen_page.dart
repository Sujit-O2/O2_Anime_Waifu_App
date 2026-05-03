import 'package:anime_waifu/services/creative/music_gen_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AudioGenPage extends StatefulWidget {
  final String? initialPrompt;
  const AudioGenPage({super.key, this.initialPrompt});
  @override
  State<AudioGenPage> createState() => _AudioGenPageState();
}

class _AudioGenPageState extends State<AudioGenPage> {
  late final TextEditingController _promptCtrl;
  int _duration = 15;
  bool _generating = false;
  String? _error;
  String? _audioUrl;
  MusicGenResult? _current;
  final List<MusicGenResult> _history = [];

  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  // Key test state
  bool _testingKeys = false;
  Map<String, String> _keyStatus = {};

  List<String> _envKeys(String envVar) => (dotenv.env[envVar] ?? '')
      .split(',')
      .map((k) => k.trim())
      .where((k) => k.isNotEmpty && !k.contains('YOUR_'))
      .toList();

  Future<void> _testKeys() async {
    setState(() { _testingKeys = true; _keyStatus = {}; });

    Future<String> check(Future<bool> Function() fn) async {
      try { return await fn() ? 'ok' : 'fail'; }
      catch (_) { return 'fail'; }
    }

    final results = <String, String>{};

    final deKeys = _envKeys('DEAPI_API_KEY');
    results['deAPI'] = deKeys.isEmpty ? 'no key' : await check(() async {
      final r = await http.get(
        Uri.parse('https://api.deapi.ai/api/v1/client/balance'),
        headers: {'Authorization': 'Bearer ${deKeys.first}'},
      ).timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    });

    final repKeys = _envKeys('REPLICATE_API_KEY');
    results['Replicate'] = repKeys.isEmpty ? 'no key' : await check(() async {
      final r = await http.get(
        Uri.parse('https://api.replicate.com/v1/account'),
        headers: {'Authorization': 'Bearer ${repKeys.first}'},
      ).timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    });

    final hfKeys = _envKeys('HF_API_KEY');
    results['HuggingFace'] = hfKeys.isEmpty ? 'no key (free tier)' : await check(() async {
      final r = await http.get(
        Uri.parse('https://huggingface.co/api/whoami-v2'),
        headers: {'Authorization': 'Bearer ${hfKeys.first}'},
      ).timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    });

    if (mounted) setState(() { _keyStatus = results; _testingKeys = false; });
  }

  @override
  void initState() {
    super.initState();
    _promptCtrl = TextEditingController(
        text: widget.initialPrompt?.isNotEmpty == true
            ? widget.initialPrompt
            : 'Dreamy anime lo-fi, soft piano, gentle rain, peaceful');
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Source _sourceFor(String url) {
    if (url.startsWith('/') || url.startsWith('file://')) {
      return DeviceFileSource(url.replaceFirst('file://', ''));
    }
    return UrlSource(url);
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _generating = true;
      _error = null;
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
      if (!mounted) return;
      setState(() {
        _audioUrl = result.audioUrl;
        _current = result;
        _history.insert(0, result);
        if (_history.length > 10) _history.removeLast();
      });
      await _player.play(_sourceFor(result.audioUrl));
    } on MusicGenException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
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
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        title: Text('AI Audio Generator',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        actions: [
          if (_current != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _providerBadge(_current!.provider),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info
          _infoCard(
            'deAPI AceStep → Replicate MusicGen → HuggingFace (3-provider fallback).',
            Colors.purple,
          ),
          const SizedBox(height: 8),

          // API Key Test
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purpleAccent,
                  side: const BorderSide(color: Colors.purpleAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _testingKeys ? null : _testKeys,
                icon: _testingKeys
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent))
                    : const Icon(Icons.key_rounded, size: 16),
                label: Text(_testingKeys ? 'Testing…' : 'Test API Keys',
                    style: GoogleFonts.outfit(fontSize: 13)),
              ),
            ),
          ]),
          if (_keyStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _keyStatus.entries.map((e) {
                  final ok = e.value == 'ok';
                  final noKey = e.value.contains('no key');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Icon(
                        ok ? Icons.check_circle_rounded
                            : noKey ? Icons.radio_button_unchecked_rounded
                            : Icons.cancel_rounded,
                        size: 16,
                        color: ok ? Colors.greenAccent
                            : noKey ? Colors.white38
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(e.key,
                          style: TextStyle(
                              color: ok ? Colors.white : Colors.white54,
                              fontSize: 13,
                              fontWeight: ok ? FontWeight.w600 : FontWeight.normal)),
                      const Spacer(),
                      Text(e.value,
                          style: TextStyle(
                              fontSize: 11,
                              color: ok ? Colors.greenAccent
                                  : noKey ? Colors.white38
                                  : Colors.redAccent)),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Prompt
          TextField(
            controller: _promptCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Music prompt',
              labelStyle: const TextStyle(color: Colors.white54),
              hintText: 'e.g. Upbeat anime opening, electric guitar, energetic',
              hintStyle: const TextStyle(color: Colors.white24),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purpleAccent)),
              prefixIcon:
                  const Icon(Icons.music_note_rounded, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 12),

          // Duration slider
          Row(children: [
            const Icon(Icons.timer_rounded, size: 18, color: Colors.white54),
            const SizedBox(width: 8),
            Text('Duration: ${_duration}s',
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
            Expanded(
              child: Slider(
                value: _duration.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                label: '${_duration}s',
                activeColor: Colors.purpleAccent,
                inactiveColor: Colors.white12,
                onChanged: _generating
                    ? null
                    : (v) => setState(() => _duration = v.round()),
              ),
            ),
          ]),
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
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_generating ? 'Generating…' : 'Generate Audio',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorCard(_error!),
          ],

          // Player
          if (_audioUrl != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.purple.shade900,
                  Colors.deepPurple.shade800
                ]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Row(children: [
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
                  if (_current != null) ...[
                    const SizedBox(width: 6),
                    _providerBadge(_current!.provider),
                  ],
                ]),
                const SizedBox(height: 12),
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
              ]),
            ),
          ],

          // History
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Recent Generations',
                style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 8),
            ..._history.map((r) => Card(
                  color: const Color(0xFF1A1A2E),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.music_note_rounded,
                        color: Colors.purpleAccent),
                    title: Text(r.prompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Row(children: [
                      _providerBadge(r.provider),
                      const SizedBox(width: 6),
                      Text(
                        '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ]),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white54),
                      onPressed: () async {
                        setState(() {
                          _audioUrl = r.audioUrl;
                          _current = r;
                          _promptCtrl.text = r.prompt;
                        });
                        await _player.play(_sourceFor(r.audioUrl));
                      },
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

Widget _infoCard(String text, Color color) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded,
            color: color.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color.withValues(alpha: 0.8), fontSize: 12))),
      ]),
    );

Widget _errorCard(String msg) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Colors.redAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 13))),
      ]),
    );

Widget _providerBadge(String provider) {
  final info = _providerInfo(provider);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: info.$2.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: info.$2.withValues(alpha: 0.4)),
    ),
    child: Text(
      info.$1,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: info.$2),
    ),
  );
}

(String, Color) _providerInfo(String provider) => switch (provider) {
  'deapi'       => ('deAPI.ai',    Colors.amberAccent),
  'replicate'   => ('Replicate',   Colors.greenAccent),
  _             => ('HuggingFace', Colors.lightBlueAccent),
};
