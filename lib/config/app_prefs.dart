/// Centralised SharedPreferences key registry.
/// Use these constants everywhere instead of raw strings.
class AppPrefs {
  AppPrefs._();

  // ── Theme ─────────────────────────────────────────────────────────────────
  static const String themeIndex = 'app_theme_index';
  static const String accentColor = 'flutter.theme_accent_color';
  static const String customBgUrl = 'flutter.custom_bg_url';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const String showTimestamps = 'show_msg_timestamps_v1';
  static const String hapticFeedback = 'haptic_feedback_v1';
  static const String wakePopupEnabled = 'wake_popup_enabled';
  static const String responseLengthMode = 'response_length_mode_v1';
  static const String chatTextSize = 'chat_text_size_v1';
  static const String autoScrollChat = 'auto_scroll_chat_v1';
  static const String ttsSpeed = 'tts_speed_v1';
  static const String soundOnWake = 'sound_on_wake_v1';
  static const String showChatHint = 'show_chat_hint_v1';
  static const String wallpaperBrightness = 'wallpaper_brightness_v1';

  // ── Persona & Features ────────────────────────────────────────────────────
  static const String selectedPersona = 'selected_persona_v1';
  static const String sleepModeEnabled = 'sleep_mode_enabled_v1';
  static const String lastSummaryDate = 'last_summary_date_v1';
  static const String outfit = 'flutter.outfit_v1';
  static const String customChatImagePath = 'custom_chat_image_path_v1';
  static const String chatImageFromSystem = 'chat_image_from_system_v1';
  static const String customAppIconPath = 'custom_app_icon_path_v1';
  static const String appIconFromCustom = 'app_icon_from_custom_v1';

  // ── Voice ─────────────────────────────────────────────────────────────────
  static const String dualVoiceEnabled = 'dual_voice_enabled_v1';
  static const String dualVoiceSecondary = 'dual_voice_secondary_v1';
  static const String liteModeEnabled = 'lite_mode_enabled_v1';
  static const String appLockEnabled = 'app_lock_enabled';

  // ── Manga ─────────────────────────────────────────────────────────────────
  static const String mangaReadingList = 'manga_reading_list_v1';
  static const String mangaDataSaver = 'manga_data_saver_v1';
  static const String mangaReadingDirection = 'manga_reading_direction_v1';

  // ── Gamification ─────────────────────────────────────────────────────────
  static const String lastDailyBonusDate = 'last_daily_bonus_date_v1';
  static const String totalXp = 'total_xp_v1';
}


