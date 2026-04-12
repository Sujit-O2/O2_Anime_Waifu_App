import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:home_widget/home_widget.dart';

/// Full-featured 3D AR Companion viewer with a model gallery,
/// interactive camera controls, and real AR projection support.
class ArCompanionPage extends StatefulWidget {
  const ArCompanionPage({super.key});
  @override
  State<ArCompanionPage> createState() => _ArCompanionPageState();
}

class _ArCompanionPageState extends State<ArCompanionPage>
    with SingleTickerProviderStateMixin {
  int _selectedModel = 0;
  late AnimationController _pulseCtrl;
  final FlutterTts _tts = FlutterTts();

  bool _autoRotate = true;

  // Exclusively injected 4 high-performance models
  static const List<_ModelEntry> _models = [
    _ModelEntry(
      name: 'Anime Woman',
      description: 'Standard 3D Waifu',
      url: 'assets/models/anime_woman_model.glb',
      poster: '',
      color: Color(0xFFFF4081),
      icon: Icons.girl_rounded,
    ),
    _ModelEntry(
      name: 'Aqua Chibi',
      description: 'Aqua Chibi (Konosuba)',
      url: 'assets/models/aqua__anime_chibi_model.glb',
      poster: '',
      color: Color(0xFF00B0FF),
      icon: Icons.water_drop_rounded,
    ),
    _ModelEntry(
      name: 'Cyber Samurai',
      description: 'Sci-fi styled samurai',
      url: 'assets/models/cyber_samurai.glb',
      poster: '',
      color: Color(0xFFD50000),
      icon: Icons.shield_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.55);
    await _tts.setPitch(1.2); // Cute higher pitch for companion
  }

  Future<void> _sendToWidget() async {
    final model = _models[_selectedModel];
    try {
      await HomeWidget.saveWidgetData<String>('waifu_name', model.name);
      await HomeWidget.updateWidget(name: 'WaifuWidgetReceiver');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${model.name} locked into Home Screen widget! \n(Restart app to initialize Android broadcast receiver)'),
          backgroundColor: model.color,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint("Widget update failed: $e");
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = _models[_selectedModel];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Column(
        children: [
          // ── 3D VIEWER ──────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // The actual 3D model viewer
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(28)),
                  child: ModelViewer(
                    key: ValueKey(
                        '${model.url}_$_autoRotate'), // Force full rebuild to stop rotation instantly
                    backgroundColor: const Color(0xFF0F1018),
                    src: model.url,
                    poster: model.poster.isNotEmpty ? model.poster : null,
                    alt: model.description,
                    ar: true,
                    arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                    autoRotate: _autoRotate,
                    autoRotateDelay: 0,
                    rotationPerSecond: _autoRotate ? '24deg' : '0deg',
                    autoPlay: true,
                    cameraControls: true,
                    disableZoom: false,
                    interactionPrompt: InteractionPrompt.auto,
                    shadowIntensity: 0, // Disabled for performance (Lag Fix)
                    shadowSoftness: 0,
                    exposure: 1.0,
                  ),
                ),

                // Top gradient overlay for status bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Back button + title
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AR COMPANION',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2)),
                              Text(
                                  'Pinch to zoom • Drag to rotate • Tap AR icon to project',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white38, fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Current model name badge (bottom of viewer)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: model.color.withValues(
                              alpha: 0.15 + _pulseCtrl.value * 0.05),
                          border: Border.all(
                              color: model.color.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                                color: model.color.withValues(
                                    alpha: 0.15 + _pulseCtrl.value * 0.1),
                                blurRadius: 20),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(model.icon, color: model.color, size: 16),
                            const SizedBox(width: 8),
                            Text(model.name.toUpperCase(),
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5)),
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.greenAccent,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.greenAccent.withValues(
                                          alpha: 0.5 + _pulseCtrl.value * 0.5),
                                      blurRadius: 8)
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── MODEL GALLERY ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('MODEL GALLERY',
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 88,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: _models.length,
                    itemBuilder: (context, i) {
                      final m = _models[i];
                      final selected = i == _selectedModel;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedModel = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: selected ? 150 : 120,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: selected
                                  ? [
                                      m.color.withValues(alpha: 0.25),
                                      m.color.withValues(alpha: 0.08)
                                    ]
                                  : [
                                      Colors.white.withValues(alpha: 0.04),
                                      Colors.white.withValues(alpha: 0.02)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: selected
                                  ? m.color.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.06),
                              width: selected ? 1.5 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: m.color.withValues(alpha: 0.2),
                                        blurRadius: 16,
                                        spreadRadius: -2)
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(m.icon,
                                      color:
                                          selected ? m.color : Colors.white30,
                                      size: 18),
                                  if (selected) ...[
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: m.color.withValues(alpha: 0.2),
                                      ),
                                      child: Text('LIVE',
                                          style: GoogleFonts.jetBrainsMono(
                                              color: m.color,
                                              fontSize: 7,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1)),
                                    ),
                                  ],
                                ],
                              ),
                              const Spacer(),
                              Text(
                                m.name,
                                style: GoogleFonts.outfit(
                                  color:
                                      selected ? Colors.white : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.description,
                                style: GoogleFonts.outfit(
                                    color: Colors.white24, fontSize: 8),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ),

          // ── ACTION COMMANDS ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text('VIEWER SETTINGS',
                      style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        _autoRotate ? 'STOP ROTATING' : 'AUTO-ROTATE',
                        _autoRotate
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        _autoRotate ? Colors.redAccent : Colors.tealAccent,
                        () => setState(() => _autoRotate = !_autoRotate),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'WIDGET',
                        Icons.home_filled,
                        Colors.amberAccent,
                        _sendToWidget,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'AR MODE',
                        Icons.view_in_ar_rounded,
                        model.color,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Tap the AR icon on the 3D viewer above!',
                                  style: GoogleFonts.outfit(fontSize: 12)),
                              backgroundColor:
                                  model.color.withValues(alpha: 0.9),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Safe area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

/// Data class for a 3D model entry in the gallery.
class _ModelEntry {
  final String name;
  final String description;
  final String url;
  final String poster;
  final Color color;
  final IconData icon;

  const _ModelEntry({
    required this.name,
    required this.description,
    required this.url,
    required this.poster,
    required this.color,
    required this.icon,
  });
}



