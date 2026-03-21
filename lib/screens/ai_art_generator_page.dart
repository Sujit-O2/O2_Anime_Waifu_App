import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AI Anime Art Generator — Generate custom waifu art via DALL-E API.
/// User types a prompt → OpenAI DALL-E generates anime-style art.
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
    _StylePreset('💜 Cyberpunk', 'cyberpunk anime, neon lights, futuristic city'),
    _StylePreset('🌊 Ghibli', 'studio ghibli style, watercolor, peaceful'),
    _StylePreset('⚔️ Shonen', 'shonen anime style, action pose, dynamic'),
    _StylePreset('🎀 Kawaii', 'cute kawaii anime, pastel colors, chibi'),
    _StylePreset('🔥 Chainsaw', 'dark manga style, horror, chainsaw man aesthetic'),
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

    setState(() { _generating = true; _error = null; });
    HapticFeedback.mediumImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('api_key') ?? '';
      if (apiKey.isEmpty) {
        setState(() { _error = 'No API key set. Go to Settings.'; _generating = false; });
        return;
      }

      final fullPrompt = '$prompt, $_selectedStyle, high quality, masterpiece';

      final resp = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': fullPrompt,
          'n': 1,
          'size': '1024x1024',
          'quality': 'standard',
        }),
      ).timeout(const Duration(seconds: 60));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final url = data['data']?[0]?['url'] as String?;
        final revisedPrompt = data['data']?[0]?['revised_prompt'] as String? ?? prompt;
        if (url != null) {
          setState(() {
            _gallery.insert(0, _GeneratedArt(
              url: url,
              prompt: prompt,
              revisedPrompt: revisedPrompt,
              timestamp: DateTime.now(),
            ));
          });
          HapticFeedback.heavyImpact();
        }
      } else {
        final body = jsonDecode(resp.body);
        setState(() => _error = body['error']?['message'] ?? 'Generation failed (${resp.statusCode})');
      }
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    }

    setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('🎨 AI Art Generator',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.deepPurple.withValues(alpha: 0.5), Colors.black.withValues(alpha: 0.95),
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
                          color: isActive ? Colors.deepPurple : Colors.transparent),
                      ),
                      child: Center(child: Text(p.label,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey.shade500,
                          fontSize: 12, fontWeight: FontWeight.w600))),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          Colors.deepPurple,
                          Colors.pinkAccent.withValues(alpha: _generating
                              ? 0.3 + _pulseCtrl.value * 0.7 : 1.0),
                        ]),
                        boxShadow: [BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.4),
                          blurRadius: 12)],
                      ),
                      child: Icon(
                        _generating ? Icons.hourglass_top : Icons.auto_awesome,
                        color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),

          // Gallery
          Expanded(
            child: _gallery.isEmpty
                ? Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎨', style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Type a prompt to generate anime art',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Powered by DALL-E 3',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                    ],
                  ))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
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
                              Image.network(art.url, fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) =>
                                  progress == null ? child : Container(
                                    color: Colors.grey.shade900,
                                    child: const Center(child: CircularProgressIndicator(
                                      color: Colors.deepPurple, strokeWidth: 2)))),
                              Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                      colors: [Colors.black87, Colors.transparent],
                                    ),
                                  ),
                                  child: Text(art.prompt, maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 10)),
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

  void _showFullArt(_GeneratedArt art) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(art.url, fit: BoxFit.contain)),
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
  final String prompt;
  final String revisedPrompt;
  final DateTime timestamp;
  _GeneratedArt({required this.url, required this.prompt,
    required this.revisedPrompt, required this.timestamp});
}
