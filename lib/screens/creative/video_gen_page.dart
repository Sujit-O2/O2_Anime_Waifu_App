import 'dart:io';
import 'package:anime_waifu/services/creative/video_gen_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class VideoGenPage extends StatefulWidget {
  final String? initialPrompt;
  const VideoGenPage({super.key, this.initialPrompt});
  @override
  State<VideoGenPage> createState() => _VideoGenPageState();
}

class _VideoGenPageState extends State<VideoGenPage> {
  late final TextEditingController _promptCtrl;
  int _numFrames = 24;
  int _fps = 8;
  bool _generating = false;
  String? _error;
  VideoPlayerController? _vpCtrl;
  final List<VideoGenResult> _history = [];
  VideoGenResult? _current;

  // Key test state
  bool _testingKeys = false;
  Map<String, String> _keyStatus = {}; // provider → 'ok' | 'fail' | 'no key'

  List<String> _envKeys(String envVar) => (dotenv.env[envVar] ?? '')
      .split(',')
      .map((k) => k.trim())
      .where((k) => k.isNotEmpty && !k.contains('YOUR_'))
      .toList();

  Future<void> _testKeys() async {
    setState(() { _testingKeys = true; _keyStatus = {}; });

    Future<String> check(String label, Future<bool> Function() fn) async {
      try { return await fn() ? 'ok' : 'fail'; }
      catch (_) { return 'fail'; }
    }

    final results = <String, String>{};

    // deAPI — check account balance endpoint
    final deKeys = _envKeys('DEAPI_API_KEY');
    if (deKeys.isEmpty) {
      results['deAPI'] = 'no key';
    } else {
      results['deAPI'] = await check('deAPI', () async {
        final r = await http.get(
          Uri.parse('https://api.deapi.ai/api/v1/client/balance'),
          headers: {'Authorization': 'Bearer ${deKeys.first}'},
        ).timeout(const Duration(seconds: 8));
        return r.statusCode == 200;
      });
    }

    // Replicate — check account endpoint
    final repKeys = _envKeys('REPLICATE_API_KEY');
    if (repKeys.isEmpty) {
      results['Replicate'] = 'no key';
    } else {
      results['Replicate'] = await check('Replicate', () async {
        final r = await http.get(
          Uri.parse('https://api.replicate.com/v1/account'),
          headers: {'Authorization': 'Bearer ${repKeys.first}'},
        ).timeout(const Duration(seconds: 8));
        return r.statusCode == 200;
      });
    }

    // FAL — check models list
    final falKeys = _envKeys('FAL_API_KEY');
    if (falKeys.isEmpty) {
      results['FAL.ai'] = 'no key';
    } else {
      results['FAL.ai'] = await check('FAL', () async {
        final r = await http.get(
          Uri.parse('https://rest.alpha.fal.ai/v1/user'),
          headers: {'Authorization': 'Key ${falKeys.first}'},
        ).timeout(const Duration(seconds: 8));
        return r.statusCode == 200 || r.statusCode == 404; // 404 = valid key, wrong endpoint
      });
    }

    // Stability — check user endpoint
    final stabKeys = _envKeys('STABILITY_API_KEY');
    if (stabKeys.isEmpty) {
      results['Stability'] = 'no key';
    } else {
      results['Stability'] = await check('Stability', () async {
        final r = await http.get(
          Uri.parse('https://api.stability.ai/v1/user/account'),
          headers: {'Authorization': 'Bearer ${stabKeys.first}'},
        ).timeout(const Duration(seconds: 8));
        return r.statusCode == 200;
      });
    }

    // Runway — check account
    final runwayKeys = _envKeys('RUNWAY_API_KEY');
    if (runwayKeys.isEmpty) {
      results['RunwayML'] = 'no key';
    } else {
      results['RunwayML'] = await check('Runway', () async {
        final r = await http.get(
          Uri.parse('https://api.dev.runwayml.com/v1/organization'),
          headers: {
            'Authorization': 'Bearer ${runwayKeys.first}',
            'X-Runway-Version': '2024-11-06',
          },
        ).timeout(const Duration(seconds: 8));
        return r.statusCode == 200 || r.statusCode == 403; // 403 = valid key, no org access
      });
    }

    // HuggingFace — check whoami
    final hfKeys = _envKeys('HF_API_KEY');
    if (hfKeys.isEmpty) {
      results['HuggingFace'] = 'no key (free tier)';
    } else {
      results['HuggingFace'] = await check('HF', () async {
        final r = await http.get(
          Uri.parse('https://huggingface.co/api/whoami-v2'),
          headers: {'Authorization': 'Bearer ${hfKeys.first}'},
        ).timeout(const Duration(seconds: 8));
        return r.statusCode == 200;
      });
    }

    if (mounted) setState(() { _keyStatus = results; _testingKeys = false; });
  }

