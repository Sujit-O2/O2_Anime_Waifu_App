import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:anime_waifu/services/assistant_mode_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SettingsProvider
///
/// Extracted from _ChatHomePageState. Manages ALL user preferences including:
/// • UI settings (timestamps, haptic, chat text size, etc.)
/// • Voice model and TTS settings
/// • Outfit/wallpaper/custom images
/// • Dev config overrides (API keys, model, URL)
/// • Assistant mode toggles (proactive, random, etc.)
/// ─────────────────────────────────────────────────────────────────────────────
class SettingsProvider extends ChangeNotifier {
  // ── Pref keys ───────────────────────────────────────────────────────────
  static const String _showTimestampsPrefKey = 'show_msg_timestamps_v1';
  static const String _hapticFeedbackPrefKey = 'haptic_feedback_v1';
  static const String _wakePopupPrefKey = 'wake_popup_enabled';
  static const String _responseLengthPrefKey = 'response_length_mode_v1';
  static const String _chatTextSizePrefKey = 'chat_text_size_v1';
  static const String _autoScrollChatPrefKey = 'auto_scroll_chat_v1';
  static const String _ttsSpeedPrefKey = 'tts_speed_v1';
  static const String _soundOnWakePrefKey = 'sound_on_wake_v1';
  static const String _showChatHintPrefKey = 'show_chat_hint_v1';
  static const String _wallpaperBrightnessPrefKey = 'wallpaper_brightness_v1';
  static const String _outfitPrefKey = 'flutter.outfit_v1';
  static const String _customChatImagePathPrefKey = 'custom_chat_image_path_v1';
  static const String _chatImageFromSystemPrefKey = 'chat_image_from_system_v1';
  static const String _customAppIconPathPrefKey = 'custom_app_icon_path_v1';
  static const String _appIconFromCustomPrefKey = 'app_icon_from_custom_v1';
  static const String _dualVoiceEnabledPrefKey = 'dual_voice_enabled_v1';
  static const String _dualVoiceSecondaryPrefKey = 'dual_voice_secondary_v1';
  static const String _liteModeEnabledPrefKey = 'lite_mode_enabled_v1';
  static const String _appLockEnabledPrefKey = 'app_lock_enabled';

  // ── UI Settings ─────────────────────────────────────────────────────────
  bool showMessageTimestamps = false;
  bool hapticFeedbackEnabled = true;
  bool wakePopupEnabled = true;
  bool soundOnWake = true;
  bool showChatHint = true;
  double wallpaperBrightness = 0.5;
  String responseLengthMode = 'Normal';
  String chatTextSize = 'Medium';
  bool autoScrollChat = true;
  double ttsSpeed = 1.0;
  bool liteModeEnabled = false;
  bool appLockEnabled = false;
  bool notificationsAllowed = false;

  // ── Outfit / Custom images ──────────────────────────────────────────────
  String selectedOutfit = 'assets/img/z2s.jpg';
  bool chatImageFromSystem = false;
  bool appIconFromCustom = false;
  String? customChatImagePath;
  String? customAppIconPath;

  // ── Dual Voice ──────────────────────────────────────────────────────────
  bool dualVoiceEnabled = false;
  String dualVoiceSecondary = "alloy";
  int dualVoiceTurn = 0;

  // ── Advanced ────────────────────────────────────────────────────────────
  int advancedMemoryLimit = 15;
  bool advancedDebugLogs = false;
  bool advancedStrictWake = false;

  // ── Dev Config ──────────────────────────────────────────────────────────
  String devApiKeyOverride = "";
  String devModelOverride = "";
  String devApiUrlOverride = "";
  String devSystemQuery = "";
  String devWakeKeyOverride = "";
  String devTtsApiKeyOverride = "";
  String devTtsModelOverride = "";
  String devTtsVoiceOverride = "";
  String devMailJetApiOverride = "";
  String devMailJetSecOverride = "";
  String devSttLangOverride = "";
  int devSttTimeoutOverride = 0;

  // ── Proactive / Idle Settings ───────────────────────────────────────────
  int idleDurationSeconds = 600;
  int proactiveIntervalSeconds = 60;
  bool idleTimerEnabled = true;
  bool proactiveEnabled = true;
  bool proactiveRandomEnabled = true;

  // ── Derived Getters ─────────────────────────────────────────────────────
  double get chatFontSize {
    switch (chatTextSize) {
      case 'Small':
        return 12.0;
      case 'Large':
        return 16.0;
      default:
        return 14.0;
    }
  }

  String get responseLengthInstruction {
    switch (responseLengthMode) {
      case 'Short':
        return ' Keep response under 10 words.';
      case 'Detailed':
        return ' Provide a detailed response, up to 100 words.';
      default:
        return '';
    }
  }

