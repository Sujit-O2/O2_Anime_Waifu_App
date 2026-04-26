import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Anime Sticker Sheet Page
///
/// Premium animated sticker reaction sheet with haptic feedback and spring animations.
/// Replaces plain emoji picker in chat with categorized anime-style stickers.
/// ─────────────────────────────────────────────────────────────────────────────
class AnimeStickerSheet extends StatefulWidget {
  const AnimeStickerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AnimeStickerSheet(),
    );
  }

  static const Map<String, List<String>> _stickerCategories = {
    'Emotions': [
      '😊',
      '🥺',
      '😢',
      '😤',
      '😍',
      '🤔',
      '😴',
      '🥰',
      '😎',
      '😅',
      '🤗',
      '😇',
      '🙄',
      '😌',
      '🤤',
      '😳'
    ],
    'Reactions': [
      '❤️',
      '💔',
      '🔥',
      '✨',
      '💫',
      '🌟',
      '💥',
      '💯',
      '👍',
      '👎',
      '👏',
      '🙌',
      '🤝',
      '✌️',
      '👌',
      '🤞'
    ],
    'Chibi': [
      '👶',
      '🧒',
      '👦',
      '👧',
      '🧑',
      '👨',
      '👩',
      '🧓',
      '👴',
      '👵',
      '🧑‍💼',
      '👨‍💼',
      '👩‍💼',
      '🧑‍🎓',
      '👨‍🎓',
      '👩‍🎓'
    ],
    'Anime': [
      '🎌',
      '🍜',
      '🍣',
      '🍱',
      '🎋',
      '🌸',
      '🌺',
      '🍡',
      '🎎',
      '🎏',
      '🗾',
      '🏯',
      '🎴',
      '🎭',
      '🎪',
      '🎨'
    ],
  };

  @override
  State<AnimeStickerSheet> createState() => _AnimeStickerSheetState();
}

class _AnimeStickerSheetState extends State<AnimeStickerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  String _selectedCategory = 'Emotions';
  final Map<String, bool> _pressedStates = {};

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onStickerTap(String sticker) {
    HapticFeedback.mediumImpact();
    setState(() => _pressedStates[sticker] = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _pressedStates[sticker] = false);
    });
    Navigator.pop(context, sticker);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final slideUp = Curves.easeOut.transform(_ctrl.value);
        return Transform.translate(
          offset: Offset(0, (1 - slideUp) * 300),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Color(0xFF12101E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Choose Sticker',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white38),
                      ),
                    ],
                  ),
                ),

                // Category tabs
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: AnimeStickerSheet._stickerCategories.keys
                        .map((category) {
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purpleAccent.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.purpleAccent
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.outfit(
                              color: isSelected
                                  ? Colors.purpleAccent
                                  : Colors.white70,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Stickers grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: AnimeStickerSheet
                              ._stickerCategories[_selectedCategory]?.length ??
                          0,
                      itemBuilder: (context, index) {
                        final sticker = AnimeStickerSheet
                            ._stickerCategories[_selectedCategory]![index];
                        final isPressed = _pressedStates[sticker] ?? false;

                        return GestureDetector(
                          onTap: () => _onStickerTap(sticker),
                          child: AnimatedScale(
                            scale: isPressed ? 0.8 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.elasticOut,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Center(
                                child: Text(
                                  sticker,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
