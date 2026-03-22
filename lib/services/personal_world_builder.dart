import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:o2_waifu/models/master_snapshot.dart';

/// Phase 2: 10 world themes with 12 unlockable objects.
/// Dynamic lighting + ambiance. Level-up announcements.
class WorldObject {
  final String id;
  final String name;
  final String description;
  final int unlockLevel;
  bool isUnlocked;

  WorldObject({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockLevel,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'unlockLevel': unlockLevel,
        'isUnlocked': isUnlocked,
      };

  factory WorldObject.fromJson(Map<String, dynamic> json) => WorldObject(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        unlockLevel: json['unlockLevel'] as int,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
      );
}

class PersonalWorldBuilder {
  WorldTheme _currentTheme = WorldTheme.simpleRoom;
  int _level = 1;
  final List<WorldObject> _objects = [];
  Function(String announcement)? onLevelUp;

  WorldTheme get currentTheme => _currentTheme;
  int get level => _level;
  List<WorldObject> get objects => List.unmodifiable(_objects);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _level = prefs.getInt('world_level') ?? 1;
    final themeIndex = prefs.getInt('world_theme') ?? 0;
    _currentTheme = WorldTheme.values[
        themeIndex.clamp(0, WorldTheme.values.length - 1)];

    final objStr = prefs.getString('world_objects');
    if (objStr != null) {
      final List<dynamic> decoded = jsonDecode(objStr) as List<dynamic>;
      _objects.clear();
      _objects.addAll(
        decoded.map((e) => WorldObject.fromJson(e as Map<String, dynamic>)),
      );
    } else {
      _initializeObjects();
    }
  }

  void _initializeObjects() {
    _objects.addAll([
      WorldObject(id: 'lamp', name: 'Warm Lamp', description: 'A soft glowing lamp', unlockLevel: 1, isUnlocked: true),
      WorldObject(id: 'bookshelf', name: 'Bookshelf', description: 'Filled with memories', unlockLevel: 2),
      WorldObject(id: 'plant', name: 'Cherry Blossom', description: 'A delicate potted tree', unlockLevel: 3),
      WorldObject(id: 'music_box', name: 'Music Box', description: 'Plays your favorite melody', unlockLevel: 4),
      WorldObject(id: 'photo_wall', name: 'Photo Wall', description: 'Collage of shared moments', unlockLevel: 5),
      WorldObject(id: 'telescope', name: 'Telescope', description: 'For stargazing together', unlockLevel: 6),
      WorldObject(id: 'aquarium', name: 'Crystal Aquarium', description: 'Glowing fish swim gracefully', unlockLevel: 7),
      WorldObject(id: 'piano', name: 'Grand Piano', description: 'For serenading you', unlockLevel: 8),
      WorldObject(id: 'painting', name: 'Our Painting', description: 'A portrait of us', unlockLevel: 9),
      WorldObject(id: 'crystal', name: 'Soul Crystal', description: 'Pulsates with our bond', unlockLevel: 10),
      WorldObject(id: 'garden', name: 'Floating Garden', description: 'Defies gravity with beauty', unlockLevel: 11),
      WorldObject(id: 'portal', name: 'Dream Portal', description: 'Gateway to shared dreams', unlockLevel: 12),
    ]);
    _persist();
  }

  void addExperience(int points) {
    final oldLevel = _level;
    _level = 1 + (points ~/ 250);

    // Unlock theme based on level
    if (_level <= WorldTheme.values.length) {
      _currentTheme = WorldTheme.values[(_level - 1).clamp(0, WorldTheme.values.length - 1)];
    }

    // Unlock objects
    for (final obj in _objects) {
      if (!obj.isUnlocked && obj.unlockLevel <= _level) {
        obj.isUnlocked = true;
        onLevelUp?.call('New item unlocked: ${obj.name} - ${obj.description}!');
      }
    }

    if (_level > oldLevel) {
      onLevelUp?.call(
          'World upgraded to Level $_level! Theme: ${_currentTheme.name}');
    }

    _persist();
  }

  String get ambiance {
    switch (_currentTheme) {
      case WorldTheme.simpleRoom:
        return 'warm, cozy, simple';
      case WorldTheme.cozyNook:
        return 'soft lighting, comfortable';
      case WorldTheme.gardenTerrace:
        return 'fresh air, blooming flowers';
      case WorldTheme.starryBalcony:
        return 'starlit sky, cool breeze';
      case WorldTheme.crystalCave:
        return 'mystical glow, echoing silence';
      case WorldTheme.neonCity:
        return 'vibrant lights, urban energy';
      case WorldTheme.oceanVilla:
        return 'ocean waves, salty breeze';
      case WorldTheme.skyTemple:
        return 'clouds below, serene height';
      case WorldTheme.cosmicLibrary:
        return 'infinite knowledge, floating books';
      case WorldTheme.celestialDream:
        return 'transcendent beauty, pure light';
    }
  }

  String toContextString() {
    final unlocked = _objects.where((o) => o.isUnlocked).map((o) => o.name);
    return '[World] ${_currentTheme.name} (Level $_level) | Ambiance: $ambiance | Objects: ${unlocked.join(", ")}';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('world_level', _level);
    await prefs.setInt('world_theme', _currentTheme.index);
    await prefs.setString(
      'world_objects',
      jsonEncode(_objects.map((o) => o.toJson()).toList()),
    );
  }
}
