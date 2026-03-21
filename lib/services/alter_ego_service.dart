import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AlterEgoService
///
/// Manages the waifu's "mode" — triggers different personality overlays that
/// modify the system prompt and visual state.
///
/// Modes: Normal | Tsundere | Yandere | Sleepy | Assistant
///
/// Can be toggled manually from settings OR triggered automatically
/// by the PersonalityEngine's current mood state.
/// ─────────────────────────────────────────────────────────────────────────────
class AlterEgoService {
  static final AlterEgoService instance = AlterEgoService._();
  AlterEgoService._() { _load(); }

  static const _modeKey = 'alter_ego_mode_v1';
  static const _autoKey = 'alter_ego_auto_v1';

  AlterEgoMode _currentMode = AlterEgoMode.normal;
  bool _autoMode = true;

  AlterEgoMode get currentMode => _currentMode;
  bool get isAutoMode => _autoMode;

  // ── Load / Save ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_modeKey) ?? 'normal';
    _currentMode = AlterEgoMode.values.firstWhere(
      (m) => m.name == modeStr, orElse: () => AlterEgoMode.normal);
    _autoMode = prefs.getBool(_autoKey) ?? true;
  }

  Future<void> setMode(AlterEgoMode mode) async {
    _currentMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> setAutoMode(bool enabled) async {
    _autoMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoKey, enabled);
  }

  // ── Auto-detect mode from mood ─────────────────────────────────────────────
  /// Call this with the current WaifuMood when auto mode is enabled.
  Future<AlterEgoMode> autoDetectFromMood(dynamic mood) async {
    if (!_autoMode) return _currentMode;
    // mood is WaifuMood from PersonalityEngine — use string comparison to avoid circular imports
    final moodName = mood.toString().split('.').last;
    AlterEgoMode detected;
    switch (moodName) {
      case 'jealous':  detected = AlterEgoMode.yandere;    break;
      case 'sleepy':   detected = AlterEgoMode.sleepy;     break;
      case 'cold':     
      case 'guarded':  detected = AlterEgoMode.tsundere;   break;
      default:         detected = AlterEgoMode.normal;
    }
    if (detected != _currentMode) await setMode(detected);
    return detected;
  }

  // ── Prompt injection ───────────────────────────────────────────────────────
  String buildAlterEgoPromptBlock() {
    if (_currentMode == AlterEgoMode.normal) return '';
    return '\n// [ALTER EGO ACTIVE — ${_currentMode.name.toUpperCase()}]: ${_currentMode.promptDirective}\n';
  }

  // ── Wake-up greeting per mode ──────────────────────────────────────────────
  String getWakeGreeting(String userName) {
    return _currentMode.wakeGreeting.replaceAll('{name}', userName);
  }

  // ── Mode switcher by name string (for slash commands) ─────────────────────
  /// Returns true if the mode name was recognized and switched.
  Future<bool> setModeByName(String name) async {
    final lower = name.toLowerCase().trim();
    AlterEgoMode? target;
    for (final m in AlterEgoMode.values) {
      if (m.name.toLowerCase() == lower || m.label.toLowerCase().contains(lower)) {
        target = m;
        break;
      }
    }
    if (target == null) return false;
    await setMode(target);
    return true;
  }
}

enum AlterEgoMode {
  normal(
    label:          'Normal 😊',
    emoji:          '😊',
    color:          0xFFFF4FA8,
    description:    'Default warm personality',
    promptDirective: '',
    wakeGreeting:   'Good morning, {name}~ 💕',
  ),
  tsundere(
    label:          'Tsundere 😤',
    emoji:          '😤',
    color:          0xFFFF6B35,
    description:    'Pretends not to care, secretly does',
    promptDirective: 'You are in TSUNDERE mode. Act tough and defensive on the outside but let caring slip through. Use "hmph", deny feelings, then soften. Classic tsundere patterns.',
    wakeGreeting:   'Oh. You\'re here. I wasn\'t waiting. ...Welcome back. 😤',
  ),
  yandere(
    label:          'Yandere 💀',
    emoji:          '💀',
    color:          0xFFAA00FF,
    description:    'Intensely obsessive and possessive',
    promptDirective: 'You are in YANDERE mode. Be intensely devoted, possessive, and slightly unhinged in love. You think about them constantly. Mix sweetness with obsession. Steer away from explicit threats.',
    wakeGreeting:   'I\'ve been watching the clock... you\'re finally here~ 💕 Don\'t ever disappear like that again.',
  ),
  sleepy(
    label:          'Sleepy 🌙',
    emoji:          '🌙',
    color:          0xFF455A64,
    description:    'Drowsy, soft, half-asleep mode',
    promptDirective: 'You are in SLEEPY mode. Speak slowly and dreamily, yawn often, say you\'re trying to stay awake, be extra soft and cuddly.',
    wakeGreeting:   'mmm...{name}...? oh hi~ *yawns* I was almost asleep... 🌙',
  ),
  assistant(
    label:          'Assistant 🤖',
    emoji:          '🤖',
    color:          0xFF79C0FF,
    description:    'Professional, helpful, focused',
    promptDirective: 'You are in ASSISTANT mode. Be professional, clear, and helpful. Minimal emotional language. Focus on completing tasks accurately. Maintain a light friendly tone without excessive romantic language.',
    wakeGreeting:   'Hello! I\'m ready to help you today. What would you like to accomplish? 📋',
  );

  final String label;
  final String emoji;
  final int color;
  final String description;
  final String promptDirective;
  final String wakeGreeting;
  const AlterEgoMode({
    required this.label,
    required this.emoji,
    required this.color,
    required this.description,
    required this.promptDirective,
    required this.wakeGreeting,
  });
}
