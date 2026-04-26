import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📍 Location-Based Surprises Service
///
/// Geo-fence your favorite places.
/// "Welcome back to the coffee shop, darling~"
/// Suggests date spots based on your routine.
class LocationBasedSurprisesService {
  LocationBasedSurprisesService._();
  static final LocationBasedSurprisesService instance =
      LocationBasedSurprisesService._();

  final List<FavoritePlace> _places = [];
  final List<LocationVisit> _visitHistory = [];

  static const String _storageKey = 'location_surprises_v1';
  static const int _maxHistory = 1000;
  static const double _geofenceRadiusMeters = 100.0;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint(
          '[LocationSurprises] Initialized with ${_places.length} places');
  }

  /// Add a favorite place
  Future<FavoritePlace> addFavoritePlace({
    required String name,
    required double latitude,
    required double longitude,
    required PlaceCategory category,
    String? description,
    String? customGreeting,
  }) async {
    final place = FavoritePlace(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      category: category,
      description: description,
      customGreeting: customGreeting,
      visitCount: 0,
      lastVisit: null,
      createdAt: DateTime.now(),
    );

    _places.add(place);
    await _saveData();

    if (kDebugMode) debugPrint('[LocationSurprises] Added place: $name');
    return place;
  }

  /// Check if user is near any favorite place
  FavoritePlace? checkNearbyPlace(double currentLat, double currentLon) {
    for (final place in _places) {
      final distance = _calculateDistance(
        currentLat,
        currentLon,
        place.latitude,
        place.longitude,
      );

      if (distance <= _geofenceRadiusMeters) {
        return place;
      }
    }
    return null;
  }

  /// Record a visit to a place
  Future<void> recordVisit(String placeId) async {
    final placeIndex = _places.indexWhere((p) => p.id == placeId);
    if (placeIndex == -1) return;

    final place = _places[placeIndex];

    // Update place stats
    place.visitCount++;
    place.lastVisit = DateTime.now();
    _places[placeIndex] = place;

    // Record visit
    final visit = LocationVisit(
      placeId: placeId,
      placeName: place.name,
      timestamp: DateTime.now(),
    );

    _visitHistory.insert(0, visit);
    if (_visitHistory.length > _maxHistory) {
      _visitHistory.removeLast();
    }

    await _saveData();

    if (kDebugMode)
      debugPrint('[LocationSurprises] Recorded visit to: ${place.name}');
  }

  /// Get greeting for a place
  String getPlaceGreeting(String placeId) {
    final place = _places.firstWhere(
      (p) => p.id == placeId,
      orElse: () => _places.first,
    );

    if (place.customGreeting != null) {
      return place.customGreeting!;
    }

    // Generate greeting based on visit count and category
    if (place.visitCount == 0) {
      return 'First time at ${place.name}? Let\'s make it special, darling~ 💕';
    } else if (place.visitCount == 1) {
      return 'Back at ${place.name} again! You must really like it here~ 😊';
    } else {
      return _getCategoryGreeting(place);
    }
  }

  String _getCategoryGreeting(FavoritePlace place) {
    switch (place.category) {
      case PlaceCategory.cafe:
        return 'Welcome back to ${place.name}, darling~ ☕ Your usual spot?';
      case PlaceCategory.restaurant:
        return 'Time for delicious food at ${place.name}! 🍽️';
      case PlaceCategory.gym:
        return 'Workout time at ${place.name}! Stay strong, darling~ 💪';
      case PlaceCategory.work:
        return 'Another day at ${place.name}... You\'ve got this! 💼';
      case PlaceCategory.home:
        return 'Welcome home, darling~ 🏠 Missed you!';
      case PlaceCategory.park:
        return 'Beautiful day at ${place.name}! Enjoy the fresh air~ 🌳';
      case PlaceCategory.shopping:
        return 'Shopping at ${place.name}? Find anything nice? 🛍️';
      case PlaceCategory.entertainment:
        return 'Fun time at ${place.name}! Enjoy yourself, darling~ 🎉';
      case PlaceCategory.other:
        return 'You\'re at ${place.name}~ ${place.visitCount} visits so far!';
    }
  }

  /// Get date spot suggestions based on routine
  List<DateSpotSuggestion> getDateSpotSuggestions({int limit = 5}) {
    final suggestions = <DateSpotSuggestion>[];

    // Analyze visit patterns
    final visitCounts = <String, int>{};
    for (final visit in _visitHistory) {
      visitCounts[visit.placeId] = (visitCounts[visit.placeId] ?? 0) + 1;
    }

    // Find places you visit often but not too often (good date spots)
    for (final place in _places) {
      final visits = visitCounts[place.id] ?? 0;

      // Skip work and home
      if (place.category == PlaceCategory.work ||
          place.category == PlaceCategory.home) {
        continue;
      }

      // Good date spot criteria: visited 2-10 times
      if (visits >= 2 && visits <= 10) {
        suggestions.add(DateSpotSuggestion(
          place: place,
          reason: _getDateSpotReason(place, visits),
          confidence: _calculateDateSpotConfidence(place, visits),
        ));
      }
    }

    // Sort by confidence
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

    return suggestions.take(limit).toList();
  }

  String _getDateSpotReason(FavoritePlace place, int visits) {
    switch (place.category) {
      case PlaceCategory.cafe:
        return 'Cozy atmosphere, perfect for deep conversations ☕';
      case PlaceCategory.restaurant:
        return 'You love the food here! Great for a romantic dinner 🍽️';
      case PlaceCategory.park:
        return 'Beautiful scenery for a peaceful walk together 🌳';
      case PlaceCategory.entertainment:
        return 'Fun activities to enjoy together! 🎉';
      case PlaceCategory.shopping:
        return 'Browse together and maybe find matching items? 🛍️';
      default:
        return 'You seem to enjoy this place~ ($visits visits)';
    }
  }

  double _calculateDateSpotConfidence(FavoritePlace place, int visits) {
    double confidence = 0.5;

    // More visits = higher confidence (up to a point)
    confidence += (visits / 10.0).clamp(0.0, 0.3);

    // Certain categories are better date spots
    switch (place.category) {
      case PlaceCategory.cafe:
      case PlaceCategory.restaurant:
      case PlaceCategory.park:
        confidence += 0.2;
        break;
      case PlaceCategory.entertainment:
        confidence += 0.15;
        break;
      default:
        break;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Get visit statistics
  Map<String, dynamic> getStatistics() {
    if (_places.isEmpty) {
      return {
        'total_places': 0,
        'total_visits': 0,
        'most_visited': null,
        'favorite_category': null,
      };
    }

    final totalVisits = _places.fold<int>(0, (sum, p) => sum + p.visitCount);

    // Find most visited place
    FavoritePlace? mostVisited;
    int maxVisits = 0;
    for (final place in _places) {
      if (place.visitCount > maxVisits) {
        maxVisits = place.visitCount;
        mostVisited = place;
      }
    }

    // Find favorite category
    final categoryCounts = <PlaceCategory, int>{};
    for (final place in _places) {
      categoryCounts[place.category] =
          (categoryCounts[place.category] ?? 0) + place.visitCount;
    }

    PlaceCategory? favoriteCategory;
    int maxCategoryVisits = 0;
    categoryCounts.forEach((category, count) {
      if (count > maxCategoryVisits) {
        maxCategoryVisits = count;
        favoriteCategory = category;
      }
    });

    return {
      'total_places': _places.length,
      'total_visits': totalVisits,
      'most_visited': mostVisited?.name,
      'most_visited_count': maxVisits,
      'favorite_category': favoriteCategory?.label,
      'by_category': categoryCounts.map((k, v) => MapEntry(k.label, v)),
    };
  }

  /// Get all favorite places
  List<FavoritePlace> getAllPlaces() => List.unmodifiable(_places);

  /// Get places by category
  List<FavoritePlace> getPlacesByCategory(PlaceCategory category) {
    return _places.where((p) => p.category == category).toList();
  }

  /// Update place
  Future<void> updatePlace(
    String placeId, {
    String? name,
    String? description,
    String? customGreeting,
    PlaceCategory? category,
  }) async {
    final index = _places.indexWhere((p) => p.id == placeId);
    if (index == -1) return;

    final place = _places[index];
    _places[index] = FavoritePlace(
      id: place.id,
      name: name ?? place.name,
      latitude: place.latitude,
      longitude: place.longitude,
      category: category ?? place.category,
      description: description ?? place.description,
      customGreeting: customGreeting ?? place.customGreeting,
      visitCount: place.visitCount,
      lastVisit: place.lastVisit,
      createdAt: place.createdAt,
    );

    await _saveData();
  }

  /// Delete place
  Future<void> deletePlace(String placeId) async {
    _places.removeWhere((p) => p.id == placeId);
    _visitHistory.removeWhere((v) => v.placeId == placeId);
    await _saveData();
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.14159265359 / 180.0);

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'places': _places.map((p) => p.toJson()).toList(),
        'visitHistory': _visitHistory.map((v) => v.toJson()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationSurprises] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _places.clear();
        _places.addAll((data['places'] as List<dynamic>)
            .map((p) => FavoritePlace.fromJson(p as Map<String, dynamic>)));

        _visitHistory.clear();
        _visitHistory.addAll((data['visitHistory'] as List<dynamic>)
            .map((v) => LocationVisit.fromJson(v as Map<String, dynamic>)));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationSurprises] Load error: $e');
    }
  }
}