  String get chatImageAsset => selectedOutfit;
  String get appIconImageAsset => 'assets/img/logi.png';
  String? get effectiveChatCustomPath =>
      chatImageFromSystem ? customChatImagePath : null;
  String? get effectiveAppIconCustomPath =>
      appIconFromCustom ? customAppIconPath : null;

  Duration get idleDuration => Duration(seconds: idleDurationSeconds);
  Duration get proactiveInterval =>
      Duration(seconds: proactiveIntervalSeconds);

  String get effectiveTtsApiKey {
    if (devTtsApiKeyOverride.trim().isNotEmpty) {
      return devTtsApiKeyOverride.trim();
    }
    return dotenv.env['GROQ_API_KEY_VOICE'] ?? (dotenv.env['API_KEY'] ?? "");
  }

  String get effectiveTtsModel {
    if (devTtsModelOverride.trim().isNotEmpty) {
      return devTtsModelOverride.trim();
    }
    return "canopylabs/orpheus-arabic-saudi";
  }

  String get effectiveTtsVoice {
    if (devTtsVoiceOverride.trim().isNotEmpty) {
      return devTtsVoiceOverride.trim();
    }
    return "aisha";
  }

  ImageProvider imageProviderFor({
    required String assetPath,
    required String? customPath,
  }) {
    if (customPath != null && customPath.trim().isNotEmpty) {
      if (customPath.startsWith('assets/')) {
        return AssetImage(customPath);
      }
      final file = File(customPath.trim());
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return AssetImage(assetPath);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Load / Save Methods
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> loadAll() async {
    await loadNewSettings();
    await loadOutfitPreference();
    await loadCustomImagePaths();
  }

  Future<void> loadNewSettings() async {
    final prefs = await SharedPreferences.getInstance();
    showMessageTimestamps = prefs.getBool(_showTimestampsPrefKey) ?? false;
    hapticFeedbackEnabled = prefs.getBool(_hapticFeedbackPrefKey) ?? true;
    wakePopupEnabled = prefs.getBool(_wakePopupPrefKey) ?? true;
    soundOnWake = prefs.getBool(_soundOnWakePrefKey) ?? true;
    showChatHint = prefs.getBool(_showChatHintPrefKey) ?? true;
    wallpaperBrightness =
        (prefs.getDouble(_wallpaperBrightnessPrefKey) ?? 0.5).clamp(0.0, 1.0);
    responseLengthMode = prefs.getString(_responseLengthPrefKey) ?? 'Normal';
    chatTextSize = prefs.getString(_chatTextSizePrefKey) ?? 'Medium';
    autoScrollChat = prefs.getBool(_autoScrollChatPrefKey) ?? true;
    ttsSpeed = (prefs.getDouble(_ttsSpeedPrefKey) ?? 1.0).clamp(0.5, 2.0);
    liteModeEnabled = prefs.getBool(_liteModeEnabledPrefKey) ?? false;
    appLockEnabled = prefs.getBool(_appLockEnabledPrefKey) ?? false;
    dualVoiceEnabled = prefs.getBool(_dualVoiceEnabledPrefKey) ?? false;
    dualVoiceSecondary =
        prefs.getString(_dualVoiceSecondaryPrefKey) ?? 'alloy';
    notifyListeners();
  }

  Future<void> loadOutfitPreference() async {
    final prefs = await SharedPreferences.getInstance();
    selectedOutfit = prefs.getString(_outfitPrefKey) ?? 'assets/img/z2s.jpg';
    notifyListeners();
  }

  Future<void> loadCustomImagePaths() async {
    final prefs = await SharedPreferences.getInstance();
    customChatImagePath = prefs.getString(_customChatImagePathPrefKey);
    chatImageFromSystem = prefs.getBool(_chatImageFromSystemPrefKey) ?? false;
    customAppIconPath = prefs.getString(_customAppIconPathPrefKey);
    appIconFromCustom = prefs.getBool(_appIconFromCustomPrefKey) ?? false;
    notifyListeners();
  }

  // ── Toggle / Set Methods ────────────────────────────────────────────────

  Future<void> toggleShowTimestamps() async {
    showMessageTimestamps = !showMessageTimestamps;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTimestampsPrefKey, showMessageTimestamps);
  }

  Future<void> toggleHapticFeedback() async {
    hapticFeedbackEnabled = !hapticFeedbackEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackPrefKey, hapticFeedbackEnabled);
  }

