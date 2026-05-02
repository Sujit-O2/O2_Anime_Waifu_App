import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';
import 'package:anime_waifu/services/utilities_core/image_gen_service.dart';

/// AI Anime Art Generator — Generate custom waifu art via AI.
/// User types a prompt → AI generates anime-style art.
class AiArtGeneratorPage extends StatefulWidget {
  const AiArtGeneratorPage({super.key});

  @override
  State<AiArtGeneratorPage> createState() => _AiArtGeneratorPageState();
}

class _AiArtGeneratorPageState extends State<AiArtGeneratorPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _promptCtrl = TextEditingController();
  final List<_GeneratedArt> _gallery = <_GeneratedArt>[];
  bool _generating = false;
  String? _error;
  late AnimationController _pulseCtrl;

  // Style presets
  static const List<_StylePreset> _presets = <_StylePreset>[
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
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final fullPrompt = '$prompt, $_selectedStyle, high quality, masterpiece';
      final result = await ImageGenService.generateImage(fullPrompt);

      if (result != null) {
        if (!mounted) return;
        setState(() {
          _gallery.insert(
            0,
            _GeneratedArt(
              url: result.url,
              bytes: result.bytes,
              prompt: prompt,
              revisedPrompt: fullPrompt,
              timestamp: DateTime.now(),
            ),
          );
        });
        HapticFeedback.heavyImpact();
      } else {
        setState(() {
          _error = 'Generation failed. Tap ✨ to retry with a different seed.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed: $e. Tap ✨ to retry.');
    }

    if (mounted) {
      setState(() => _generating = false);
    }
  }

  Future<void> _downloadImage(_GeneratedArt art) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imgDir = Directory('${dir.path}/saved_images');
      if (!await imgDir.exists()) {
        await imgDir.create(recursive: true);
      }
      final fileName = 'ai_art_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${imgDir.path}/$fileName');
      await file.writeAsBytes(art.bytes);

      // Also try saving to external Pictures folder for gallery visibility
      try {
        final extDir = Directory('/storage/emulated/0/Pictures/AnimeWaifu');
        if (!await extDir.exists()) {
          await extDir.create(recursive: true);
        }
        final extFile = File('${extDir.path}/$fileName');
        await extFile.writeAsBytes(art.bytes);
      } catch (_) {}

      if (mounted) {
        showSuccessSnackbar(context, 'Image saved to Pictures/AnimeWaifu!');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString().split(':').first}'),
            backgroundColor: Colors.redAccent,
          ),
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
          children: <Widget>[
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(art.bytes, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
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
                          child: const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              art.revisedPrompt,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: WaifuBackground(
        opacity: 0.08,
        tint: V2Theme.surfaceDark,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'AI Art Generator',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Generate custom anime art.',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Style Presets
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _presets.length,
                  itemBuilder: (_, i) {
                    final p = _presets[i];
                    final isActive = _selectedStyle == p.suffix;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Semantics(
                        button: true,
                        label: 'Art style ${p.label}',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedStyle = p.suffix);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: isActive
                                    ? V2Theme.primaryColor.withValues(alpha: 0.22)
                                    : Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: isActive
                                      ? V2Theme.primaryColor
                                      : Colors.white10,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  p.label,
                                  style: GoogleFonts.outfit(
                                    color: isActive ? Colors.white : Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Prompt Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _promptCtrl,
                        style: GoogleFonts.outfit(color: Colors.white),
                        maxLines: 2,
                        minLines: 1,
                        cursorColor: V2Theme.primaryColor,
                        decoration: InputDecoration(
                          hintText: 'Describe your anime art...',
                          hintStyle: GoogleFonts.outfit(
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _generate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      button: true,
                      label: _generating ? 'Generating art' : 'Generate art',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: _generating ? null : _generate,
                          child: AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    V2Theme.primaryColor,
                                    V2Theme.secondaryColor.withValues(
                                      alpha: _generating
                                          ? 0.3 + _pulseCtrl.value * 0.7
                                          : 1.0,
                                    ),
                                  ],
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: V2Theme.primaryColor.withValues(
                                      alpha: _generating ? 0.4 : 0.2,
                                    ),
                                    blurRadius: _generating ? 18 : 8,
                                    spreadRadius: _generating ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _generating
                                    ? Icons.hourglass_top_rounded
                                    : Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _error!,
                    style: GoogleFonts.outfit(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Gallery
              Expanded(
                child: _gallery.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              '🎨',
                              style: TextStyle(fontSize: 54),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Type a prompt to generate art',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Powered by advanced AI rendering models.',
                              style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _gallery.length,
                        itemBuilder: (_, i) {
                          final art = _gallery[i];
                          return AnimatedEntry(
                            index: i,
                            child: GestureDetector(
                              onTap: () => _showFullArt(art),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    Image.memory(
                                      art.bytes,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.black45,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image_rounded,
                                            color: Colors.white38,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _gallery.removeAt(i));
                                          HapticFeedback.lightImpact();
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black54,
                                            border: Border.all(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          10,
                                          16,
                                          10,
                                          10,
                                        ),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: <Color>[
                                              Colors.black87,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          art.prompt,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StylePreset {
  const _StylePreset(this.label, this.suffix);
  final String label;
  final String suffix;
}

class _GeneratedArt {
  const _GeneratedArt({
    required this.url,
    required this.bytes,
    required this.prompt,
    required this.revisedPrompt,
    required this.timestamp,
  });
  final String url;
  final Uint8List bytes;
  final String prompt;
  final String revisedPrompt;
  final DateTime timestamp;
}