  @override
  void initState() {
    super.initState();
    _promptCtrl = TextEditingController(
        text: widget.initialPrompt?.isNotEmpty == true
            ? widget.initialPrompt
            : 'Anime girl walking through cherry blossom park, cinematic');
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _vpCtrl?.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    await _vpCtrl?.dispose();
    _vpCtrl = null;

    try {
      final result = await VideoGenService.instance.generate(
        prompt: prompt,
        numFrames: _numFrames,
        fps: _fps,
      );
      if (!mounted) return;
      await _loadVideo(result);
      setState(() {
        _current = result;
        _history.insert(0, result);
        if (_history.length > 10) _history.removeLast();
      });
    } on VideoGenException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _loadVideo(VideoGenResult result) async {
    final ctrl = result.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(result.videoUrl))
        : VideoPlayerController.file(File(result.videoUrl));
    await ctrl.initialize();
    ctrl.setLooping(true);
    await ctrl.play();
    if (mounted) {
      setState(() => _vpCtrl = ctrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        title: Text('AI Video Generator',
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
            'deAPI LTX-2.3 → Replicate zeroscope → FAL.ai → Stability AI → RunwayML → HuggingFace (6-provider fallback, multi-key rotation).',
            Colors.deepPurple,
          ),
          const SizedBox(height: 8),

          // API Key Test
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurpleAccent,
                  side: const BorderSide(color: Colors.deepPurpleAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _testingKeys ? null : _testKeys,
                icon: _testingKeys
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent))
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
              labelText: 'Video prompt',
              labelStyle: const TextStyle(color: Colors.white54),
              hintText: 'e.g. Anime girl in rain, neon city, cinematic',
              hintStyle: const TextStyle(color: Colors.white24),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.deepPurpleAccent)),
              prefixIcon:
                  const Icon(Icons.movie_creation_rounded, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 12),

          // Frames & FPS
          Row(children: [
            Expanded(child: _sliderTile('Frames', _numFrames, 8, 48, 5,
                (v) => setState(() => _numFrames = v))),
            const SizedBox(width: 12),
            Expanded(child: _sliderTile('FPS', _fps, 4, 24, 4,
                (v) => setState(() => _fps = v))),
          ]),
          const SizedBox(height: 4),
          Text(
            'Duration ≈ ${(_numFrames / _fps).toStringAsFixed(1)}s',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Generate button
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
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
                  : const Icon(Icons.videocam_rounded),
              label: Text(_generating ? 'Generating…' : 'Generate Video',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorCard(_error!),
          ],

          // Video player
          if (_vpCtrl != null && _vpCtrl!.value.isInitialized) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: _vpCtrl!.value.aspectRatio,
                child: VideoPlayer(_vpCtrl!),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _vpCtrl!.value.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    color: Colors.deepPurpleAccent,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _vpCtrl!.value.isPlaying
                          ? _vpCtrl!.pause()
                          : _vpCtrl!.play();
                    });
                  },
                ),
              ],
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
                    leading: const Icon(Icons.movie_rounded,
                        color: Colors.deepPurpleAccent),
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
                        setState(() => _current = r);
                        await _loadVideo(r);
                      },
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _sliderTile(String label, int value, int min, int max, int divisions,
      ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          activeColor: Colors.deepPurpleAccent,
          inactiveColor: Colors.white12,
          onChanged: _generating ? null : (v) => onChanged(v.round()),
        ),
      ],
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
        Icon(Icons.info_outline_rounded, color: color.withValues(alpha: 0.8), size: 16),
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
                style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
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
  'deapi'       => ('deAPI.ai',     Colors.amberAccent),
  'replicate'   => ('Replicate',    Colors.greenAccent),
  'fal'         => ('FAL.ai',       Colors.orangeAccent),
  'stability'   => ('Stability AI', Colors.purpleAccent),
  'runway'      => ('RunwayML',     Colors.cyanAccent),
  _             => ('HuggingFace',  Colors.lightBlueAccent),
};
