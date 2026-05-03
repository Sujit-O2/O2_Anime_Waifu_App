import 'dart:async';
import 'package:flutter/foundation.dart';

/// 🎨 Dynamic Avatar Expressions Service
class AvatarExpressionService {
  AvatarExpressionService._();
  static final AvatarExpressionService instance = AvatarExpressionService._();

  AvatarExpression _currentExpression = AvatarExpression.neutral;
  Timer? _expressionTimer;

  AvatarExpression get currentExpression => _currentExpression;

  void setExpression(AvatarExpression expression, {Duration? duration, double intensity = 1.0}) {
    _currentExpression = expression;
    onExpressionChanged?.call(expression, intensity);
    
    if (duration != null) {
      _expressionTimer?.cancel();
      _expressionTimer = Timer(duration, () => setExpression(AvatarExpression.neutral));
    }
    
    if (kDebugMode) debugPrint('[Avatar] Expression: ${expression.label} (intensity: $intensity)');
  }

  void setExpressionFromEmotion(String emotion) {
    final lower = emotion.toLowerCase();
    if (lower.contains('love') || lower.contains('adore')) {
      setExpression(AvatarExpression.loving, duration: const Duration(seconds: 3));
    } else if (lower.contains('happy') || lower.contains('joy')) {
      setExpression(AvatarExpression.happy, duration: const Duration(seconds: 3));
    } else if (lower.contains('sad') || lower.contains('cry')) {
      setExpression(AvatarExpression.sad, duration: const Duration(seconds: 4));
    } else if (lower.contains('angry') || lower.contains('mad')) {
      setExpression(AvatarExpression.angry, duration: const Duration(seconds: 3));
    } else if (lower.contains('surprise') || lower.contains('wow')) {
      setExpression(AvatarExpression.surprised, duration: const Duration(seconds: 2));
    } else if (lower.contains('playful') || lower.contains('tease')) {
      setExpression(AvatarExpression.playful, duration: const Duration(seconds: 3));
    }
  }

  void Function(AvatarExpression, double)? onExpressionChanged;

  void dispose() => _expressionTimer?.cancel();
}

enum AvatarExpression {
  neutral, happy, sad, angry, surprised, loving, playful, shy, excited, worried, sleepy, thinking;

  String get label {
    switch (this) {
      case AvatarExpression.neutral: return 'Neutral';
      case AvatarExpression.happy: return 'Happy';
      case AvatarExpression.sad: return 'Sad';
      case AvatarExpression.angry: return 'Angry';
      case AvatarExpression.surprised: return 'Surprised';
      case AvatarExpression.loving: return 'Loving';
      case AvatarExpression.playful: return 'Playful';
      case AvatarExpression.shy: return 'Shy';
      case AvatarExpression.excited: return 'Excited';
      case AvatarExpression.worried: return 'Worried';
      case AvatarExpression.sleepy: return 'Sleepy';
      case AvatarExpression.thinking: return 'Thinking';
    }
  }

  String get assetPath {
    switch (this) {
      case AvatarExpression.loving:
      case AvatarExpression.happy:
      case AvatarExpression.excited:
        return 'assets/img/z2s.jpg';
      case AvatarExpression.sad:
      case AvatarExpression.worried:
      case AvatarExpression.sleepy:
        return 'assets/img/bll.jpg';
      default:
        return 'assets/img/front.png';
    }
  }
}
