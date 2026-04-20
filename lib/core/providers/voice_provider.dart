import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// VoiceProvider
///
/// Single source of truth for all voice-related state: STT, TTS, wake word,
/// and assistant-mode flags. The UI and _ChatHomePageState methods read/write
/// through this provider instead of maintaining their own duplicate variables.
///
/// NOTE: The actual service instances (SpeechService, TtsService,
/// PorcupineService) remain in _ChatHomePageState because they are
/// lifecycle-managed (init/dispose). This provider holds only the *state*
/// that drives UI rendering and cross-method communication.
/// ─────────────────────────────────────────────────────────────────────────────
class VoiceProvider extends ChangeNotifier {
  // ── Auto-listen / assistant mode ───────────────────────────────────────────
  bool _isAutoListening = false;
  bool get isAutoListening => _isAutoListening;
  set isAutoListening(bool v) {
    if (_isAutoListening == v) return;
    _isAutoListening = v;
    notifyListeners();
  }

  bool _assistantModeEnabled = false;
  bool get assistantModeEnabled => _assistantModeEnabled;
  set assistantModeEnabled(bool v) {
    if (_assistantModeEnabled == v) return;
    _assistantModeEnabled = v;
    notifyListeners();
  }

  // ── Wake word state ────────────────────────────────────────────────────────
  bool _suspendWakeWord = false;
  bool get suspendWakeWord => _suspendWakeWord;
  set suspendWakeWord(bool v) {
    if (_suspendWakeWord == v) return;
    _suspendWakeWord = v;
    notifyListeners();
  }

  bool _wakeWordReady = false;
  bool get wakeWordReady => _wakeWordReady;
  set wakeWordReady(bool v) {
    if (_wakeWordReady == v) return;
    _wakeWordReady = v;
    notifyListeners();
  }

  bool _wakeInitInProgress = false;
  bool get wakeInitInProgress => _wakeInitInProgress;
  set wakeInitInProgress(bool v) {
    if (_wakeInitInProgress == v) return;
    _wakeInitInProgress = v;
    notifyListeners();
  }

  bool _wakeWordEnabledByUser = true;
  bool get wakeWordEnabledByUser => _wakeWordEnabledByUser;
  set wakeWordEnabledByUser(bool v) {
    if (_wakeWordEnabledByUser == v) return;
    _wakeWordEnabledByUser = v;
    notifyListeners();
  }

  bool _wakeWordActivationLimitHit = false;
  bool get wakeWordActivationLimitHit => _wakeWordActivationLimitHit;
  set wakeWordActivationLimitHit(bool v) {
    if (_wakeWordActivationLimitHit == v) return;
    _wakeWordActivationLimitHit = v;
    notifyListeners();
  }

  // ── Manual mic session ─────────────────────────────────────────────────────
  bool _isManualMicSession = false;
  bool get isManualMicSession => _isManualMicSession;
  set isManualMicSession(bool v) {
    if (_isManualMicSession == v) return;
    _isManualMicSession = v;
    notifyListeners();
  }

  // ── Voice model ────────────────────────────────────────────────────────────
  String _voiceModel = 'english';
  String get voiceModel => _voiceModel;
  set voiceModel(String v) {
    if (_voiceModel == v) return;
    _voiceModel = v;
    notifyListeners();
  }

  // ── Wake effect (visual pulse on wake word detect) ─────────────────────────
  bool _wakeEffectVisible = false;
  bool get wakeEffectVisible => _wakeEffectVisible;
  set wakeEffectVisible(bool v) {
    if (_wakeEffectVisible == v) return;
    _wakeEffectVisible = v;
    notifyListeners();
  }

  // ── Pending reply dispatch (deferred reply after wake word) ────────────────
  bool pendingReplyDispatch = false;
  bool pendingReplyNeedsVoice = false;
}