class FavoritePlace {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final PlaceCategory category;
  final String? description;
  final String? customGreeting;
  int visitCount;
  DateTime? lastVisit;
  final DateTime createdAt;

  FavoritePlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.description,
    this.customGreeting,
    required this.visitCount,
    this.lastVisit,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'category': category.name,
        'description': description,
        'customGreeting': customGreeting,
        'visitCount': visitCount,
        'lastVisit': lastVisit?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FavoritePlace.fromJson(Map<String, dynamic> json) => FavoritePlace(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        category: PlaceCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => PlaceCategory.other,
        ),
        description: json['description'] as String?,
        customGreeting: json['customGreeting'] as String?,
        visitCount: json['visitCount'] as int,
        lastVisit: json['lastVisit'] != null
            ? DateTime.parse(json['lastVisit'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class LocationVisit {
  final String placeId;
  final String placeName;
  final DateTime timestamp;

  const LocationVisit({
    required this.placeId,
    required this.placeName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'placeName': placeName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LocationVisit.fromJson(Map<String, dynamic> json) => LocationVisit(
        placeId: json['placeId'] as String,
        placeName: json['placeName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class DateSpotSuggestion {
  final FavoritePlace place;
  final String reason;
  final double confidence;

  const DateSpotSuggestion({
    required this.place,
    required this.reason,
    required this.confidence,
  });
}

enum PlaceCategory {
  cafe,
  restaurant,
  gym,
  work,
  home,
  park,
  shopping,
  entertainment,
  other;

  String get label {
    switch (this) {
      case PlaceCategory.cafe:
        return 'Café';
      case PlaceCategory.restaurant:
        return 'Restaurant';
      case PlaceCategory.gym:
        return 'Gym';
      case PlaceCategory.work:
        return 'Work';
      case PlaceCategory.home:
        return 'Home';
      case PlaceCategory.park:
        return 'Park';
      case PlaceCategory.shopping:
        return 'Shopping';
      case PlaceCategory.entertainment:
        return 'Entertainment';
      case PlaceCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case PlaceCategory.cafe:
        return '☕';
      case PlaceCategory.restaurant:
        return '🍽️';
      case PlaceCategory.gym:
        return '💪';
      case PlaceCategory.work:
        return '💼';
      case PlaceCategory.home:
        return '🏠';
      case PlaceCategory.park:
        return '🌳';
      case PlaceCategory.shopping:
        return '🛍️';
      case PlaceCategory.entertainment:
        return '🎉';
      case PlaceCategory.other:
        return '📍';
    }
  }
}
