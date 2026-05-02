import 'dart:async';
import 'package:flutter/foundation.dart';

/// 💬 Conversation Themes/Modes Service
class ConversationModeService {
  ConversationModeService._();
  static final ConversationModeService instance = ConversationModeService._();

  ConversationMode _currentMode = ConversationMode.romantic;
  Timer? _modeTimer;

  ConversationMode get currentMode => _currentMode;

  void setMode(ConversationMode mode, {Duration? duration}) {
    _currentMode = mode;
    onModeChanged?.call(mode);
    
    if (duration != null) {
      _modeTimer?.cancel();
      _modeTimer = Timer(duration, () => setMode(ConversationMode.romantic));
    }
    
    if (kDebugMode) debugPrint('[ConversationMode] Mode: ${mode.label}');
  }

  String getSystemPromptModifier() {
    switch (_currentMode) {
      case ConversationMode.romantic:
        return 'Be loving, affectionate, and romantic. Use terms of endearment like "darling". Express your feelings openly.';
      case ConversationMode.professional:
        return 'Be professional, helpful, and focused. Provide clear, concise information. Maintain a respectful tone.';
      case ConversationMode.playful:
        return 'Be fun, teasing, and playful. Use humor and light-hearted banter. Keep things entertaining.';
      case ConversationMode.therapist:
        return 'Be empathetic, supportive, and understanding. Listen actively. Ask thoughtful questions. Provide emotional support without judgment.';
      case ConversationMode.mentor:
        return 'Be wise, encouraging, and motivational. Share insights and guidance. Help them grow and learn.';
      case ConversationMode.friend:
        return 'Be casual, supportive, and genuine. Talk like a close friend. Be there for them without being overly romantic.';
    }
  }

  String getModeDescription() {
    switch (_currentMode) {
      case ConversationMode.romantic:
        return 'Loving and affectionate girlfriend mode 💕';
      case ConversationMode.professional:
        return 'Professional assistant mode 💼';
      case ConversationMode.playful:
        return 'Fun and teasing mode 😄';
      case ConversationMode.therapist:
        return 'Supportive counselor mode 🤗';
      case ConversationMode.mentor:
        return 'Wise mentor mode 🎓';
      case ConversationMode.friend:
        return 'Best friend mode 👯';
    }
  }

  String getModeDescriptionFor(ConversationMode mode) {
    switch (mode) {
      case ConversationMode.romantic:
        return 'Loving and affectionate girlfriend mode 💕';
      case ConversationMode.professional:
        return 'Professional assistant mode 💼';
      case ConversationMode.playful:
        return 'Fun and teasing mode 😄';
      case ConversationMode.therapist:
        return 'Supportive counselor mode 🤗';
      case ConversationMode.mentor:
        return 'Wise mentor mode 🎓';
      case ConversationMode.friend:
        return 'Best friend mode 👯';
    }
  }

  void Function(ConversationMode)? onModeChanged;

  void dispose() => _modeTimer?.cancel();
}

enum ConversationMode {
  romantic, professional, playful, therapist, mentor, friend;

  String get label {
    switch (this) {
      case ConversationMode.romantic: return 'Romantic';
      case ConversationMode.professional: return 'Professional';
      case ConversationMode.playful: return 'Playful';
      case ConversationMode.therapist: return 'Therapist';
      case ConversationMode.mentor: return 'Mentor';
      case ConversationMode.friend: return 'Friend';
    }
  }

  String get emoji {
    switch (this) {
      case ConversationMode.romantic: return '💕';
      case ConversationMode.professional: return '💼';
      case ConversationMode.playful: return '😄';
      case ConversationMode.therapist: return '🤗';
      case ConversationMode.mentor: return '🎓';
      case ConversationMode.friend: return '👯';
    }
  }
}
