/// Application-wide constants
/// Centralizes all magic strings and configuration values
library;

// ═══════════════════════════════════════════════════════════════════════════
// SHARED PREFERENCES KEYS
// ═══════════════════════════════════════════════════════════════════════════

class PrefsKeys {
  // Wake Word & Voice
  static const String wakeWordEnabled = 'wake_word_enabled';
  static const String voiceModel = 'voice_model';
  static const String sttProvider = 'stt_provider';
  static const String sttLangOverride = 'dev_stt_lang_override';
  static const String sttTimeoutOverride = 'dev_stt_timeout_override';

  // Timers & Intervals
  static const String idleTimerEnabled = 'idle_timer_enabled';
  static const String idleDurationSeconds = 'idle_duration_seconds';
  static const String proactiveIntervalSeconds = 'proactive_interval_seconds';
  static const String proactiveRandomEnabled = 'proactive_random_enabled';
  static const String proactiveEnabled = 'proactive_enabled';

  // Assistant Mode
  static const String assistantModeEnabled = 'assistant_mode_enabled';

  // Persona & AI
  static const String selectedPersona = 'selected_persona_v1';
  static const String sleepModeEnabled = 'sleep_mode_enabled_v1';
  static const String lastSummaryDate = 'last_summary_date_v1';

  // UI Settings
  static const String appThemeIndex = 'app_theme_index';
  static const String themeAccentColor = 'flutter.theme_accent_color';
  static const String customBgUrl = 'flutter.custom_bg_url';
  static const String showTimestamps = 'flutter.show_timestamps';
  static const String hapticFeedback = 'flutter.haptic_feedback';
  static const String wakePopupEnabled = 'flutter.wake_popup_enabled';
  static const String soundOnWake = 'flutter.sound_on_wake';
  static const String showChatHint = 'flutter.show_chat_hint';
  static const String wallpaperBrightness = 'flutter.wallpaper_brightness';
  static const String responseLengthMode = 'flutter.response_length_mode';
  static const String chatTextSize = 'flutter.chat_text_size';
  static const String autoScrollChat = 'flutter.auto_scroll_chat';
  static const String ttsSpeed = 'flutter.tts_speed';

  // Dual Voice
  static const String dualVoiceEnabled = 'dual_voice_enabled_v1';
  static const String dualVoiceSecondary = 'dual_voice_secondary_v1';
  static const String dualVoiceTurn = 'dual_voice_turn_v1';

  // Advanced Settings
  static const String liteModeEnabled = 'lite_mode_enabled_v1';
  static const String appLockEnabled = 'app_lock_enabled';
  static const String advancedMemoryLimit = 'flutter.advanced_memory_limit';
  static const String advancedDebugLogs = 'flutter.advanced_debug_logs';
  static const String advancedStrictWake = 'flutter.advanced_strict_wake';

  // Custom Images
  static const String chatImageAsset = 'flutter.chat_image_asset';
  static const String chatImageFromSystem = 'flutter.chat_image_from_system';
  static const String chatImageCustomPath = 'flutter.chat_image_custom_path';
  static const String appIconImageAsset = 'flutter.app_icon_image_asset';
  static const String appIconFromCustom = 'flutter.app_icon_from_custom';
  static const String appIconCustomPath = 'flutter.app_icon_custom_path';

  // Developer Overrides
  static const String devApiKeyOverride = 'dev_api_key_override';
  static const String devModelOverride = 'dev_model_override';
  static const String devApiUrlOverride = 'dev_api_url_override';
  static const String devSystemQuery = 'dev_system_query';
  static const String devWakeKeyOverride = 'dev_wake_key_override';
  static const String devTtsApiKeyOverride = 'dev_tts_api_key_override';
  static const String devTtsModelOverride = 'dev_tts_model_override';
  static const String devTtsVoiceOverride = 'dev_tts_voice_override';
  static const String devBrevoApiKeyOverride = 'dev_brevo_api_key_override';

  // Memory & Consolidation
  static const String lastConsolidationMs = 'last_consolidation_ms';
  static const String pendingProactiveMessages = 'pending_proactive_messages';

  // Alarm
  static const String alarmTriggered = 'alarm_triggered';

  // AI Personality
  static const String aiPersonalityPrompt = 'ai_personality_prompt';
  static const String autoLearningPrefs = 'auto_learning_prefs';

  // Memory Architecture
  static const String memoryStackData = 'memory_stack_data';
  static const String knowledgeGraphData = 'knowledge_graph_data';
}

// ═══════════════════════════════════════════════════════════════════════════
// API & NETWORK
// ═══════════════════════════════════════════════════════════════════════════

