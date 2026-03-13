import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Provides short sound-effect feedback for game interactions.
/// Uses HapticFeedback as primary, AudioPlayer as secondary.
class GameSoundsService {
  GameSoundsService._();
  static final GameSoundsService instance = GameSoundsService._();

  // Frequencies for synthesized tones (haptic as fallback)
  Future<void> playTap() async {
    await HapticFeedback.lightImpact();
    _tryPlay('tap');
  }

  Future<void> playCorrect() async {
    await HapticFeedback.mediumImpact();
    _tryPlay('correct');
  }

  Future<void> playWrong() async {
    await HapticFeedback.heavyImpact();
    _tryPlay('wrong');
  }

  Future<void> playSpin() async {
    await HapticFeedback.selectionClick();
    _tryPlay('spin');
  }

  Future<void> playReveal() async {
    await HapticFeedback.mediumImpact();
    _tryPlay('reveal');
  }

  Future<void> _tryPlay(String name) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/$name.mp3'));
    } catch (_) {
      // No asset — haptic feedback already played, ignore silently
    }
  }
}
