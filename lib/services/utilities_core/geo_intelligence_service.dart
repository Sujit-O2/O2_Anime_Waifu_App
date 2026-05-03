// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// ═══════════════════════════════════════════════════════════════════════════
/// GEO INTELLIGENCE SERVICE — v10.0.2
/// High-performance GIS: geo-fencing, heatmaps, smart location memory,
/// place clustering, travel path, and location-based AI triggers.
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Data Models ─────────────────────────────────────────────────────────────

class GeoPoint {
  final double lat;
  final double lng;
  final DateTime timestamp;
  final String? label;
  final int visitCount;

  const GeoPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.label,
    this.visitCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'ts': timestamp.millisecondsSinceEpoch,
        'label': label,
        'visits': visitCount,
      };

  factory GeoPoint.fromJson(Map<String, dynamic> j) => GeoPoint(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
        label: j['label'] as String?,
        visitCount: (j['visits'] as int?) ?? 1,
      );

  /// Haversine distance in meters
  double distanceTo(GeoPoint other) =>
      GeoIntelligenceService.haversine(lat, lng, other.lat, other.lng);
}

class GeoFence {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;
  final String triggerMessage;
  final bool active;
  final DateTime createdAt;

  const GeoFence({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.triggerMessage,
    this.active = true,
    required this.createdAt,
  });

  bool contains(double pLat, double pLng) {
    return GeoIntelligenceService.haversine(lat, lng, pLat, pLng) <=
        radiusMeters;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'radius': radiusMeters,
        'msg': triggerMessage,
        'active': active,
        'created': createdAt.millisecondsSinceEpoch,
      };

  factory GeoFence.fromJson(Map<String, dynamic> j) => GeoFence(
        id: j['id'] as String,
        name: j['name'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        radiusMeters: (j['radius'] as num).toDouble(),
        triggerMessage: j['msg'] as String,
        active: (j['active'] as bool?) ?? true,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(j['created'] as int),
      );
}

class PlaceCluster {
  final double lat;
  final double lng;
  final int visitCount;
  final String? inferredLabel;
  final double heatIntensity; // 0.0 – 1.0

  const PlaceCluster({
    required this.lat,
    required this.lng,
    required this.visitCount,
    this.inferredLabel,
    required this.heatIntensity,
  });
}

class LocationEvent {
  final String type; // 'enter_fence' | 'exit_fence' | 'new_place' | 'home' | 'frequent'
  final String message;
  final GeoPoint location;
  final DateTime timestamp;

  const LocationEvent({
    required this.type,
    required this.message,
    required this.location,
    required this.timestamp,
  });
}

// ─── Service ─────────────────────────────────────────────────────────────────

class GeoIntelligenceService {
  static final GeoIntelligenceService _instance =
      GeoIntelligenceService._internal();
  factory GeoIntelligenceService() => _instance;
  GeoIntelligenceService._internal();

  // State
  Position? _lastPosition;
  final List<GeoPoint> _history = [];
  final List<GeoFence> _fences = [];
  final Set<String> _activeFences = {};
  List<PlaceCluster> _clusters = [];
  StreamSubscription<Position>? _positionSub;
  Timer? _clusterTimer;

  // Streams
  final _locationStream = StreamController<Position>.broadcast();
  final _eventStream = StreamController<LocationEvent>.broadcast();

  Stream<Position> get locationStream => _locationStream.stream;
  Stream<LocationEvent> get eventStream => _eventStream.stream;
  Position? get lastPosition => _lastPosition;
  List<GeoPoint> get history => List.unmodifiable(_history);
  List<GeoFence> get fences => List.unmodifiable(_fences);
  List<PlaceCluster> get clusters => List.unmodifiable(_clusters);

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<bool> initialize() async {
    await _loadFromPrefs();
    final perm = await _requestPermission();
    if (!perm) return false;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, // battery-friendly
        distanceFilter: 50, // only update after 50m movement
      ),
    ).listen(_onPosition, onError: (_) {});

    // Only start recluster timer if there are saved fences to monitor
    if (_fences.isNotEmpty) {
      _startClusterTimer();
    }

