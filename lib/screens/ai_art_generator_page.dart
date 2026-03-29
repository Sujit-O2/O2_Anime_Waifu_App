import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../services/image_gen_service.dart';

/// AI Anime Art Generator — Generate custom waifu art via AI.
/// User types a prompt → AI generates anime-style art.
class AiArtGeneratorPage extends StatefulWidget {
  const AiArtGeneratorPage({super.key});
  @override
  State<AiArtGeneratorPage> createState() => _AiArtGeneratorPageState();
}

class _AiArtGeneratorPageState extends State<AiArtGeneratorPage>
    with SingleTickerProviderStateMixin {
  final _promptCtrl = TextEditingController();
  final List<_GeneratedArt> _gallery = [];
  bool _generating = false;
  String? _error;
  late AnimationController _pulseCtrl;

  // Style presets
  static const List<_StylePreset> _presets = [
    _StylePreset('🌸 Anime', 'anime style, vibrant colors, detailed'),
    _StylePreset('🌙 Dark', 'dark anime aesthetic, moody, cinematic lighting'),
    _StylePreset(
        '💜 Cyberpunk', 'cyberpunk anime, neon lights, futuristic city'),
    _StylePreset('🌊 Ghibli', 'studio ghibli style, watercolor, peaceful'),
    _StylePreset('⚔️ Shonen', 'shonen anime style, action pose, dynamic'),
    _StylePreset('🎀 Kawaii', 'cute kawaii anime, pastel colors, chibi'),
    _StylePreset(
        '🔥 Chainsaw', 'dark manga style, horror, chainsaw man aesthetic'),
    _StylePreset('🌌 Space', 'cosmic anime, galaxy background, stars'),
  ];

  String _selectedStyle = _presets[0].suffix;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _generating = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final fullPrompt = '$prompt, $_selectedStyle, high quality, masterpiece';
      final result = await ImageGenService.generateImage(fullPrompt);

      if (result != null) {
        setState(() {
          _gallery.insert(
              0,
              _GeneratedArt(
                url: result.url,
                bytes: result.bytes,
                prompt: prompt,
                revisedPrompt: fullPrompt,
                timestamp: DateTime.now(),
              ));
        });
        HapticFeedback.heavyImpact();
      } else {
        setState(() => _error =
            'Generation failed. Tap ✨ to retry with a different seed.');
      }
    } catch (e) {
      setState(() => _error = 'Failed: $e. Tap ✨ to retry.');
    }

    setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🎨 AI Art Generator',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.deepPurple.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.95),
            ]),
          ),
        ),
      ),
      body: Column(
        children: [
          // Style Presets
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _presets.length,
              itemBuilder: (_, i) {
                final p = _presets[i];
                final isActive = _selectedStyle == p.suffix;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStyle = p.suffix),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isActive
                            ? Colors.deepPurple.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                            color: isActive
                                ? Colors.deepPurple
                                : Colors.transparent),
                      ),
                      child: Center(
                          child: Text(p.label,
                              style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600))),
                    ),
                  ),
                );
              },
            ),
          ),

          // Prompt Input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Describe your anime art...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _generate(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _generating ? null : _generate,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          Colors.deepPurple,
                          Colors.pinkAccent.withValues(
                              alpha: _generating
                                  ? 0.3 + _pulseCtrl.value * 0.7
                                  : 1.0),
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.4),
                              blurRadius: 12)
                        ],
                      ),
                      child: Icon(
                          _generating
                              ? Icons.hourglass_top
                              : Icons.auto_awesome,
                          color: Colors.white,
                          size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),

          // Gallery
          Expanded(
            child: _gallery.isEmpty
                ? Center(
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎨', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Type a prompt to generate anime art',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Powered by AI Image Generation',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 11)),
                    ],
                  ))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10),
                    itemCount: _gallery.length,
                    itemBuilder: (_, i) {
                      final art = _gallery[i];
                      return GestureDetector(
                        onTap: () => _showFullArt(art),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Use bytes directly for reliable display
                              Image.memory(art.bytes,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade900,
                                    child: const Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey, size: 32),
                                    ),
                                  )),
                              // Delete button overlay
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _gallery.removeAt(i));
                                    HapticFeedback.lightImpact();
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black54,
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black87,
                                        Colors.transparent
                                      ],
                                    ),
                                  ),
                                  child: Text(art.prompt,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadImage(_GeneratedArt art) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imgDir = Directory('${dir.path}/saved_images');
      if (!await imgDir.exists()) await imgDir.create(recursive: true);
      final fileName = 'ai_art_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${imgDir.path}/$fileName');
      await file.writeAsBytes(art.bytes);

      // Also try saving to external Pictures folder for gallery visibility
      try {
        final extDir = Directory('/storage/emulated/0/Pictures/AnimeWaifu');
        if (!await extDir.exists()) await extDir.create(recursive: true);
        final extFile = File('${extDir.path}/$fileName');
        await extFile.writeAsBytes(art.bytes);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('💾 Image saved to Pictures/AnimeWaifu!'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${e.toString().split(':').first}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showFullArt(_GeneratedArt art) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(art.bytes, fit: BoxFit.contain)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Download button
                      GestureDetector(
                        onTap: () => _downloadImage(art),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      GestureDetector(
                        onTap: () {
                          setState(() => _gallery.remove(art));
                          Navigator.pop(ctx);
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: 0.7),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(art.revisedPrompt,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StylePreset {
  final String label;
  final String suffix;
  const _StylePreset(this.label, this.suffix);
}

class _GeneratedArt {
  final String url;
  final Uint8List bytes;
  final String prompt;
  final String revisedPrompt;
  final DateTime timestamp;
  _GeneratedArt(
      {required this.url,
      required this.bytes,
      required this.prompt,
      required this.revisedPrompt,
      required this.timestamp});
}
