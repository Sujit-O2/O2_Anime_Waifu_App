import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Email Template Builder - Create custom email designs
class EmailTemplateBuilder {
  static final EmailTemplateBuilder _instance =
      EmailTemplateBuilder._internal();
  factory EmailTemplateBuilder() => _instance;
  EmailTemplateBuilder._internal();

  static const String _templatesKey = 'email_templates';
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Create custom email template
  Future<String?> createTemplate(EmailTemplate template) async {
    try {
      final id = _generateId();
      final templateWithId = template.copyWith(id: id);

      final templates = _prefs.getString(_templatesKey) ?? '{}';
      final templatesMap = jsonDecode(templates) as Map<String, dynamic>;
      templatesMap[id] = templateWithId.toJson();

      await _prefs.setString(_templatesKey, jsonEncode(templatesMap));
      debugPrint('✅ Template created: $id');
      return id;
    } catch (e) {
      debugPrint('❌ Error creating template: $e');
      return null;
    }
  }

  /// Get all templates
  Future<List<EmailTemplate>> getAllTemplates() async {
    try {
      final templates = _prefs.getString(_templatesKey) ?? '{}';
      final templatesMap = jsonDecode(templates) as Map<String, dynamic>;
      return templatesMap.values
          .cast<Map<String, dynamic>>()
          .map((json) => EmailTemplate.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading templates: $e');
      return [];
    }
  }

  /// Get template by ID
  Future<EmailTemplate?> getTemplate(String id) async {
    try {
      final templates = _prefs.getString(_templatesKey) ?? '{}';
      final templatesMap = jsonDecode(templates) as Map<String, dynamic>;
      if (templatesMap.containsKey(id)) {
        return EmailTemplate.fromJson(templatesMap[id]);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting template: $e');
      return null;
    }
  }

  /// Update template
  Future<bool> updateTemplate(EmailTemplate template) async {
    try {
      final templates = _prefs.getString(_templatesKey) ?? '{}';
      final templatesMap = jsonDecode(templates) as Map<String, dynamic>;
      templatesMap[template.id] = template.toJson();
      await _prefs.setString(_templatesKey, jsonEncode(templatesMap));
      return true;
    } catch (e) {
      debugPrint('❌ Error updating template: $e');
      return false;
    }
  }

  /// Delete template
  Future<bool> deleteTemplate(String id) async {
    try {
      final templates = _prefs.getString(_templatesKey) ?? '{}';
      final templatesMap = jsonDecode(templates) as Map<String, dynamic>;
      templatesMap.remove(id);
      await _prefs.setString(_templatesKey, jsonEncode(templatesMap));
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting template: $e');
      return false;
    }
  }

  /// Generate HTML from template
  String generateHtml(EmailTemplate template, Map<String, String> variables) {
    String html = template.htmlContent;

    // Replace variables
    variables.forEach((key, value) {
      html = html.replaceAll('{{$key}}', value);
    });

    return html;
  }

  /// Build simple text email template
  String buildSimpleTemplate({
    required String title,
    required String message,
    required String backgroundColor,
    required String textColor,
  }) {
    return '''
    <html>
    <head>
      <style>
        body { background-color: $backgroundColor; color: $textColor; font-family: Arial, sans-serif; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { font-size: 24px; font-weight: bold; margin-bottom: 20px; }
        .message { font-size: 16px; line-height: 1.6; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">$title</div>
        <div class="message">$message</div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Build newsletter template
  String buildNewsletterTemplate({
    required String title,
    required String subtitle,
    required List<String> articles,
    required String accentColor,
  }) {
    final articleHtml = articles
        .map((article) =>
            '<div style="border-left: 4px solid $accentColor; padding-left: 15px; margin: 15px 0;">$article</div>')
        .join();

    return '''
    <html>
    <head>
      <style>
        body { background-color: #f5f5f5; font-family: Arial, sans-serif; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; }
        .header { color: $accentColor; font-size: 28px; font-weight: bold; margin-bottom: 10px; }
        .subtitle { color: #666; font-size: 14px; margin-bottom: 30px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">$title</div>
        <div class="subtitle">$subtitle</div>
        $articleHtml
      </div>
    </body>
    </html>
    ''';
  }

  /// Build promotional template
  String buildPromoTemplate({
    required String headline,
    required String description,
    required String ctaText,
    required String ctaUrl,
    required String imageUrl,
    required String primaryColor,
  }) {
    return '''
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; }
        .container { max-width: 600px; margin: 0 auto; }
        .banner { background: $primaryColor; color: white; padding: 40px; text-align: center; }
        .headline { font-size: 32px; font-weight: bold; margin-bottom: 15px; }
        .description { font-size: 16px; margin-bottom: 25px; line-height: 1.6; }
        .cta { background: white; color: $primaryColor; padding: 12px 30px; border-radius: 5px; text-decoration: none; font-weight: bold; display: inline-block; }
        .image { text-align: center; margin: 20px 0; }
        .image img { max-width: 100%; height: auto; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="banner">
          <div class="headline">$headline</div>
          <div class="description">$description</div>
          <a href="$ctaUrl" class="cta">$ctaText</a>
          <div class="image"><img src="$imageUrl" alt="Promo"></div>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  String _generateId() {
    return 'tmpl_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Email Template Model
class EmailTemplate {
  final String id;
  final String name;
  final String description;
  final String htmlContent;
  final List<String> variables; // Variables like {{name}}, {{url}}
  final String category; // personal, newsletter, promo, transactional
  final DateTime createdAt;
  final bool isPublic;

  EmailTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.htmlContent,
    required this.variables,
    required this.category,
    DateTime? createdAt,
    this.isPublic = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'htmlContent': htmlContent,
        'variables': variables,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'isPublic': isPublic,
      };

  factory EmailTemplate.fromJson(Map<String, dynamic> json) => EmailTemplate(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        htmlContent: json['htmlContent'],
        variables: List<String>.from(json['variables'] ?? []),
        category: json['category'],
        createdAt: DateTime.parse(json['createdAt']),
        isPublic: json['isPublic'] ?? false,
      );

  EmailTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? htmlContent,
    List<String>? variables,
    String? category,
    DateTime? createdAt,
    bool? isPublic,
  }) =>
      EmailTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        htmlContent: htmlContent ?? this.htmlContent,
        variables: variables ?? this.variables,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
        isPublic: isPublic ?? this.isPublic,
      );
}

/// Global instance
final emailTemplateBuilder = EmailTemplateBuilder();


