import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../models/chat_message.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ChatProvider
///
/// Single source of truth for all chat-related state. The UI and
/// _ChatHomePageState methods read/write through this provider instead of
/// maintaining their own duplicate variables.
/// ─────────────────────────────────────────────────────────────────────────────
class ChatProvider extends ChangeNotifier {
  // ── Message lists ──────────────────────────────────────────────────────────
  final List<ChatMessage> messages = [];
  final List<ChatMessage> pastMessages = []; // older messages from prev session
  final List<ChatMessage> pinnedMessages = [];

  // ── Busy / speaking state ──────────────────────────────────────────────────
  bool _isBusy = false;
  bool get isBusy => _isBusy;
  set isBusy(bool v) {
    if (_isBusy == v) return;
    _isBusy = v;
    notifyListeners();
  }

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;
  set isSpeaking(bool v) {
    if (_isSpeaking == v) return;
    _isSpeaking = v;
    notifyListeners();
  }

  // ── Voice text (partial STT result shown as ghost bubble) ──────────────────
  String _currentVoiceText = '';
  String get currentVoiceText => _currentVoiceText;
  set currentVoiceText(String v) {
    if (_currentVoiceText == v) return;
    _currentVoiceText = v;
    notifyListeners();
  }

  // ── Pull-to-refresh counter ────────────────────────────────────────────────
  int swipeCount = 0;

  // ── User message counter ───────────────────────────────────────────────────
  int userMessageCount = 0;

  // ── Chat search ────────────────────────────────────────────────────────────
  bool _isChatSearchActive = false;
  bool get isChatSearchActive => _isChatSearchActive;
  set isChatSearchActive(bool v) {
    if (_isChatSearchActive == v) return;
    _isChatSearchActive = v;
    notifyListeners();
  }

  String _chatSearchQuery = '';
  String get chatSearchQuery => _chatSearchQuery;
  set chatSearchQuery(String v) {
    if (_chatSearchQuery == v) return;
    _chatSearchQuery = v;
    notifyListeners();
  }

  // ── Quick reply chips ──────────────────────────────────────────────────────
  List<String> _quickReplies = [];
  List<String> get quickReplies => _quickReplies;
  set quickReplies(List<String> v) {
    _quickReplies = v;
    notifyListeners();
  }

  // ── Mood / sticker ────────────────────────────────────────────────────────
  String _currentMoodLabel = 'Happy 😊';
  String get currentMoodLabel => _currentMoodLabel;
  set currentMoodLabel(String v) {
    if (_currentMoodLabel == v) return;
    _currentMoodLabel = v;
    notifyListeners();
  }

  final String currentStickerEmotion = 'neutral';

  // ── Phase 2 prompt extras (personality + memory + context + jealousy) ──────
  String phase2PromptExtras = '';

  // ── Memory cache ───────────────────────────────────────────────────────────
  String cachedMemoryBlock = '';

  // ── Image attachment for vision ────────────────────────────────────────────
  File? _selectedImage;
  File? get selectedImage => _selectedImage;
  set selectedImage(File? v) {
    _selectedImage = v;
    notifyListeners();
  }

  // ── Custom rules / prompt overrides (loaded from Firestore) ────────────────
  String customRules = '';
  String waifuPromptOverride = '';

  // ── API key status ─────────────────────────────────────────────────────────
  String _apiKeyStatus = 'Checking...';
  String get apiKeyStatus => _apiKeyStatus;
  set apiKeyStatus(String v) {
    if (_apiKeyStatus == v) return;
    _apiKeyStatus = v;
    notifyListeners();
  }

  // ── Persona ────────────────────────────────────────────────────────────────
  String _selectedPersona = 'Default';
  String get selectedPersona => _selectedPersona;
  set selectedPersona(String v) {
    if (_selectedPersona == v) return;
    _selectedPersona = v;
    notifyListeners();
  }

  // ── Sleep mode ─────────────────────────────────────────────────────────────
  bool _sleepModeEnabled = false;
  bool get sleepModeEnabled => _sleepModeEnabled;
  set sleepModeEnabled(bool v) {
    if (_sleepModeEnabled == v) return;
    _sleepModeEnabled = v;
    notifyListeners();
  }

  bool get isSleepTime {
    if (!_sleepModeEnabled) return false;
    final now = DateTime.now();
    return now.hour >= 0 && now.hour < 7;
  }

  // ── Notification state ─────────────────────────────────────────────────────
  List<Map<String, String>> notifHistory = [];
  bool hasUnreadNotifs = false;
  bool showInAppNotif = false;
  String inAppNotifText = '';

  // ── Idle / proactive timers state ──────────────────────────────────────────
  bool idleTimerEnabled = true;
  bool idleBlockedUntilUserMessage = false;
  int idleConsumedAtUserMessageCount = -1;
  int idleDurationSeconds = 600;
  int proactiveIntervalSeconds = 1800; // 30 min — battery optimized
  bool proactiveEnabled = true;
  bool proactiveRandomEnabled = true;

  /// Restore persisted idle/proactive/persona/sleep settings from disk.
  /// Called once at provider creation via `ChatProvider()..loadPersistedState()`.
  Future<void> loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      idleTimerEnabled = prefs.getBool('idle_timer_enabled') ?? true;
      idleDurationSeconds = prefs.getInt('idle_duration_seconds') ?? 600;
      proactiveIntervalSeconds =
          prefs.getInt('proactive_interval_seconds') ?? 1800;
      proactiveEnabled = prefs.getBool('proactive_enabled') ?? true;
      proactiveRandomEnabled =
          prefs.getBool('proactive_random_enabled') ?? true;
      _selectedPersona =
          prefs.getString('selected_persona_v1') ?? 'Default';
      _sleepModeEnabled = prefs.getBool('sleep_mode_enabled_v1') ?? false;
      notifyListeners();
    } catch (e) {
      // If SharedPreferences fails, defaults are fine.
    }
  }

  // ── Convenience: add a message and notify ──────────────────────────────────
  void addMessage(ChatMessage msg) {
    messages.add(msg);
    notifyListeners();
  }

  void clearMessages() {
    messages.clear();
    pastMessages.clear();
    pinnedMessages.clear();
    userMessageCount = 0;
    notifyListeners();
  }

  /// Remove messages by ID from both active and past lists.
  void deleteMessages(Set<String> idsToDelete) {
    messages.removeWhere((m) => idsToDelete.contains(m.id));
    pastMessages.removeWhere((m) => idsToDelete.contains(m.id));
    pinnedMessages.removeWhere((m) => idsToDelete.contains(m.id));
    notifyListeners();
  }


  void insertPastMessages() {
    if (pastMessages.isNotEmpty) {
      messages.insertAll(0, pastMessages);
      pastMessages.clear();
      swipeCount = 0;
      notifyListeners();
    }
  }

  /// Remove the attached image.
  void removeSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }
}


