import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Base service class for all new feature integrations
/// Provides common functionality for data persistence, AI context, and user preferences
class BaseFeatureService {
  static final BaseFeatureService _instance = BaseFeatureService._internal();

  factory BaseFeatureService() {
    return _instance;
  }

  BaseFeatureService._internal();

  late SharedPreferences _prefs;
  
  // Common data stores
  final Map<String, dynamic> _featureData = {};
  final Map<String, double> _userPreferences = {};
  final Map<String, int> _usageFrequency = {};
  final List<Map<String, dynamic>> _activityLog = [];

  // Initialize service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFeatureData();
    await _loadUserPreferences();
    if (kDebugMode) debugPrint('[BaseFeatureService] Initialized');
  }

  // ===== DATA PERSISTENCE =====
  Future<void> _loadFeatureData() async {
    final data = _prefs.getString('feature_data');
    if (data != null && data.isNotEmpty) {
      try {
        _featureData.addAll(jsonDecode(data) as Map<String, dynamic>);
      } catch (e) {
        if (kDebugMode) debugPrint('[BaseFeatureService] Error loading feature data: $e');
      }
    }
  }

  Future<void> _saveFeatureData() async {
    await _prefs.setString('feature_data', jsonEncode(_featureData));
  }

  Future<void> _loadUserPreferences() async {
    final prefData = _prefs.getString('feature_user_preferences');
    if (prefData != null) {
      try {
        final decoded = jsonDecode(prefData) as Map<String, dynamic>;
        _userPreferences.addAll(
          decoded.map((k, v) => MapEntry(k, (v as num).toDouble())),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[BaseFeatureService] Error loading preferences: $e');
      }
    }
  }

  Future<void> _saveUserPreferences() async {
    await _prefs.setString('feature_user_preferences', jsonEncode(_userPreferences));
  }

  // ===== FEATURE DATA MANAGEMENT =====
  T getFeatureData<T>(String key, {T? defaultValue}) {
    final value = _featureData[key];
    if (value == null) return defaultValue ?? value as T;
    return value as T;
  }

  void setFeatureData<T>(String key, T value) {
    _featureData[key] = value;
    _saveFeatureData();
  }

  void removeFeatureData(String key) {
    _featureData.remove(key);
    _saveFeatureData();
  }

  // ===== USER PREFERENCES =====
  double getUserPreference(String key, {double defaultValue = 0.5}) {
    return _userPreferences[key] ?? defaultValue;
  }

  void setUserPreference(String key, double value) {
    _userPreferences[key] = value.clamp(0.0, 1.0);
    _saveUserPreferences();
  }

  // ===== USAGE TRACKING =====
  int getUsageFrequency(String feature) {
    return _usageFrequency[feature] ?? 0;
  }

  void incrementUsageFrequency(String feature) {
    _usageFrequency[feature] = (_usageFrequency[feature] ?? 0) + 1;
    _saveFeatureData(); // Save usage data with feature data
  }

  // ===== ACTIVITY LOGGING =====
  void logActivity(String feature, String action, {Map<String, dynamic>? metadata}) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'feature': feature,
      'action': action,
      'metadata': metadata ?? {},
    };
    _activityLog.add(logEntry);
    
    // Keep only last 1000 entries
    if (_activityLog.length > 1000) {
      _activityLog.removeRange(0, _activityLog.length - 1000);
    }
  }

  List<Map<String, dynamic>> getActivityLog({String? feature, int limit = 50}) {
    var filtered = _activityLog;
    if (feature != null) {
      filtered = _activityLog.where((entry) => entry['feature'] == feature).toList();
    }
    return filtered.reversed.take(limit).toList();
  }

  // ===== AI CONTEXT INTEGRATION =====
  /// Prepare context for AI processing
  Future<Map<String, dynamic>> getAIContext() async {
    return {
      'feature_data': _featureData,
      'user_preferences': _userPreferences,
      'usage_frequency': _usageFrequency,
      'recent_activity': _activityLog.take(10).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Update AI with feature interaction results
  Future<void> updateAIContext(String feature, String interactionType, dynamic result) async {
    // This would integrate with the existing AICopilotService
    // For now, we'll just log it
    logActivity(feature, interactionType, metadata: {'result': result});
  }

  // ===== STATISTICS =====
  Future<Map<String, dynamic>> getFeatureStatistics() async {
    return {
      'total_features_tracked': _featureData.length,
      'total_preferences': _userPreferences.length,
      'most_used_feature': _usageFrequency.entries.isNotEmpty
          ? _usageFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'none',
      'activity_log_entries': _activityLog.length,
      'feature_keys': _featureData.keys.toList(),
    };
  }
}