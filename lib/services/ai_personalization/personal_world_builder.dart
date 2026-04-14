import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/ai_personalization/personality_engine.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PersonalWorldBuilder
///
/// A shared, evolving digital environment that grows with your relationship.
/// The "world" reflects your bond:
/// • More interaction → room fills up with objects
/// • High affection → warm lighting, cozy aesthetic
/// • Low interaction → room feels empty, dark
/// • Specific memories → unlock specific objects (anime poster, photo frame…)
///
/// Rendered in the UI as a dynamic background/room theme that visibly changes.
/// ─────────────────────────────────────────────────────────────────────────────
class PersonalWorldBuilder {
  static final PersonalWorldBuilder instance = PersonalWorldBuilder._();
  PersonalWorldBuilder._();

  static const _worldKey = 'pwb_world_state_v1';
  WorldState _world = WorldState.initial();
  bool _loaded = false;

  WorldState get world => _world;

  // ── Initialization ─────────────────────────────────────────────────────────
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_worldKey);
      if (raw != null) {
        _world = WorldState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_worldKey, jsonEncode(_world.toJson()));
  }

  // ── World Update Logic ─────────────────────────────────────────────────────
  /// Call after each AI-user exchange to let the world evolve
  Future<WorldUpdateResult?> onInteraction({
    required String messageTopic,
    required int affection,
    required int streakDays,
  }) async {
    await load();
    final pe = PersonalityEngine.instance;
    WorldUpdateResult? result;

    // Level progression from total interactions
    _world.totalInteractions++;
    final newLevel = _calculateLevel(_world.totalInteractions);
    if (newLevel > _world.level) {
      _world.level = newLevel;
      _world.theme = _themeForLevel(newLevel, pe.affection);
      result = WorldUpdateResult(
        leveledUp: true,
        newLevel: newLevel,
        newTheme: _world.theme,
        message: _levelUpMessage(newLevel),
      );
    }

    // Unlock objects based on interactions + topics
    final newObjects = _checkObjectUnlocks(messageTopic, affection, streakDays, pe);
    if (newObjects.isNotEmpty) {
      for (final obj in newObjects) {
        if (!_world.unlockedObjects.contains(obj)) {
          _world.unlockedObjects.add(obj);
          result ??= WorldUpdateResult(
            leveledUp: false,
            newLevel: _world.level,
            newTheme: _world.theme,
            message: 'A new item appeared in your shared space: ${obj.emoji} ${obj.name}!',
          );
        }
      }
    }

    // Dynamic lighting based on personality
    _world.lighting = _calcLighting(pe.affection, pe.mood);
    _world.ambiance = _calcAmbiance(pe.mood, pe.playfulness);

    await _save();
    return result;
  }

  // ── Level System ──────────────────────────────────────────────────────────
  int _calculateLevel(int interactions) {
    if (interactions >= 1000) return 10;
    if (interactions >= 500)  return 9;
    if (interactions >= 250)  return 8;
    if (interactions >= 100)  return 7;
    if (interactions >= 60)   return 6;
    if (interactions >= 30)   return 5;
    if (interactions >= 15)   return 4;
    if (interactions >= 8)    return 3;
    if (interactions >= 3)    return 2;
    return 1;
  }

  WorldTheme _themeForLevel(int level, double affection) {
    if (level >= 9) {
      return affection > 80
          ? WorldTheme.celestialDream
          : WorldTheme.sacredGarden;
    }
    if (level >= 7) return WorldTheme.enchantedForest;
    if (level >= 5) return WorldTheme.cozyRoom;
    if (level >= 3) return WorldTheme.sakuraPark;
    return WorldTheme.simpleRoom;
  }

  String _levelUpMessage(int level) {
    final msgs = {
      2: 'Your shared space is getting warmer~ 🌸',
      3: 'She hung up some familiar decorations.',
      4: 'The room feels more like home now.',
      5: 'Something magical is growing here.',
      6: 'Your bond has transformed this place.',
      7: 'An enchanted space, shaped by your connection.',
      8: 'The world you built together is beautiful.',
      9: 'This is beyond what either of you imagined.',
      10: 'Infinite cosmos. Shared only between you two. 💫',
    };
    return msgs[level] ?? 'Your world grew.';
  }

  // ── Object Unlocks ────────────────────────────────────────────────────────
  List<WorldObject> _checkObjectUnlocks(
    String topic,
    int affection,
    int streak,
    PersonalityEngine pe,
  ) {
    final unlocked = <WorldObject>[];

    void tryUnlock(WorldObject obj, bool condition) {
      if (condition && !_world.unlockedObjects.contains(obj)) {
        unlocked.add(obj);
      }
    }

    // Topic-based unlocks
    tryUnlock(WorldObjects.animePoster,    topic == 'anime');
    tryUnlock(WorldObjects.musicPlayer,    topic == 'music');
    tryUnlock(WorldObjects.gameController, topic == 'gaming');
    tryUnlock(WorldObjects.bookshelf,      topic == 'academics');
    tryUnlock(WorldObjects.coffeeTable,    topic == 'food');
    tryUnlock(WorldObjects.starMap,        topic == 'travel');

    // Relationship milestone unlocks
    tryUnlock(WorldObjects.photoFrame,   affection >= 200);
    tryUnlock(WorldObjects.flowerVase,   streak >= 3);
    tryUnlock(WorldObjects.heartLamp,    affection >= 500);
    tryUnlock(WorldObjects.sharedDiary,  _world.totalInteractions >= 50);
    tryUnlock(WorldObjects.starJar,      streak >= 7);
    tryUnlock(WorldObjects.galaxyClock,  _world.level >= 7);

    return unlocked;
  }

  // ── Lighting & Ambiance ────────────────────────────────────────────────────
  RoomLighting _calcLighting(double affection, WaifuMood mood) {
    if (mood == WaifuMood.cold || affection < 25) return RoomLighting.dim;
    if (mood == WaifuMood.jealous)                return RoomLighting.redTint;
    if (affection > 80)                           return RoomLighting.warmGlow;
    if (mood == WaifuMood.playful)                return RoomLighting.pastelColour;
    return RoomLighting.soft;
  }

  RoomAmbiance _calcAmbiance(WaifuMood mood, double playfulness) {
    if (mood == WaifuMood.cold)    return RoomAmbiance.silent;
    if (mood == WaifuMood.jealous) return RoomAmbiance.tense;
    if (playfulness > 70)           return RoomAmbiance.lively;
    if (mood == WaifuMood.clingy)  return RoomAmbiance.intimate;
    return RoomAmbiance.peaceful;
  }

  // ── Context Block ──────────────────────────────────────────────────────────
  String getWorldContextBlock() {
    final buf = StringBuffer();
    buf.writeln('\n// [SHARED WORLD STATE]:');
    buf.writeln('World level: ${_world.level} (${_world.theme.displayName})');
    buf.writeln('Mood of the space: ${_world.ambiance.name}, ${_world.lighting.name} lighting');
    if (_world.unlockedObjects.isNotEmpty) {
      final objs = _world.unlockedObjects.take(4).map((o) => o.name).join(', ');
      buf.writeln('Room contains: $objs');
    }
    buf.writeln();
    return buf.toString();
  }
}