    return true;
  }

  Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ── Position Handler ──────────────────────────────────────────────────────

  void _onPosition(Position pos) {
    _lastPosition = pos;
    _locationStream.add(pos);

    final point = GeoPoint(
      lat: pos.latitude,
      lng: pos.longitude,
      timestamp: DateTime.now(),
    );

    // Deduplicate: only add if moved >30m from last recorded point
    if (_history.isEmpty ||
        _history.last.distanceTo(point) > 30) {
      _history.add(point);
      if (_history.length > 500) _history.removeAt(0); // cap at 500
      _saveHistory();
    }

    _checkFences(pos.latitude, pos.longitude);
    _checkFrequentPlace(point);
  }

  // ── Geo-Fencing ───────────────────────────────────────────────────────────

  void addFence(GeoFence fence) {
    _fences.add(fence);
    _saveFences();
    _startClusterTimer(); // ensure timer runs when geofencing is active
  }

  void removeFence(String id) {
    _fences.removeWhere((f) => f.id == id);
    _activeFences.remove(id);
    _saveFences();
    if (_fences.isEmpty) {
      _clusterTimer?.cancel(); // no fences left — stop the timer
    }
  }

  void _startClusterTimer() {
    if (_clusterTimer?.isActive ?? false) return;
    _clusterTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _recluster());
  }

  void _checkFences(double lat, double lng) {
    for (final fence in _fences) {
      if (!fence.active) continue;
      final inside = fence.contains(lat, lng);
      final wasInside = _activeFences.contains(fence.id);

      if (inside && !wasInside) {
        _activeFences.add(fence.id);
        _eventStream.add(LocationEvent(
          type: 'enter_fence',
          message: fence.triggerMessage,
          location: GeoPoint(lat: lat, lng: lng, timestamp: DateTime.now()),
          timestamp: DateTime.now(),
        ));
      } else if (!inside && wasInside) {
        _activeFences.remove(fence.id);
        _eventStream.add(LocationEvent(
          type: 'exit_fence',
          message: 'Left ${fence.name}',
          location: GeoPoint(lat: lat, lng: lng, timestamp: DateTime.now()),
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  // ── Clustering (DBSCAN-lite) ──────────────────────────────────────────────

  void _recluster() {
    if (_history.length < 3) return;
    _clusters = _dbscan(_history, eps: 100, minPts: 3);
  }

  List<PlaceCluster> _dbscan(
      List<GeoPoint> points, {
      required double eps,
      required int minPts,
    }) {
    final visited = <int>{};
    final clusters = <List<GeoPoint>>[];

    for (int i = 0; i < points.length; i++) {
      if (visited.contains(i)) continue;
      visited.add(i);

      final neighbors = _regionQuery(points, i, eps);
      if (neighbors.length < minPts) continue;

      final cluster = <GeoPoint>[points[i]];
      final queue = List<int>.from(neighbors);

      while (queue.isNotEmpty) {
        final j = queue.removeLast();
        if (!visited.contains(j)) {
          visited.add(j);
          final jNeighbors = _regionQuery(points, j, eps);
          if (jNeighbors.length >= minPts) {
            queue.addAll(jNeighbors.where((n) => !visited.contains(n)));
          }
        }
        cluster.add(points[j]);
      }
      clusters.add(cluster);
    }

    if (clusters.isEmpty) return [];

    final maxVisits = clusters.map((c) => c.length).reduce(math.max);

    return clusters.map((c) {
      final avgLat = c.map((p) => p.lat).reduce((a, b) => a + b) / c.length;
      final avgLng = c.map((p) => p.lng).reduce((a, b) => a + b) / c.length;
      return PlaceCluster(
        lat: avgLat,
        lng: avgLng,
        visitCount: c.length,
        heatIntensity: c.length / maxVisits,
        inferredLabel: _inferLabel(c),
      );
    }).toList()
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));
  }

  List<int> _regionQuery(List<GeoPoint> points, int idx, double eps) {
    final result = <int>[];
    for (int i = 0; i < points.length; i++) {
      if (i == idx) continue;
      if (points[idx].distanceTo(points[i]) <= eps) result.add(i);
    }
    return result;
  }

  String? _inferLabel(List<GeoPoint> cluster) {
    // Time-based heuristic: if most visits are 22:00–07:00 → "Home"
    final nightVisits = cluster
        .where((p) => p.timestamp.hour >= 22 || p.timestamp.hour <= 7)
        .length;
    if (nightVisits > cluster.length * 0.6) return 'Home 🏠';

    // Daytime weekday → "Work"
    final workVisits = cluster
        .where((p) =>
            p.timestamp.weekday <= 5 &&
            p.timestamp.hour >= 9 &&
            p.timestamp.hour <= 18)
        .length;
    if (workVisits > cluster.length * 0.5) return 'Work 💼';

    return null;
  }

  // ── Frequent Place Detection ──────────────────────────────────────────────

  void _checkFrequentPlace(GeoPoint point) {
    if (_clusters.isEmpty) return;
    for (final cluster in _clusters) {
      final dist = haversine(cluster.lat, cluster.lng, point.lat, point.lng);
      if (dist < 100 && cluster.visitCount >= 5) {
        final label = cluster.inferredLabel ?? 'a familiar place';
        _eventStream.add(LocationEvent(
          type: 'frequent',
          message: 'You\'re at $label again, darling~ 💕',
          location: point,
          timestamp: DateTime.now(),
        ));
        break;
      }
    }
  }

  // ── Heatmap Data ──────────────────────────────────────────────────────────

  /// Returns normalized heatmap points for rendering.
  /// Each entry: {lat, lng, intensity 0.0–1.0}
  List<Map<String, double>> getHeatmapData() {
    if (_history.isEmpty) return [];
    _recluster();
    return _clusters
        .map((c) => {
              'lat': c.lat,
              'lng': c.lng,
              'intensity': c.heatIntensity,
            })
        .toList();
  }

  /// Travel path as ordered list of lat/lng pairs.
  List<Map<String, double>> getTravelPath({int maxPoints = 100}) {
    final step = (_history.length / maxPoints).ceil().clamp(1, 999);
    return [
      for (int i = 0; i < _history.length; i += step)
        {'lat': _history[i].lat, 'lng': _history[i].lng}
    ];
  }

  // ── Smart Location Memory ─────────────────────────────────────────────────

  /// Returns a human-readable summary of the user's location patterns.
  String getLocationSummary() {
    if (_clusters.isEmpty) return 'No location data yet.';
    final top = _clusters.take(3).toList();
    final parts = top.map((c) {
      final label = c.inferredLabel ?? 'a place';
      return '$label (${c.visitCount} visits)';
    });
    return 'Frequent places: ${parts.join(', ')}.';
  }

  /// Returns the most likely current context label.
  String? getCurrentContextLabel() {
    if (_lastPosition == null) return null;
    for (final cluster in _clusters) {
      final dist = haversine(
          cluster.lat, cluster.lng, _lastPosition!.latitude, _lastPosition!.longitude);
      if (dist < 150) return cluster.inferredLabel;
    }
    return null;
  }

  // ── Haversine ─────────────────────────────────────────────────────────────

  static double haversine(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = _history.length > 200
          ? _history.sublist(_history.length - 200)
          : _history;
      await prefs.setString(
          'geo_history', jsonEncode(recent.map((p) => p.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _saveFences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'geo_fences', jsonEncode(_fences.map((f) => f.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final histJson = prefs.getString('geo_history');
      if (histJson != null) {
        final list = jsonDecode(histJson) as List;
        _history.addAll(list.map((e) => GeoPoint.fromJson(e as Map<String, dynamic>)));
      }

      final fenceJson = prefs.getString('geo_fences');
      if (fenceJson != null) {
        final list = jsonDecode(fenceJson) as List;
        _fences.addAll(list.map((e) => GeoFence.fromJson(e as Map<String, dynamic>)));
      }

      _recluster();
    } catch (_) {}
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    _positionSub?.cancel();
    _clusterTimer?.cancel();
    _locationStream.close();
    _eventStream.close();
  }
}
