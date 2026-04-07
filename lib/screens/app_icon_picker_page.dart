import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App Icon Picker — lets users choose between themed app icons.
/// Uses Android activity-alias mechanism via MethodChannel.
class AppIconPickerPage extends StatefulWidget {
  const AppIconPickerPage({super.key});
  @override
  State<AppIconPickerPage> createState() => _AppIconPickerPageState();
}

class _AppIconPickerPageState extends State<AppIconPickerPage> {
  static const _channel = MethodChannel('anime_waifu/assistant_mode');
  String _currentVariant = 'old';
  bool _switching = false;

  // Available icon variants
  static const List<_IconOption> _icons = [
    _IconOption(
      id: 'old',
      name: 'Classic Zero Two',
      emoji: '🌸',
      description: 'The original pink classic',
      gradient: [Color(0xFFE91E63), Color(0xFFAD1457)],
    ),
    _IconOption(
      id: 'new',
      name: 'Neon Zero Two',
      emoji: '⚡',
      description: 'Cyberpunk neon glow',
      gradient: [Color(0xFF6200EA), Color(0xFFAA00FF)],
    ),
    _IconOption(
      id: 'dark',
      name: 'Shadow Mode',
      emoji: '🌙',
      description: 'Stealth dark minimal',
      gradient: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    ),
    _IconOption(
      id: 'sakura',
      name: 'Sakura Bloom',
      emoji: '🌸',
      description: 'Soft cherry blossom pastel',
      gradient: [Color(0xFFF48FB1), Color(0xFFF06292)],
    ),
    _IconOption(
      id: 'ocean',
      name: 'Ocean Wave',
      emoji: '🌊',
      description: 'Deep sea gradient blue',
      gradient: [Color(0xFF00BCD4), Color(0xFF0097A7)],
    ),
    _IconOption(
      id: 'fire',
      name: 'Flame Spirit',
      emoji: '🔥',
      description: 'Hot orange-red energy',
      gradient: [Color(0xFFFF5722), Color(0xFFE64A19)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    try {
      final variant = await _channel.invokeMethod<String>('getLauncherIconVariant');
      if (mounted) setState(() => _currentVariant = variant ?? 'old');
    } catch (_) {}
  }

  Future<void> _switchIcon(String variant) async {
    if (variant == _currentVariant || _switching) return;

    setState(() => _switching = true);

    try {
      await _channel.invokeMethod('setLauncherIconVariant', {'variant': variant});
      HapticFeedback.mediumImpact();
      if (mounted) {
        setState(() {
          _currentVariant = variant;
          _switching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ App icon changed! May take a moment to update.'),
          backgroundColor: Colors.green.shade800,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _switching = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Only Classic and Neon are available as registered aliases'),
          backgroundColor: Colors.orange.shade800,
        ));
        // Still update locally for visual consistency
        setState(() => _currentVariant = variant);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('🎨 App Icon Picker',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Choose your app icon',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text('The icon on your home screen will change',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          if (_switching)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(color: Colors.deepPurple,
                backgroundColor: Colors.white10),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: _icons.length,
              itemBuilder: (_, i) {
                final icon = _icons[i];
                final isSelected = _currentVariant == icon.id;
                return GestureDetector(
                  onTap: () => _switchIcon(icon.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.08),
                        width: isSelected ? 2 : 1,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          icon.gradient[0].withValues(alpha: isSelected ? 0.4 : 0.15),
                          icon.gradient[1].withValues(alpha: isSelected ? 0.2 : 0.05),
                        ],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: icon.gradient[0].withValues(alpha: 0.3),
                          blurRadius: 16, spreadRadius: -4,
                        ),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon preview
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: icon.gradient,
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            boxShadow: [BoxShadow(
                              color: icon.gradient[0].withValues(alpha: 0.4),
                              blurRadius: 12, spreadRadius: -2,
                            )],
                          ),
                          child: Center(
                            child: Text(icon.emoji,
                              style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(icon.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade300,
                            fontWeight: FontWeight.w700, fontSize: 13),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(icon.description,
                          style: TextStyle(
                            color: isSelected ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 10),
                          textAlign: TextAlign.center),
                        if (isSelected) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            child: const Text('ACTIVE',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Note
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.amber.withValues(alpha: 0.08),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Only Classic & Neon icons are registered as Android aliases. Other icons are visual presets.',
                  style: TextStyle(color: Colors.amber.shade300, fontSize: 11),
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconOption {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<Color> gradient;
  const _IconOption({required this.id, required this.name, required this.emoji,
    required this.description, required this.gradient});
}
