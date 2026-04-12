import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Custom Theme Service - Allows users to create and manage custom themes
class CustomThemeService {
  static final CustomThemeService _instance = CustomThemeService._internal();
  factory CustomThemeService() => _instance;
  CustomThemeService._internal();

  static const String _customThemesKey = 'custom_themes';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Create a new custom theme
  Future<bool> createCustomTheme(CustomTheme theme) async {
    try {
      final themes = await getAllCustomThemes();
      themes.add(theme);
      final json = themes.map((t) => t.toJson()).toList();
      await _prefs.setString(_customThemesKey, jsonEncode(json));
      return true;
    } catch (e) {
      debugPrint('❌ Error creating custom theme: $e');
      return false;
    }
  }

  /// Get all custom themes
  Future<List<CustomTheme>> getAllCustomThemes() async {
    try {
      final json = _prefs.getString(_customThemesKey);
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List;
      return list.map((e) => CustomTheme.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Error loading custom themes: $e');
      return [];
    }
  }

  /// Get custom theme by ID
  Future<CustomTheme?> getCustomTheme(String id) async {
    final themes = await getAllCustomThemes();
    try {
      return themes.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update custom theme
  Future<bool> updateCustomTheme(CustomTheme theme) async {
    try {
      final themes = await getAllCustomThemes();
      final index = themes.indexWhere((t) => t.id == theme.id);
      if (index == -1) return false;
      themes[index] = theme;
      final json = themes.map((t) => t.toJson()).toList();
      await _prefs.setString(_customThemesKey, jsonEncode(json));
      return true;
    } catch (e) {
      debugPrint('❌ Error updating custom theme: $e');
      return false;
    }
  }

  /// Delete custom theme
  Future<bool> deleteCustomTheme(String id) async {
    try {
      final themes = await getAllCustomThemes();
      themes.removeWhere((t) => t.id == id);
      final json = themes.map((t) => t.toJson()).toList();
      await _prefs.setString(_customThemesKey, jsonEncode(json));
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting custom theme: $e');
      return false;
    }
  }

  /// Build ThemeData from CustomTheme
  ThemeData buildThemeData(CustomTheme theme) {
    final primaryColor = Color(int.parse(theme.primaryColor.replaceFirst('#', '0xff')));
    final accentColor = Color(int.parse(theme.accentColor.replaceFirst('#', '0xff')));
    final backgroundColor = Color(int.parse(theme.backgroundColor.replaceFirst('#', '0xff')));

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: theme.isDarkMode ? Brightness.dark : Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: accentColor,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
      ),
      brightness: theme.isDarkMode ? Brightness.dark : Brightness.light,
    );
  }
}

/// Custom Theme Model
class CustomTheme {
  final String id;
  final String name;
  final String primaryColor; // hex: #RRGGBB
  final String accentColor;
  final String backgroundColor;
  final String secondaryColor;
  final bool isDarkMode;
  final double? cornerRadius;
  final double? fontScale;
  final String animationType; // pulse, flow, shimmer, bounce, spin, ripple
  final double animationSpeed; // 0.5 (slow) to 2.0 (fast)
  final int usageCount;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isPublic; // For sharing

  CustomTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.secondaryColor,
    this.isDarkMode = true,
    this.cornerRadius = 12.0,
    this.fontScale = 1.0,
    this.animationType = 'pulse',
    this.animationSpeed = 1.0,
    this.usageCount = 0,
    DateTime? createdAt,
    DateTime? lastModified,
    this.isPublic = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryColor': primaryColor,
        'accentColor': accentColor,
        'backgroundColor': backgroundColor,
        'secondaryColor': secondaryColor,
        'isDarkMode': isDarkMode,
        'cornerRadius': cornerRadius,
        'fontScale': fontScale,
        'animationType': animationType,
        'animationSpeed': animationSpeed,
        'usageCount': usageCount,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'isPublic': isPublic,
      };

  factory CustomTheme.fromJson(Map<String, dynamic> json) => CustomTheme(
        id: json['id'],
        name: json['name'],
        primaryColor: json['primaryColor'],
        accentColor: json['accentColor'],
        backgroundColor: json['backgroundColor'],
        secondaryColor: json['secondaryColor'],
        isDarkMode: json['isDarkMode'] ?? true,
        cornerRadius: json['cornerRadius']?.toDouble() ?? 12.0,
        fontScale: json['fontScale']?.toDouble() ?? 1.0,
        animationType: json['animationType'] ?? 'pulse',
        animationSpeed: json['animationSpeed']?.toDouble() ?? 1.0,
        usageCount: json['usageCount'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        lastModified: DateTime.parse(json['lastModified']),
        isPublic: json['isPublic'] ?? false,
      );

  CustomTheme copyWith({
    String? id,
    String? name,
    String? primaryColor,
    String? accentColor,
    String? backgroundColor,
    String? secondaryColor,
    bool? isDarkMode,
    double? cornerRadius,
    double? fontScale,
    String? animationType,
    double? animationSpeed,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isPublic,
  }) =>
      CustomTheme(
        id: id ?? this.id,
        name: name ?? this.name,
        primaryColor: primaryColor ?? this.primaryColor,
        accentColor: accentColor ?? this.accentColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        secondaryColor: secondaryColor ?? this.secondaryColor,
        isDarkMode: isDarkMode ?? this.isDarkMode,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        fontScale: fontScale ?? this.fontScale,
        animationType: animationType ?? this.animationType,
        animationSpeed: animationSpeed ?? this.animationSpeed,
        usageCount: usageCount ?? this.usageCount,
        createdAt: createdAt ?? this.createdAt,
        lastModified: lastModified ?? this.lastModified,
        isPublic: isPublic ?? this.isPublic,
      );
}

/// Global instance
final customThemeService = CustomThemeService();


