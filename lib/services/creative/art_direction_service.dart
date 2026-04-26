import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎨 Art Direction Assistant Service
///
/// Suggest visual concepts, color palettes, or design elements.
class ArtDirectionService {
  ArtDirectionService._();
  static final ArtDirectionService instance = ArtDirectionService._();

  final List<DesignProject> _projects = [];
  final List<ColorPalette> _palettes = [];
  final List<VisualConcept> _concepts = [];

  int _totalProjects = 0;
  int _totalPalettes = 0;

  static const String _storageKey = 'art_direction_v1';

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint('[ArtDirection] Initialized with $_totalProjects projects');
  }

  Future<DesignProject> createDesignProject({
    required String title,
    required DesignType type,
    required String description,
    required String targetAudience,
    required String mood,
  }) async {
    final project = DesignProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
      description: description,
      targetAudience: targetAudience,
      mood: mood,
      status: DesignStatus.planning,
      palettes: [],
      concepts: [],
      elements: [],
      inspiration: '',
      notes: '',
      createdAt: DateTime.now(),
    );

    _projects.insert(0, project);
    _totalProjects++;

    await _saveData();

    if (kDebugMode) debugPrint('[ArtDirection] Created project: $title');
    return project;
  }

  Future<ColorPalette> generateColorPalette({
    required String name,
    required String baseColor,
    required PaletteType type,
    required String mood,
    String? description,
  }) async {
    final colors = _generateColors(baseColor, type, mood);

    final palette = ColorPalette(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      baseColor: baseColor,
      type: type,
      mood: mood,
      colors: colors,
      description: description ?? _generatePaletteDescription(type, mood),
      usage: [],
      createdAt: DateTime.now(),
    );

    _palettes.insert(0, palette);
    _totalPalettes++;

    await _saveData();

    if (kDebugMode) debugPrint('[ArtDirection] Generated palette: $name');
    return palette;
  }

  List<String> _generateColors(
      String baseColor, PaletteType type, String mood) {
    // Simplified color generation - in reality would use color theory
    final colors = <String>[];

    switch (type) {
      case PaletteType.monochromatic:
        colors.add(baseColor);
        colors.add(_adjustBrightness(baseColor, 0.8));
        colors.add(_adjustBrightness(baseColor, 0.6));
        colors.add(_adjustBrightness(baseColor, 0.4));
        colors.add(_adjustBrightness(baseColor, 0.2));
        break;
      case PaletteType.analogous:
        colors.add(baseColor);
        colors.add(_shiftHue(baseColor, 30));
        colors.add(_shiftHue(baseColor, 60));
        colors.add(_shiftHue(baseColor, -30));
        colors.add(_shiftHue(baseColor, -60));
        break;
      case PaletteType.complementary:
        colors.add(baseColor);
        colors.add(_shiftHue(baseColor, 180));
        colors.add(_adjustBrightness(baseColor, 0.8));
        colors.add(_adjustBrightness(_shiftHue(baseColor, 180), 0.8));
        colors.add('#FFFFFF');
        break;
      case PaletteType.triadic:
        colors.add(baseColor);
        colors.add(_shiftHue(baseColor, 120));
        colors.add(_shiftHue(baseColor, 240));
        colors.add(_adjustBrightness(baseColor, 0.7));
        colors.add(_adjustBrightness(_shiftHue(baseColor, 120), 0.7));
        break;
      case PaletteType.gradient:
        colors.add(baseColor);
        colors.add(_shiftHue(baseColor, 45));
        colors.add(_shiftHue(baseColor, 90));
        colors.add(_adjustBrightness(baseColor, 1.2));
        colors.add(_adjustBrightness(_shiftHue(baseColor, 90), 0.8));
        break;
    }

    return colors;
  }

  String _adjustBrightness(String color, double factor) {
    // Simplified brightness adjustment
    if (color.startsWith('#')) {
      color = color.substring(1);
    }

    try {
      final r = (int.parse(color.substring(0, 2), radix: 16) * factor)
          .clamp(0, 255)
          .toInt();
      final g = (int.parse(color.substring(2, 4), radix: 16) * factor)
          .clamp(0, 255)
          .toInt();
      final b = (int.parse(color.substring(4, 6), radix: 16) * factor)
          .clamp(0, 255)
          .toInt();

      return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    } catch (e) {
      return color;
    }
  }

  String _shiftHue(String color, double degrees) {
    // Simplified hue shift
    if (color.startsWith('#')) {
      color = color.substring(1);
    }

    try {
      var r = int.parse(color.substring(0, 2), radix: 16) / 255;
      var g = int.parse(color.substring(2, 4), radix: 16) / 255;
      var b = int.parse(color.substring(4, 6), radix: 16) / 255;

      // Simple RGB shift (not true hue rotation, but good enough for demo)
      r = (r + degrees / 360).clamp(0.0, 1.0);
      g = (g + degrees / 360).clamp(0.0, 1.0);
      b = (b + degrees / 360).clamp(0.0, 1.0);

      return '#${(r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(b * 255).toInt().toRadixString(16).padLeft(2, '0')}';
    } catch (e) {
      return color;
    }
  }

  String _generatePaletteDescription(PaletteType type, String mood) {
    switch (type) {
      case PaletteType.monochromatic:
        return 'A sophisticated $mood palette using variations of a single hue for harmony and elegance';
      case PaletteType.analogous:
        return 'A smooth $mood palette with adjacent colors that blend naturally';
      case PaletteType.complementary:
        return 'A vibrant $mood palette using contrasting colors for maximum impact';
      case PaletteType.triadic:
        return 'A balanced $mood palette with three evenly spaced colors for visual interest';
      case PaletteType.gradient:
        return 'A flowing $mood palette that transitions smoothly between colors';
    }
  }

  Future<VisualConcept> createVisualConcept({
    required String title,
    required String description,
    required ConceptType type,
    required List<String> elements,
    required String style,
    String? referenceImages,
  }) async {
    final concept = VisualConcept(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: type,
      elements: elements,
      style: style,
      referenceImages: referenceImages,
      status: ConceptStatus.draft,
      createdAt: DateTime.now(),
    );

    _concepts.insert(0, concept);

    await _saveData();

    if (kDebugMode) debugPrint('[ArtDirection] Created concept: $title');
    return concept;
  }

  Future<void> addPaletteToProject(String projectId, String paletteId) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final project = _projects[projectIndex];
    if (!project.palettes.contains(paletteId)) {
      _projects[projectIndex] = project.copyWith(
        palettes: [...project.palettes, paletteId],
      );
      await _saveData();
    }
  }

  Future<void> addConceptToProject(String projectId, String conceptId) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final project = _projects[projectIndex];
    if (!project.concepts.contains(conceptId)) {
      _projects[projectIndex] = project.copyWith(
        concepts: [...project.concepts, conceptId],
      );
      await _saveData();
    }
  }

  Future<void> updateProjectStatus(
      String projectId, DesignStatus status) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final project = _projects[projectIndex];
    _projects[projectIndex] = project.copyWith(status: status);

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[ArtDirection] Updated project status: $projectId -> $status');
  }

  String getColorSuggestions({
    required String mood,
    required DesignType type,
    String? targetAudience,
  }) {
    final suggestions = <String>[];

    switch (mood.toLowerCase()) {
      case 'energetic':
        suggestions.addAll([
          '🔥 Warm oranges and reds for excitement',
          '⚡ Bright yellows for energy and optimism',
          '💪 Bold primary colors for impact',
        ]);
        break;
      case 'calm':
        suggestions.addAll([
          '🌊 Soft blues for tranquility',
          '🌿 Gentle greens for relaxation',
          '☁️ Light pastels for serenity',
        ]);
        break;
      case 'luxury':
        suggestions.addAll([
          '👑 Deep purples and golds for elegance',
          '💎 Rich blacks with metallic accents',
          '🌟 Jewel tones for sophistication',
        ]);
        break;
      case 'playful':
        suggestions.addAll([
          '🌈 Bright rainbow colors for fun',
          '🎨 Unexpected color combinations',
          '✨ Vibrant and saturated hues',
        ]);
        break;
      case 'professional':
        suggestions.addAll([
          '💼 Blues and grays for trust',
          '📊 Clean whites with accent colors',
          '🎯 Muted, sophisticated tones',
        ]);
        break;
      case 'romantic':
        suggestions.addAll([
          '💕 Soft pinks and reds',
          '🌹 Warm tones for intimacy',
          '🕯️ Candlelight-inspired palette',
        ]);
        break;
    }

    switch (type) {
      case DesignType.branding:
        suggestions.add(
            '🎯 Consider how colors will look across all brand touchpoints');
        suggestions.add('📱 Test colors on different screens and devices');
        break;
      case DesignType.web:
        suggestions.add('🌐 Ensure good contrast for web accessibility');
        suggestions.add('📱 Consider how colors render on mobile');
        break;
      case DesignType.print:
        suggestions.add('🖨️ Remember CMYK conversion for print');
        suggestions.add('📄 Test colors in physical mockups');
        break;
      case DesignType.ui:
        suggestions.add('🎨 Create a clear hierarchy with color');
        suggestions.add('🔍 Ensure interactive elements stand out');
        break;
      case DesignType.illustration:
        suggestions.add('✨ Use color to guide the eye through the composition');
        suggestions.add('🎭 Consider emotional impact of color choices');
        break;
    }

    if (targetAudience != null) {
      suggestions.add(
          '👥 Consider color preferences and cultural meanings for $targetAudience');
    }

    return '🎨 Color Suggestions for $mood mood (${type.label}):\n' +
        suggestions.map((s) => '• $s').join('\n');
  }

  String getDesignPrinciples(DesignType type) {
    final principles = <String>[];

    switch (type) {
      case DesignType.branding:
        principles.addAll([
          '🎯 Consistency across all touchpoints',
          '💡 Memorable and distinctive',
          '🎨 Appropriate for target audience',
          '📈 Scalable and versatile',
          '⏰ Timeless over trendy',
        ]);
        break;
      case DesignType.web:
        principles.addAll([
          '🌐 Clear navigation and information hierarchy',
          '📱 Responsive design for all devices',
          '⚡ Fast loading times',
          '♿ Accessible to all users',
          '🎯 Clear calls to action',
        ]);
        break;
      case DesignType.print:
        principles.addAll([
          '📄 Clear typography and readable text',
          '🎨 Effective use of white space',
          '🖨️ High-quality images and graphics',
          '📐 Proper margins and alignment',
          '🎯 Clear visual hierarchy',
        ]);
        break;
      case DesignType.ui:
        principles.addAll([
          '🎯 User-centered design',
          '🔍 Clear feedback for interactions',
          '🎨 Consistent interface patterns',
          '⚡ Fast and responsive interactions',
          '♿ Accessible to users with disabilities',
        ]);
        break;
      case DesignType.illustration:
        principles.addAll([
          '✨ Clear focal point',
          '🎨 Harmonious color palette',
          '📐 Balanced composition',
          '🎭 Expressive and engaging',
          '🎯 Appropriate style for context',
        ]);
        break;
    }

    return '📐 Design Principles for ${type.label}:\n' +
        principles.map((p) => '• $p').join('\n');
  }

  String getArtInsights() {
    if (_projects.isEmpty && _palettes.isEmpty) {
      return 'No design projects or palettes created yet. Start exploring visual concepts!';
    }

    final buffer = StringBuffer();
    buffer.writeln('🎨 Art Direction Insights:');
    buffer.writeln('• Total Projects: $_totalProjects');
    buffer.writeln('• Total Palettes: $_totalPalettes');
    buffer.writeln('• Total Concepts: ${_concepts.length}');

    if (_projects.isNotEmpty) {
      final byStatus = <DesignStatus, int>{};
      for (final project in _projects) {
        byStatus[project.status] = (byStatus[project.status] ?? 0) + 1;
      }

      buffer.writeln('');
      buffer.writeln('Projects by Status:');
      for (final entry in byStatus.entries) {
        buffer.writeln('  • ${entry.key.label}: ${entry.value}');
      }
    }

    if (_palettes.isNotEmpty) {
      final byType = <PaletteType, int>{};
      for (final palette in _palettes) {
        byType[palette.type] = (byType[palette.type] ?? 0) + 1;
      }

      buffer.writeln('');
      buffer.writeln('Palettes by Type:');
      for (final entry in byType.entries) {
        buffer.writeln('  • ${entry.key.label}: ${entry.value}');
      }
    }

    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'projects': _projects.take(20).map((p) => p.toJson()).toList(),
        'palettes': _palettes.take(50).map((p) => p.toJson()).toList(),
        'concepts': _concepts.take(50).map((c) => c.toJson()).toList(),
        'totalProjects': _totalProjects,
        'totalPalettes': _totalPalettes,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[ArtDirection] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _projects.clear();
        _projects.addAll((data['projects'] as List<dynamic>? ?? [])
            .map((p) => DesignProject.fromJson(p as Map<String, dynamic>)));

        _palettes.clear();
        _palettes.addAll((data['palettes'] as List<dynamic>? ?? [])
            .map((p) => ColorPalette.fromJson(p as Map<String, dynamic>)));

        _concepts.clear();
        _concepts.addAll((data['concepts'] as List<dynamic>? ?? [])
            .map((c) => VisualConcept.fromJson(c as Map<String, dynamic>)));

        _totalProjects = data['totalProjects'] as int? ?? 0;
        _totalPalettes = data['totalPalettes'] as int? ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ArtDirection] Load error: $e');
    }
  }
}

