import 'package:flutter/foundation.dart';

/// 🌐 Multi-Language Support Service
class MultiLanguageService {
  MultiLanguageService._();
  static final MultiLanguageService instance = MultiLanguageService._();

  LanguageCode _currentLanguage = LanguageCode.english;

  LanguageCode get currentLanguage => _currentLanguage;

  LanguageCode detectLanguage(String text) {
    final lower = text.toLowerCase();
    
    if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text)) return LanguageCode.japanese;
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(text)) return LanguageCode.chinese;
    if (RegExp(r'[\uAC00-\uD7AF]').hasMatch(text)) return LanguageCode.korean;
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) return LanguageCode.arabic;
    if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) return LanguageCode.russian;
    
    if (lower.contains(RegExp(r'\b(bonjour|merci|oui|non)\b'))) return LanguageCode.french;
    if (lower.contains(RegExp(r'\b(hola|gracias|si|no)\b'))) return LanguageCode.spanish;
    if (lower.contains(RegExp(r'\b(hallo|danke|ja|nein)\b'))) return LanguageCode.german;
    if (lower.contains(RegExp(r'\b(ciao|grazie|si|no)\b'))) return LanguageCode.italian;
    if (lower.contains(RegExp(r'\b(olá|obrigado|sim|não)\b'))) return LanguageCode.portuguese;
    
    return LanguageCode.english;
  }

  void setLanguage(LanguageCode language) {
    _currentLanguage = language;
    if (kDebugMode) debugPrint('[MultiLang] Language set to: ${language.label}');
  }

  String getSystemPromptModifier(LanguageCode language) {
    switch (language) {
      case LanguageCode.japanese: return 'Respond in Japanese. Use casual/friendly tone (タメ口).';
      case LanguageCode.chinese: return 'Respond in Simplified Chinese. Use friendly tone.';
      case LanguageCode.korean: return 'Respond in Korean. Use casual/friendly tone (반말).';
      case LanguageCode.spanish: return 'Respond in Spanish. Use informal "tú" form.';
      case LanguageCode.french: return 'Respond in French. Use informal "tu" form.';
      case LanguageCode.german: return 'Respond in German. Use informal "du" form.';
      case LanguageCode.italian: return 'Respond in Italian. Use informal "tu" form.';
      case LanguageCode.portuguese: return 'Respond in Portuguese. Use informal "você" form.';
      case LanguageCode.russian: return 'Respond in Russian. Use informal "ты" form.';
      case LanguageCode.arabic: return 'Respond in Arabic. Use friendly tone.';
      default: return 'Respond in English.';
    }
  }
}

enum LanguageCode {
  english, japanese, chinese, korean, spanish, french, german, italian, portuguese, russian, arabic;

  String get label {
    switch (this) {
      case LanguageCode.english: return 'English';
      case LanguageCode.japanese: return '日本語';
      case LanguageCode.chinese: return '中文';
      case LanguageCode.korean: return '한국어';
      case LanguageCode.spanish: return 'Español';
      case LanguageCode.french: return 'Français';
      case LanguageCode.german: return 'Deutsch';
      case LanguageCode.italian: return 'Italiano';
      case LanguageCode.portuguese: return 'Português';
      case LanguageCode.russian: return 'Русский';
      case LanguageCode.arabic: return 'العربية';
    }
  }

  String get code {
    switch (this) {
      case LanguageCode.english: return 'en';
      case LanguageCode.japanese: return 'ja';
      case LanguageCode.chinese: return 'zh';
      case LanguageCode.korean: return 'ko';
      case LanguageCode.spanish: return 'es';
      case LanguageCode.french: return 'fr';
      case LanguageCode.german: return 'de';
      case LanguageCode.italian: return 'it';
      case LanguageCode.portuguese: return 'pt';
      case LanguageCode.russian: return 'ru';
      case LanguageCode.arabic: return 'ar';
    }
  }
}
