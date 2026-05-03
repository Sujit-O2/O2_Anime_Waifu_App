import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 💧 Hydration & Nutrition Tracking Service
///
/// Voice-logged meals and water intake with nutritional analysis.
class HydrationNutritionService {
  HydrationNutritionService._();
  static final HydrationNutritionService instance =
      HydrationNutritionService._();

  final List<NutritionLog> _nutritionLogs = [];
  final List<HydrationLog> _hydrationLogs = [];

  int _totalMealsLogged = 0;
  int _totalWaterIntakeMl = 0;
  DateTime? _lastAnalysis;

  static const String _storageKey = 'hydration_nutrition_v1';
  static const int _maxHistory = 365; // 1 year of data

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint(
          '[HydrationNutrition] Initialized with $_totalMealsLogged meals logged');
  }

  /// Log a meal via voice input (simplified - in reality would use NLP to parse)
  Future<void> logMeal({
    required String description,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    required double sugar,
  }) async {
    final log = NutritionLog(
      timestamp: DateTime.now(),
      description: description,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
    );

    _nutritionLogs.insert(0, log);
    if (_nutritionLogs.length > _maxHistory) {
      _nutritionLogs.removeLast();
    }

    _totalMealsLogged++;
    _lastAnalysis = DateTime.now();

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[HydrationNutrition] Meal logged: $description ($calories cal)');
  }

  /// Log water intake
  Future<void> logWaterIntake(int amountMl) async {
    if (amountMl <= 0) return;

    final log = HydrationLog(
      timestamp: DateTime.now(),
      amountMl: amountMl,
    );

    _hydrationLogs.insert(0, log);
    if (_hydrationLogs.length > _maxHistory) {
      _hydrationLogs.removeLast();
    }

    _totalWaterIntakeMl += amountMl;
    _lastAnalysis = DateTime.now();

    await _saveData();

    if (kDebugMode)
      debugPrint('[HydrationNutrition] Water logged: $amountMl ml');
  }

  String getNutritionInsights() {
    if (_nutritionLogs.isEmpty) {
      return 'Start logging your meals to get nutrition insights!';
    }

    final today = DateTime.now();
    final todayLogs = _nutritionLogs
        .where((log) =>
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day)
        .toList();

    if (todayLogs.isEmpty) {
      return 'Log some meals today to get daily nutrition insights.';
    }

    final totalCalories =
        todayLogs.fold<int>(0, (sum, log) => sum + log.calories);
    final totalProtein =
        todayLogs.fold<double>(0, (sum, log) => sum + log.protein);
    final totalCarbs = todayLogs.fold<double>(0, (sum, log) => sum + log.carbs);
    final totalFat = todayLogs.fold<double>(0, (sum, log) => sum + log.fat);

    final buffer = StringBuffer();
    buffer.writeln('🍽️ Today\'s Nutrition:');
    buffer.writeln('• Calories: $totalCalories kcal');
    buffer.writeln('• Protein: ${totalProtein.toStringAsFixed(1)}g');
    buffer.writeln('• Carbs: ${totalCarbs.toStringAsFixed(1)}g');
    buffer.writeln('• Fat: ${totalFat.toStringAsFixed(1)}g');

    // Simple feedback based on general guidelines
    if (totalCalories < 1200) {
      buffer.writeln('⚠️ Calorie intake seems low for most adults');
    } else if (totalCalories > 2500) {
      buffer.writeln('⚠️ Calorie intake seems high for most adults');
    }

    if (totalProtein < 50) {
      buffer.writeln(
          '💡 Consider increasing protein intake for muscle maintenance');
    }

    return buffer.toString();
  }

  String getHydrationInsights() {
    if (_hydrationLogs.isEmpty) {
      return 'Start logging your water intake to get hydration insights!';
    }

    final today = DateTime.now();
    final todayLogs = _hydrationLogs
        .where((log) =>
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day)
        .toList();

    final totalToday = todayLogs.fold<int>(0, (sum, log) => sum + log.amountMl);

    final buffer = StringBuffer();
    buffer.writeln('💧 Today\'s Hydration:');
    buffer.writeln('• Water Intake: $totalToday ml');

    if (totalToday < 1500) {
      buffer.writeln('⚠️ Below recommended intake (2L/day)');
      buffer.writeln('💡 Try drinking a glass of water every hour');
    } else if (totalToday < 2000) {
      buffer.writeln('💡 Getting close to goal! Aim for 2000ml+ daily');
    } else {
      buffer.writeln('🌟 Excellent hydration! Keep it up');
    }

    return buffer.toString();
  }

  String getDailyRecommendations() {
    final recommendations = <String>[];

    // Hydration recommendation
    final today = DateTime.now();
    final todayWater = _hydrationLogs
        .where((log) =>
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day)
        .fold<int>(0, (sum, log) => sum + log.amountMl);

    if (todayWater < 1500) {
      recommendations.add('Drink 500ml of water now to start hydrating');
    } else if (todayWater < 2000) {
      recommendations
          .add('Have another glass of water to reach your daily goal');
    }

    // Nutrition recommendation
    final todayMeals = _nutritionLogs
        .where((log) =>
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day)
        .toList();

    if (todayMeals.isEmpty) {
      recommendations.add('Log your first meal of the day');
    } else {
      final totalCalories =
          todayMeals.fold<int>(0, (sum, log) => sum + log.calories);
      if (totalCalories < 800 && today.hour > 12) {
        // If it's afternoon and low calories
        recommendations
            .add('Consider a nutritious lunch to fuel your afternoon');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('You\'re doing great with hydration and nutrition!');
    }

    return '🎯 Daily Recommendations: ${recommendations.join(' • ')}';
  }

  List<NutritionLog> getRecentMeals({int limit = 10}) {
    return List.unmodifiable(_nutritionLogs.take(limit));
  }

  List<HydrationLog> getRecentWaterLogs({int limit = 10}) {
    return List.unmodifiable(_hydrationLogs.take(limit));
  }

  int getTodayWaterIntakeMl() {
    final today = DateTime.now();
    return _hydrationLogs
        .where((log) =>
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day)
        .fold<int>(0, (sum, log) => sum + log.amountMl);
  }

  int getTodayCalories() {
    final today = DateTime.now();
    return _nutritionLogs
        .where((log) =>
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day)
        .fold<int>(0, (sum, log) => sum + log.calories);
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'nutritionLogs':
            _nutritionLogs.take(50).map((l) => l.toJson()).toList(),
        'hydrationLogs':
            _hydrationLogs.take(50).map((l) => l.toJson()).toList(),
        'totalMealsLogged': _totalMealsLogged,
        'totalWaterIntakeMl': _totalWaterIntakeMl,
        'lastAnalysis': _lastAnalysis?.toIso8601String(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[HydrationNutrition] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _nutritionLogs.clear();
        _nutritionLogs.addAll((data['nutritionLogs'] as List<dynamic>)
            .map((l) => NutritionLog.fromJson(l as Map<String, dynamic>)));

        _hydrationLogs.clear();
        _hydrationLogs.addAll((data['hydrationLogs'] as List<dynamic>)
            .map((l) => HydrationLog.fromJson(l as Map<String, dynamic>)));

        _totalMealsLogged = data['totalMealsLogged'] as int;
        _totalWaterIntakeMl = data['totalWaterIntakeMl'] as int;

        if (data['lastAnalysis'] != null) {
          _lastAnalysis = DateTime.parse(data['lastAnalysis'] as String);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[HydrationNutrition] Load error: $e');
    }
  }
}

class NutritionLog {
  final DateTime timestamp;
  final String description;
  final int calories; // kcal
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  final double fiber; // grams
  final double sugar; // grams

  NutritionLog({
    required this.timestamp,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'description': description,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
      };

  factory NutritionLog.fromJson(Map<String, dynamic> json) => NutritionLog(
        timestamp: DateTime.parse(json['timestamp']),
        description: json['description'],
        calories: json['calories'] as int,
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        fiber: (json['fiber'] as num).toDouble(),
        sugar: (json['sugar'] as num).toDouble(),
      );
}

class HydrationLog {
  final DateTime timestamp;
  final int amountMl; // milliliters

  HydrationLog({
    required this.timestamp,
    required this.amountMl,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'amountMl': amountMl,
      };

  factory HydrationLog.fromJson(Map<String, dynamic> json) => HydrationLog(
        timestamp: DateTime.parse(json['timestamp']),
        amountMl: json['amountMl'] as int,
      );
}
