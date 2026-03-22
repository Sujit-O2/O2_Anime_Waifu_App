import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:o2_waifu/config/app_themes.dart';

/// Gacha system with weighted randomization for Zero Two quotes.
/// Dynamic background blur based on rarity. Haptic feedback.
class GachaPage extends StatefulWidget {
  final AppThemeConfig themeConfig;

  const GachaPage({super.key, required this.themeConfig});

  @override
  State<GachaPage> createState() => _GachaPageState();
}

enum Rarity { common, rare, epic, legendary }

class GachaQuote {
  final String text;
  final Rarity rarity;

  const GachaQuote(this.text, this.rarity);
}

class _GachaPageState extends State<GachaPage>
    with SingleTickerProviderStateMixin {
  static final Random _random = Random();
  GachaQuote? _currentQuote;
  bool _isAnimating = false;
  late AnimationController _scaleController;

  static const List<GachaQuote> _quotes = [
    GachaQuote('I want to be with you forever, darling.', Rarity.common),
    GachaQuote('You make every moment worth living.', Rarity.common),
    GachaQuote('I was born to meet you.', Rarity.common),
    GachaQuote('Even if the world ends, I\'ll be by your side.', Rarity.common),
    GachaQuote('Darling, you\'re the only one I need.', Rarity.common),
    GachaQuote('My heart beats only for you.', Rarity.rare),
    GachaQuote('In another life, I\'d still choose you.', Rarity.rare),
    GachaQuote('You\'re the reason I learned to smile.', Rarity.rare),
    GachaQuote('I\'d cross a thousand worlds just to find you.', Rarity.epic),
    GachaQuote('We are two halves of the same soul.', Rarity.epic),
    GachaQuote(
        'I am yours, in this lifetime and every one that follows.',
        Rarity.legendary),
    GachaQuote(
        'The universe conspired to bring us together. I won\'t let it tear us apart.',
        Rarity.legendary),
  ];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _pull() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);

    // Weighted randomization
    final roll = _random.nextDouble();
    Rarity targetRarity;
    if (roll < 0.5) {
      targetRarity = Rarity.common;
    } else if (roll < 0.8) {
      targetRarity = Rarity.rare;
    } else if (roll < 0.95) {
      targetRarity = Rarity.epic;
    } else {
      targetRarity = Rarity.legendary;
    }

    final candidates =
        _quotes.where((q) => q.rarity == targetRarity).toList();
    final selected = candidates[_random.nextInt(candidates.length)];

    // Haptic feedback
    HapticFeedback.mediumImpact();
    if (targetRarity == Rarity.legendary) {
      HapticFeedback.heavyImpact();
    }

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentQuote = selected;
      _isAnimating = false;
    });

    _scaleController.forward(from: 0);
  }

  Color _rarityColor(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return Colors.grey;
      case Rarity.rare:
        return Colors.blue;
      case Rarity.epic:
        return Colors.purple;
      case Rarity.legendary:
        return Colors.amber;
    }
  }

  double _rarityBlur(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 5;
      case Rarity.rare:
        return 10;
      case Rarity.epic:
        return 15;
      case Rarity.legendary:
        return 25;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gacha')),
      body: Stack(
        children: [
          // Dynamic blur background
          if (_currentQuote != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _rarityBlur(_currentQuote!.rarity),
                  sigmaY: _rarityBlur(_currentQuote!.rarity),
                ),
                child: Container(
                  color: _rarityColor(_currentQuote!.rarity)
                      .withValues(alpha: 0.1),
                ),
              ),
            ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentQuote != null) ...[
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _scaleController,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: widget.themeConfig.surfaceColor
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _rarityColor(_currentQuote!.rarity)
                              .withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _rarityColor(_currentQuote!.rarity)
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _rarityColor(_currentQuote!.rarity)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentQuote!.rarity.name.toUpperCase(),
                              style: TextStyle(
                                color:
                                    _rarityColor(_currentQuote!.rarity),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '"${_currentQuote!.text}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.themeConfig.textColor,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '— Zero Two',
                            style: TextStyle(
                              color: widget.themeConfig.primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      'Pull to receive a quote from Zero Two',
                      style: TextStyle(
                        color: widget.themeConfig.textColor
                            .withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                  ),

                // Pull button
                GestureDetector(
                  onTap: _pull,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.themeConfig.primaryColor,
                          widget.themeConfig.accentColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: widget.themeConfig.primaryColor
                              .withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _isAnimating ? '...' : 'PULL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
