import 'dart:io';
import 'package:anime_waifu/services/creative/video_gen_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() { _generating = true; _error = null; });
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
    if (mounted) setState(() => _vpCtrl = ctrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        title: Text('AI Video Generator',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(
            'Powered by HuggingFace (damo-vilab/text-to-video-ms-1.7b) — free, no credit card. Multi-key rotation for best availability.',
            Colors.deepPurple,
          ),
          const SizedBox(height: 12),

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
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent)),
              prefixIcon: const Icon(Icons.movie_creation_rounded, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 12),

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

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.videocam_rounded),
              label: Text(_generating ? 'Generating…' : 'Generate Video',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorCard(_error!),
          ],

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
                  onPressed: () => setState(() {
                    _vpCtrl!.value.isPlaying ? _vpCtrl!.pause() : _vpCtrl!.play();
                  }),
                ),
              ],
            ),
          ],

          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Recent Generations',
                style: GoogleFonts.outfit(
                    color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            ..._history.map((r) => Card(
                  color: const Color(0xFF1A1A2E),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.movie_rounded, color: Colors.deepPurpleAccent),
                    title: Text(r.prompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white54),
                      onPressed: () async {
                        await _vpCtrl?.dispose();
                        _vpCtrl = null;
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
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
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
                style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12))),
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
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
      ]),
    );
