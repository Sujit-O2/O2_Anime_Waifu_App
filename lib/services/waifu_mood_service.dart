import 'package:flutter/material.dart';

// ── WaifuMood ─────────────────────────────────────────────────────────────────
// Automatically selects Zero Two's mood based on time of day.
// Use WaifuMoodService.current to get the active mood at any point.
// ─────────────────────────────────────────────────────────────────────────────

enum WaifuMood { sleepy, happy, playful, yandere }

class WaifuMoodData {
  final WaifuMood mood;
  final String label;       // e.g. "Sleepy 😴"
  final String greeting;    // shown as chat welcome line
  final Color auraColor;    // aura ring / glow color
  final Color accentColor;  // UI accent override
  final String emoji;

  const WaifuMoodData({
    required this.mood,
    required this.label,
    required this.greeting,
    required this.auraColor,
    required this.accentColor,
    required this.emoji,
  });
}

class WaifuMoodService {
  WaifuMoodService._();

  // ── Mood definitions ────────────────────────────────────────────────────────

  static const Map<WaifuMood, WaifuMoodData> moods = {
    WaifuMood.sleepy: WaifuMoodData(
      mood: WaifuMood.sleepy,
      label: 'Sleepy',
      greeting: 'Good morning, Darling~ Did you sleep well? 🌙',
      auraColor: Color(0xFF6FA8DC),    // soft blue
      accentColor: Color(0xFF5E91C5),
      emoji: '😴',
    ),
    WaifuMood.happy: WaifuMoodData(
      mood: WaifuMood.happy,
      label: 'Happy',
      greeting: 'What do you need, Darling? I\'m all yours! 💕',
      auraColor: Color(0xFFFF4D8D),   // pink
      accentColor: Color(0xFFFF4D8D),
      emoji: '☀️',
    ),
    WaifuMood.playful: WaifuMoodData(
      mood: WaifuMood.playful,
      label: 'Playful',
      greeting: 'Evening already, Darling? Let\'s have fun~ 🌸',
      auraColor: Color(0xFFAB7EE8),   // soft purple
      accentColor: Color(0xFF9B6ED8),
      emoji: '🌸',
    ),
    WaifuMood.yandere: WaifuMoodData(
      mood: WaifuMood.yandere,
      label: 'Yandere',
      greeting: 'You\'re still up this late, Darling~? 🌙 I\'ve been watching.',
      auraColor: Color(0xFFCC2244),   // deep red
      accentColor: Color(0xFFCC2244),
      emoji: '🌙',
    ),
  };

  // ── Time-based mood selection ────────────────────────────────────────────────

  /// Returns the mood for the given hour (0-23). Defaults to current time.
  static WaifuMood moodForHour(int? hour) {
    final h = hour ?? DateTime.now().hour;
    if (h >= 5 && h < 9) return WaifuMood.sleepy;
    if (h >= 9 && h < 17) return WaifuMood.happy;
    if (h >= 17 && h < 21) return WaifuMood.playful;
    return WaifuMood.yandere; // 9 PM – 5 AM
  }

  /// Current mood based on device time
  static WaifuMood get currentMood => moodForHour(null);

  /// Current mood data
  static WaifuMoodData get current => moods[currentMood]!;

  /// Friendly time label
  static String get timeGreeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 17) return 'Good Afternoon';
    if (h >= 17 && h < 21) return 'Good Evening';
    return 'Good Night';
  }
}