  Future<void> toggleWakePopupEnabled() async {
    wakePopupEnabled = !wakePopupEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wakePopupPrefKey, wakePopupEnabled);
    if (Platform.isAndroid && wakePopupEnabled) {
      final svc = AssistantModeService();
      final canOverlay = await svc.canDrawOverlays();
      if (!canOverlay) {
        await svc.requestOverlayPermission();
      }
    }
  }

  Future<void> toggleSoundOnWake() async {
    soundOnWake = !soundOnWake;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundOnWakePrefKey, soundOnWake);
  }

  Future<void> toggleShowChatHint() async {
    showChatHint = !showChatHint;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showChatHintPrefKey, showChatHint);
  }

  Future<void> setWallpaperBrightness(double value,
      {bool persist = true}) async {
    wallpaperBrightness = value.clamp(0.0, 1.0);
    notifyListeners();
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_wallpaperBrightnessPrefKey, wallpaperBrightness);
  }

  Future<void> setResponseLength(String mode) async {
    responseLengthMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_responseLengthPrefKey, mode);
  }

  Future<void> setChatTextSize(String size) async {
    chatTextSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatTextSizePrefKey, size);
  }

  Future<void> toggleAutoScrollChat() async {
    autoScrollChat = !autoScrollChat;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoScrollChatPrefKey, autoScrollChat);
  }

  Future<void> setTtsSpeed(double speed) async {
    final s = speed.clamp(0.5, 2.0).toDouble();
    if (ttsSpeed == s) return;
    ttsSpeed = s;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_ttsSpeedPrefKey, s);
  }

  Future<void> setOutfit(String assetPath) async {
    selectedOutfit = assetPath;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outfitPrefKey, assetPath);
  }

  Future<void> toggleLiteMode() async {
    liteModeEnabled = !liteModeEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_liteModeEnabledPrefKey, liteModeEnabled);
  }

  Future<void> toggleAppLock() async {
    appLockEnabled = !appLockEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledPrefKey, appLockEnabled);
  }

  Future<void> toggleDualVoice() async {
    dualVoiceEnabled = !dualVoiceEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dualVoiceEnabledPrefKey, dualVoiceEnabled);
  }

  Future<void> setDualVoiceSecondary(String voice) async {
    dualVoiceSecondary = voice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dualVoiceSecondaryPrefKey, voice);
  }

  Future<void> pickImageFromGallery({required bool forChatImage}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) return;

      final path = picked.path.trim();
      if (path.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();

      if (forChatImage) {
        customChatImagePath = path;
        chatImageFromSystem = true;
        await prefs.setString(_customChatImagePathPrefKey, path);
        await prefs.setBool(_chatImageFromSystemPrefKey, true);
      } else {
        customAppIconPath = path;
        appIconFromCustom = true;
        await prefs.setString(_customAppIconPathPrefKey, path);
        await prefs.setBool(_appIconFromCustomPrefKey, true);
      }
      evictImageCaches();
      notifyListeners();
    } catch (e) {
      debugPrint('Gallery image pick failed: $e');
    }
  }

  Future<void> resetCustomImages() async {
    customChatImagePath = null;
    chatImageFromSystem = false;
    customAppIconPath = null;
    appIconFromCustom = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customChatImagePathPrefKey);
    await prefs.remove(_customAppIconPathPrefKey);
    await prefs.setBool(_chatImageFromSystemPrefKey, false);
    await prefs.setBool(_appIconFromCustomPrefKey, false);
    evictImageCaches();
  }

  void evictImageCaches() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Apply dev config overrides. Call after user updates dev panel.
  void applyDevConfig({
    String? apiKey,
    String? model,
    String? apiUrl,
    String? systemQuery,
    String? wakeKey,
    String? ttsApiKey,
    String? ttsModel,
    String? ttsVoice,
    String? mailJetApi,
    String? mailJetSec,
    String? sttLang,
    int? sttTimeout,
  }) {
    if (apiKey != null) devApiKeyOverride = apiKey;
    if (model != null) devModelOverride = model;
    if (apiUrl != null) devApiUrlOverride = apiUrl;
    if (systemQuery != null) devSystemQuery = systemQuery;
    if (wakeKey != null) devWakeKeyOverride = wakeKey;
    if (ttsApiKey != null) devTtsApiKeyOverride = ttsApiKey;
    if (ttsModel != null) devTtsModelOverride = ttsModel;
    if (ttsVoice != null) devTtsVoiceOverride = ttsVoice;
    if (mailJetApi != null) devMailJetApiOverride = mailJetApi;
    if (mailJetSec != null) devMailJetSecOverride = mailJetSec;
    if (sttLang != null) devSttLangOverride = sttLang;
    if (sttTimeout != null) devSttTimeoutOverride = sttTimeout;
    notifyListeners();
  }
}