class ApiConfig {
  static const Duration chatTimeout = Duration(seconds: 25);
  static const Duration mailTimeout = Duration(seconds: 20);
  static const Duration sttTimeout = Duration(seconds: 10);
  static const Duration wakeVerificationTimeout = Duration(seconds: 6);

  static const String defaultApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String defaultModel =
      'meta-llama/llama-4-scout-17b-16e-instruct';
  static const String brevoApiUrl = 'https://api.brevo.com/v3/smtp/email';
  static const String openWeatherApiUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String safebooruApiUrl = 'https://safebooru.org/index.php';

  // Fallback models for retry logic
  static const List<String> fallbackModels = [
    'meta-llama/llama-4-scout-17b-16e-instruct',
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// APP LIMITS & THRESHOLDS
// ═══════════════════════════════════════════════════════════════════════════

class AppLimits {
  static const int maxConversationMessages = 50;
  static const int maxPayloadMessages = 20;
  static const int maxMemoryMessages = 15;
  static const int maxScheduledMsgCacheSize = 1000; // Clear after this

  // Achievement thresholds
  static const int achievement100Points = 100;
  static const int achievement500Points = 500;
  static const int achievement1000Points = 1000;
  static const int achievementPointTolerance = 5; // Allow ±5 points

  // Wake word
  static const Duration wakeDetectCooldown = Duration(seconds: 4);

// Proactive intervals (seconds)
  static const List<int> proactiveRandomIntervals = [
    2700, // 45m
    5400, // 1.5h
    10800, // 3h
    18000, // 5h
    28800, // 8h
  ];

  // Pagination
  static const int pageSize = 20;
}

// ═══════════════════════════════════════════════════════════════════════════
// SECURITY
// ═══════════════════════════════════════════════════════════════════════════

class SecurityConfig {
  // DO NOT use this in production - derive from user password
  static const String vaultEncryptionKey = 'anime-waifu-vault-key-2026';

  // Audit events
  static const String auditPinSet = 'pin_set';
  static const String auditPinVerifyFailed = 'pin_verification_failed';
  static const String auditPinVerifyError = 'pin_verification_error';
  static const String auditNoteCreated = 'secret_note_created';
  static const String auditNoteDeleted = 'secret_note_deleted';
  static const String auditNotesCleared = 'secret_notes_cleared';
  static const String auditAccountDeleted = 'account_deleted';
}

// ═══════════════════════════════════════════════════════════════════════════
// DEFAULT VALUES
// ═══════════════════════════════════════════════════════════════════════════

class Defaults {
  static const String defaultEmail =
      'sujitswain077@gmail.com'; // Replace hardcoded email
  static const String defaultSenderEmail =
      'zerozerotwoxsujit@gmail.com'; // Fallback — overridden by SENDER_EMAIL in .env
  static const String defaultCity = 'Bhubaneswar';
  static const String defaultPersona = 'Default';
  static const String defaultVoiceModel = 'arabic';
  static const String defaultSttProvider = 'groq';

  static const int defaultIdleDurationSeconds = 600; // 10 min
  static const int defaultProactiveIntervalSeconds = 1800; // 30 min
  static const double defaultTtsSpeed = 1.0;
  static const double defaultWallpaperBrightness = 0.5;
}

// ═══════════════════════════════════════════════════════════════════════════
// FIRESTORE COLLECTIONS
// ═══════════════════════════════════════════════════════════════════════════

class FirestoreCollections {
  static const String chats = 'chats';
  static const String profiles = 'profiles';
  static const String vault = 'vault';
  static const String memory = 'memory';
  static const String quests = 'quests';
  static const String mood = 'mood';
  static const String settings = 'settings';
  static const String alarm = 'alarm';
  static const String scores = 'scores';
  static const String achievements = 'achievements';
  static const String affection = 'affection';
  static const String analyticsEvents = 'analytics_events';
  static const String crashReports = 'crash_reports';
  static const String voiceCommandHistory = 'voice_command_history';
  static const String activityFeed = 'activity_feed';
  static const String offlineSessions = 'offline_sessions';
  static const String pendingOperations = 'pending_operations';
  static const String adminLogs = 'admin_logs';
}

// ═══════════════════════════════════════════════════════════════════════════
// REGEX PATTERNS
// ═══════════════════════════════════════════════════════════════════════════

class RegexPatterns {
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String passwordRegex =
      r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$';
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';
  static const String phoneRegex = r'^\+?[\d\s-]{10,}$';
  static const String urlRegex = r'^https?:\/\/[\w\-]+(\.[\w\-]+)+[/#?]?.*$';
}

// ═══════════════════════════════════════════════════════════════════════════
// APPEARANCE CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════

class AppearanceConstants {
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