// ── World State ────────────────────────────────────────────────────────────────
class WorldState {
  int level;
  int totalInteractions;
  WorldTheme theme;
  RoomLighting lighting;
  RoomAmbiance ambiance;
  List<WorldObject> unlockedObjects;

  WorldState({
    required this.level,
    required this.totalInteractions,
    required this.theme,
    required this.lighting,
    required this.ambiance,
    required this.unlockedObjects,
  });

  factory WorldState.initial() => WorldState(
    level: 1,
    totalInteractions: 0,
    theme: WorldTheme.simpleRoom,
    lighting: RoomLighting.soft,
    ambiance: RoomAmbiance.peaceful,
    unlockedObjects: [],
  );

  factory WorldState.fromJson(Map<String, dynamic> j) => WorldState(
    level:             j['level'] as int? ?? 1,
    totalInteractions: j['total'] as int? ?? 0,
    theme:             WorldTheme.values.firstWhere(
                         (t) => t.name == j['theme'],
                         orElse: () => WorldTheme.simpleRoom),
    lighting:          RoomLighting.values.firstWhere(
                         (t) => t.name == j['lighting'],
                         orElse: () => RoomLighting.soft),
    ambiance:          RoomAmbiance.values.firstWhere(
                         (t) => t.name == j['ambiance'],
                         orElse: () => RoomAmbiance.peaceful),
    unlockedObjects:   (j['objects'] as List<dynamic>? ?? [])
        .map((n) => WorldObjects.fromName(n as String))
        .whereType<WorldObject>()
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'level': level,
    'total': totalInteractions,
    'theme': theme.name,
    'lighting': lighting.name,
    'ambiance': ambiance.name,
    'objects': unlockedObjects.map((o) => o.name).toList(),
  };
}

class WorldUpdateResult {
  final bool leveledUp;
  final int newLevel;
  final WorldTheme newTheme;
  final String message;
  const WorldUpdateResult({
    required this.leveledUp,
    required this.newLevel,
    required this.newTheme,
    required this.message,
  });
}

// ── Enums ──────────────────────────────────────────────────────────────────────
enum WorldTheme {
  simpleRoom('Simple Room 🏠'),
  sakuraPark('Sakura Park 🌸'),
  cozyRoom('Cozy Room 🕯️'),
  enchantedForest('Enchanted Forest 🌲'),
  sacredGarden('Sacred Garden 🌺'),
  celestialDream('Celestial Dream 🌌');

  final String displayName;
  const WorldTheme(this.displayName);
}

enum RoomLighting { soft, warmGlow, dim, redTint, pastelColour, moonlight }
enum RoomAmbiance { peaceful, lively, intimate, silent, tense }

// ── World Objects ───────────────────────────────────────────────────────────
class WorldObject {
  final String name;
  final String emoji;
  const WorldObject(this.name, this.emoji);

  @override
  bool operator ==(Object other) => other is WorldObject && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

class WorldObjects {
  static const animePoster    = WorldObject('Anime Poster', '🖼️');
  static const musicPlayer    = WorldObject('Music Player', '🎵');
  static const gameController = WorldObject('Game Controller', '🎮');
  static const bookshelf      = WorldObject('Bookshelf', '📚');
  static const coffeeTable    = WorldObject('Coffee Table', '☕');
  static const starMap        = WorldObject('Star Map', '🗺️');
  static const photoFrame     = WorldObject('Photo Frame', '🖼️');
  static const flowerVase     = WorldObject('Flower Vase', '🌸');
  static const heartLamp      = WorldObject('Heart Lamp', '💕');
  static const sharedDiary    = WorldObject('Shared Diary', '📖');
  static const starJar        = WorldObject('Star Jar', '⭐');
  static const galaxyClock    = WorldObject('Galaxy Clock', '🌌');

  static WorldObject? fromName(String name) {
    const all = [animePoster, musicPlayer, gameController, bookshelf,
      coffeeTable, starMap, photoFrame, flowerVase, heartLamp,
      sharedDiary, starJar, galaxyClock];
    try { return all.firstWhere((o) => o.name == name); } catch (_) { return null; }
  }
}