class DesignProject {
  final String id;
  final String title;
  final DesignType type;
  final String description;
  final String targetAudience;
  final String mood;
  DesignStatus status;
  final List<String> palettes;
  final List<String> concepts;
  final List<String> elements;
  final String inspiration;
  final String notes;
  final DateTime createdAt;

  DesignProject({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.targetAudience,
    required this.mood,
    required this.status,
    required this.palettes,
    required this.concepts,
    required this.elements,
    required this.inspiration,
    required this.notes,
    required this.createdAt,
  });

  DesignProject copyWith({
    DesignStatus? status,
    List<String>? palettes,
    List<String>? concepts,
    List<String>? elements,
    String? inspiration,
    String? notes,
  }) {
    return DesignProject(
      id: id,
      title: title,
      type: type,
      description: description,
      targetAudience: targetAudience,
      mood: mood,
      status: status ?? this.status,
      palettes: palettes ?? this.palettes,
      concepts: concepts ?? this.concepts,
      elements: elements ?? this.elements,
      inspiration: inspiration ?? this.inspiration,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'description': description,
        'targetAudience': targetAudience,
        'mood': mood,
        'status': status.name,
        'palettes': palettes,
        'concepts': concepts,
        'elements': elements,
        'inspiration': inspiration,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DesignProject.fromJson(Map<String, dynamic> json) => DesignProject(
        id: json['id'],
        title: json['title'],
        type: DesignType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DesignType.branding,
        ),
        description: json['description'],
        targetAudience: json['targetAudience'],
        mood: json['mood'],
        status: DesignStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DesignStatus.planning,
        ),
        palettes: List<String>.from(json['palettes'] ?? []),
        concepts: List<String>.from(json['concepts'] ?? []),
        elements: List<String>.from(json['elements'] ?? []),
        inspiration: json['inspiration'] ?? '',
        notes: json['notes'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class ColorPalette {
  final String id;
  final String name;
  final String baseColor;
  final PaletteType type;
  final String mood;
  final List<String> colors;
  final String description;
  final List<String> usage;
  final DateTime createdAt;

  ColorPalette({
    required this.id,
    required this.name,
    required this.baseColor,
    required this.type,
    required this.mood,
    required this.colors,
    required this.description,
    required this.usage,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseColor': baseColor,
        'type': type.name,
        'mood': mood,
        'colors': colors,
        'description': description,
        'usage': usage,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ColorPalette.fromJson(Map<String, dynamic> json) => ColorPalette(
        id: json['id'],
        name: json['name'],
        baseColor: json['baseColor'],
        type: PaletteType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => PaletteType.analogous,
        ),
        mood: json['mood'],
        colors: List<String>.from(json['colors'] ?? []),
        description: json['description'] ?? '',
        usage: List<String>.from(json['usage'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class VisualConcept {
  final String id;
  final String title;
  final String description;
  final ConceptType type;
  final List<String> elements;
  final String style;
  final String? referenceImages;
  ConceptStatus status;
  final DateTime createdAt;

  VisualConcept({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.elements,
    required this.style,
    this.referenceImages,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'elements': elements,
        'style': style,
        'referenceImages': referenceImages,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VisualConcept.fromJson(Map<String, dynamic> json) => VisualConcept(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        type: ConceptType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ConceptType.moodboard,
        ),
        elements: List<String>.from(json['elements'] ?? []),
        style: json['style'],
        referenceImages: json['referenceImages'],
        status: ConceptStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ConceptStatus.draft,
        ),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

enum DesignType {
  branding('Branding'),
  web('Web Design'),
  print('Print Design'),
  ui('UI/UX'),
  illustration('Illustration');

  final String label;
  const DesignType(this.label);
}

enum DesignStatus {
  planning('Planning'),
  inProgress('In Progress'),
  review('Review'),
  completed('Completed');

  final String label;
  const DesignStatus(this.label);
}

enum PaletteType {
  monochromatic('Monochromatic'),
  analogous('Analogous'),
  complementary('Complementary'),
  triadic('Triadic'),
  gradient('Gradient');

  final String label;
  const PaletteType(this.label);
}

enum ConceptType {
  moodboard('Moodboard'),
  wireframe('Wireframe'),
  mockup('Mockup'),
  storyboard('Storyboard'),
  sketch('Sketch');

  final String label;
  const ConceptType(this.label);
}

enum ConceptStatus {
  draft('Draft'),
  review('Review'),
  approved('Approved'),
  implemented('Implemented');

  final String label;
  const ConceptStatus(this.label);
}
