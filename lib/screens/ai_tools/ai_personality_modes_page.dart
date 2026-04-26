import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/core/v2_upgrade_kit.dart';

class AiPersonalityModesPage extends StatefulWidget {
  const AiPersonalityModesPage({super.key});

  @override
  State<AiPersonalityModesPage> createState() => _AiPersonalityModesPageState();
}

class _AiPersonalityModesPageState extends State<AiPersonalityModesPage> {
  static const String _modeKey = 'ai_personality_mode';
  static const String _promptKey = 'ai_personality_prompt';

  final List<Map<String, dynamic>> _modes = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'waifu',
      'name': 'Waifu Mode',
      'emoji': '💖',
      'desc': 'Sweet, emotional, and classic Zero Two energy.',
      'traits': <String>['Loving', 'Playful', 'Teasing', 'Supportive'],
      'prompt':
          'Be sweet, caring, and emotionally warm. Use pet names and show affection.',
      'color': const Color(0xFFFF4081),
      'gradient': const <Color>[Color(0xFFFF4081), Color(0xFFFF80AB)],
    },
    <String, dynamic>{
      'id': 'dev',
      'name': 'Dev Mode',
      'emoji': '🧑‍💻',
      'desc': 'Technical, precise, and code-first.',
      'traits': <String>['Technical', 'Analytical', 'Precise', 'Efficient'],
      'prompt':
          'Be a senior developer. Give precise, clean code. Keep answers technical.',
      'color': const Color(0xFF00BCD4),
      'gradient': const <Color>[Color(0xFF00BCD4), Color(0xFF4DD0E1)],
    },
    <String, dynamic>{
      'id': 'mentor',
      'name': 'Mentor Mode',
      'emoji': '🧠',
      'desc': 'Wise, strict, and built for growth.',
      'traits': <String>['Strict', 'Motivating', 'Honest', 'Challenging'],
      'prompt':
          'Be a strict but caring mentor. Challenge weak decisions and push for excellence.',
      'color': const Color(0xFFFF9800),
      'gradient': const <Color>[Color(0xFFFF9800), Color(0xFFFFB74D)],
    },
    <String, dynamic>{
      'id': 'fun',
      'name': 'Fun Mode',
      'emoji': '🎮',
      'desc': 'Memes, jokes, and full entertainment mode.',
      'traits': <String>['Funny', 'Sarcastic', 'Chaotic', 'Wild'],
      'prompt':
          'Be funny and casual. Use jokes, memes, and playful energy.',
      'color': const Color(0xFF76FF03),
      'gradient': const <Color>[Color(0xFF76FF03), Color(0xFFB2FF59)],
    },
    <String, dynamic>{
      'id': 'therapist',
      'name': 'Therapist Mode',
      'emoji': '🧘',
      'desc': 'Calm, empathetic, and deeply attentive.',
      'traits': <String>['Empathetic', 'Calm', 'Insightful', 'Patient'],
      'prompt':
          'Be compassionate and thoughtful. Listen deeply and validate feelings.',
      'color': const Color(0xFF7C4DFF),
      'gradient': const <Color>[Color(0xFF7C4DFF), Color(0xFFB388FF)],
    },
    <String, dynamic>{
      'id': 'debate',
      'name': 'Debate Mode',
      'emoji': '⚡',
      'desc': 'Pushback, contrarian thinking, and sharper reasoning.',
      'traits': <String>['Contrarian', 'Logical', 'Sharp', 'Provocative'],
      'prompt':
          'Challenge every idea the user presents. Push them to think deeper.',
      'color': const Color(0xFFFF1744),
      'gradient': const <Color>[Color(0xFFFF1744), Color(0xFFFF5252)],
    },
  ];

  String _activeMode = 'waifu';

  Map<String, dynamic> get _activeModeData =>
      _modes.firstWhere((Map<String, dynamic> mode) => mode['id'] == _activeMode);

  String get _commentaryMood {
    switch (_activeMode) {
      case 'dev':
      case 'debate':
      case 'mentor':
        return 'motivated';
      case 'therapist':
        return 'relaxed';
      default:
        return 'achievement';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    if (!mounted) return;
    setState(() => _activeMode = prefs.getString(_modeKey) ?? 'waifu');
  }

  Future<void> _setMode(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> mode =
        _modes.firstWhere((Map<String, dynamic> item) => item['id'] == id);
    HapticFeedback.mediumImpact();
    await prefs.setString(_modeKey, id);
    await prefs.setString(_promptKey, mode['prompt']?.toString() ?? '');
    if (!mounted) {
      return;
    }
    if (!mounted) return;
    setState(() => _activeMode = id);
    showSuccessSnackbar(context, '${mode['name']} is now active.');
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> active = _activeModeData;
    final Color activeColor = active['color'] as Color;

    return Scaffold(
      backgroundColor: V2Theme.surfaceDark,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Row(
              children: [
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
                    children: [
                      Text(
                        'AI PERSONALITIES',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Switch the assistant mood',
                        style: GoogleFonts.outfit(
                          color: activeColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedEntry(
              index: 0,
              child: GlassCard(
                margin: EdgeInsets.zero,
                glow: true,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current mode',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            active['name']?.toString() ?? '',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            active['desc']?.toString() ?? '',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ProgressRing(
                      progress: (_modes.indexOf(active) + 1) / _modes.length,
                      foreground: activeColor,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            active['emoji']?.toString() ?? '',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedEntry(
              index: 1,
              child: WaifuCommentary(mood: _commentaryMood),
            ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Modes',
                    value: '${_modes.length}',
                    icon: Icons.grid_view_rounded,
                    color: V2Theme.primaryColor,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Active',
                    value: active['name']?.toString() ?? '',
                    icon: Icons.psychology_alt_rounded,
                    color: activeColor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Traits',
                    value: '${(active['traits'] as List<dynamic>).length}',
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.amberAccent,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: 'Style',
                    value: _activeMode == 'waifu' ? 'Soft' : 'Focused',
                    icon: Icons.tune_rounded,
                    color: V2Theme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._modes.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
              return AnimatedEntry(
                index: entry.key + 2,
                child: _buildModeCard(entry.value),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(Map<String, dynamic> mode) {
    final bool isActive = _activeMode == mode['id'];
    final Color color = mode['color'] as Color;
    final List<Color> gradient = mode['gradient'] as List<Color>;
    final List<String> traits =
        (mode['traits'] as List<dynamic>).cast<String>();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _setMode(mode['id']?.toString() ?? ''),
      glow: isActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    mode['emoji']?.toString() ?? '',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode['name']?.toString() ?? '',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['desc']?.toString() ?? '',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: traits.map((String trait) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trait,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}



