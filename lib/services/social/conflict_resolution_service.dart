import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🤝 Conflict Resolution Coach Service
///
/// Help navigate disagreements with communication strategies.
class ConflictResolutionService {
  ConflictResolutionService._();
  static final ConflictResolutionService instance =
      ConflictResolutionService._();

  final List<ConflictSession> _sessions = [];
  final List<CommunicationStrategy> _strategies = [];

  int _totalSessions = 0;
  int _resolvedConflicts = 0;

  static const String _storageKey = 'conflict_resolution_v1';

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint(
          '[ConflictResolution] Initialized with $_totalSessions sessions');
  }

  Future<ConflictSession> createSession({
    required String title,
    required String description,
    required ConflictType type,
    required int intensity,
    required List<String> involvedParties,
  }) async {
    final session = ConflictSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: type,
      intensity: intensity,
      involvedParties: involvedParties,
      status: ConflictStatus.identified,
      strategies: [],
      outcome: null,
      resolutionNotes: '',
      createdAt: DateTime.now(),
    );

    _sessions.insert(0, session);
    _totalSessions++;

    await _saveData();

    if (kDebugMode) debugPrint('[ConflictResolution] Created session: $title');
    return session;
  }

  Future<List<CommunicationStrategy>> getStrategiesForConflict({
    required ConflictType type,
    required int intensity,
    required List<String> involvedParties,
  }) async {
    final strategies = <CommunicationStrategy>[];

    // De-escalation strategies (always include for intensity > 5)
    if (intensity > 5) {
      strategies.addAll([
        CommunicationStrategy(
          name: 'Take a Break',
          description:
              'Step away for 20-30 minutes to cool down before continuing',
          category: StrategyCategory.deEscalation,
          effectiveness: 8,
          steps: [
            'Acknowledge the need for a pause',
            'Set a specific time to reconvene',
            'Use the time to reflect, not rehearse arguments',
          ],
        ),
        CommunicationStrategy(
          name: 'Lower Your Voice',
          description: 'Speak more softly and slowly to reduce tension',
          category: StrategyCategory.deEscalation,
          effectiveness: 7,
          steps: [
            'Take a deep breath before speaking',
            'Speak at half your normal volume',
            'Pause between sentences',
          ],
        ),
      ]);
    }

    // Type-specific strategies
    switch (type) {
      case ConflictType.miscommunication:
        strategies.addAll([
          CommunicationStrategy(
            name: 'Active Listening',
            description: 'Fully focus on understanding before responding',
            category: StrategyCategory.communication,
            effectiveness: 9,
            steps: [
              'Maintain eye contact',
              'Paraphrase what you heard',
              'Ask clarifying questions',
              'Validate their feelings',
            ],
          ),
          CommunicationStrategy(
            name: 'I-Statements',
            description: 'Express feelings without blaming',
            category: StrategyCategory.communication,
            effectiveness: 8,
            steps: [
              'Start with "I feel..."',
              'Describe the specific behavior',
              'Explain the impact on you',
              'State your need clearly',
            ],
          ),
        ]);
        break;

      case ConflictType.valuesDifference:
        strategies.addAll([
          CommunicationStrategy(
            name: 'Find Common Ground',
            description: 'Identify shared values and goals',
            category: StrategyCategory.collaboration,
            effectiveness: 8,
            steps: [
              'List shared values',
              'Identify common goals',
              'Focus on areas of agreement first',
              'Build from shared foundation',
            ],
          ),
          CommunicationStrategy(
            name: 'Seek to Understand',
            description: 'Explore the root of differing values',
            category: StrategyCategory.empathy,
            effectiveness: 7,
            steps: [
              'Ask open-ended questions',
              'Listen without judgment',
              'Acknowledge their perspective',
              'Share your own reasoning gently',
            ],
          ),
        ]);
        break;

      case ConflictType.expectations:
        strategies.addAll([
          CommunicationStrategy(
            name: 'Clarify Expectations',
            description: 'Make implicit expectations explicit',
            category: StrategyCategory.communication,
            effectiveness: 9,
            steps: [
              'State what you expected',
              'Ask what they expected',
              'Identify the gap',
              'Negotiate future expectations',
            ],
          ),
          CommunicationStrategy(
            name: 'Use Specific Examples',
            description: 'Ground discussion in concrete instances',
            category: StrategyCategory.communication,
            effectiveness: 8,
            steps: [
              'Describe specific situations',
              'Focus on behaviors, not character',
              'Use recent, clear examples',
              'Avoid generalizations',
            ],
          ),
        ]);
        break;

      case ConflictType.stress:
        strategies.addAll([
          CommunicationStrategy(
            name: 'Stress Acknowledgment',
            description: 'Recognize external stress as a factor',
            category: StrategyCategory.empathy,
            effectiveness: 8,
            steps: [
              'Acknowledge the stress',
              'Express understanding',
              'Offer support',
              'Suggest addressing stress first',
            ],
          ),
          CommunicationStrategy(
            name: 'Timing Check',
            description: 'Assess if this is the right time to discuss',
            category: StrategyCategory.deEscalation,
            effectiveness: 7,
            steps: [
              'Ask if this is a good time',
              'Suggest a better time if needed',
              'Commit to revisiting the topic',
              'Follow through on the commitment',
            ],
          ),
        ]);
        break;

      case ConflictType.trust:
        strategies.addAll([
          CommunicationStrategy(
            name: 'Rebuild Trust Gradually',
            description: 'Take small steps to restore confidence',
            category: StrategyCategory.relationship,
            effectiveness: 8,
            steps: [
              'Acknowledge the breach',
              'Make a specific commitment',
              'Follow through consistently',
              'Be patient with the process',
            ],
          ),
          CommunicationStrategy(
            name: 'Transparency Practice',
            description: 'Increase openness and information sharing',
            category: StrategyCategory.relationship,
            effectiveness: 7,
            steps: [
              'Volunteer information proactively',
              'Answer questions fully',
              'Check in about concerns',
              'Maintain consistency',
            ],
          ),
        ]);
        break;
    }

    // Party count strategies
    if (involvedParties.length > 2) {
      strategies.add(CommunicationStrategy(
        name: 'Structured Discussion',
        description: 'Ensure everyone has a chance to speak',
        category: StrategyCategory.communication,
        effectiveness: 8,
        steps: [
          'Set speaking order or time limits',
          'Use a talking object if helpful',
          'Summarize each person\'s view',
          'Look for common themes',
        ],
      ));
    }

    // Store strategies
    _strategies.addAll(strategies);

    return strategies;
  }

  Future<void> addStrategyToSession(
      String sessionId, CommunicationStrategy strategy) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final session = _sessions[sessionIndex];
    _sessions[sessionIndex] = session.copyWith(
      strategies: [...session.strategies, strategy],
    );

    await _saveData();
  }

  Future<void> updateSessionStatus(String sessionId, ConflictStatus status,
      {String? notes}) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final session = _sessions[sessionIndex];
    _sessions[sessionIndex] = session.copyWith(
      status: status,
      resolutionNotes: notes ?? session.resolutionNotes,
      resolvedAt: status == ConflictStatus.resolved ? DateTime.now() : null,
    );

    if (status == ConflictStatus.resolved) {
      _resolvedConflicts++;
    }

    await _saveData();

    if (kDebugMode)
      debugPrint('[ConflictResolution] Session updated: $sessionId -> $status');
  }

  String getDeEscalationTechniques() {
    final techniques = [
      '🗣️ Speak more softly and slowly',
      '😌 Take deep breaths before responding',
      '⏸️ Pause for 3 seconds before replying',
      '📍 Use the person\'s name gently',
      '🤝 Maintain open body language',
      '👀 Make soft eye contact',
      '💭 Acknowledge their feelings first',
      '🌟 Find something to agree with',
    ];

    return '🕊️ De-escalation Techniques:\n${techniques.join('\n')}';
  }

  String getActiveListeningPrompts() {
    final prompts = [
      '"What I hear you saying is..."',
      '"Help me understand..."',
      '"Can you say more about that?"',
      '"What\'s most important to you here?"',
      '"How did that make you feel?"',
      '"What do you need from me?"',
      '"Let me make sure I understand..."',
      '"What would help right now?"',
    ];

    return '👂 Active Listening Prompts:\n${prompts.join('\n')}';
  }

  String getIStatementTemplate() {
    return '''
🗣️ I-Statement Template:

"I feel [emotion] when [specific behavior] because [impact]. 
I need [specific request]."

Example:
"I feel hurt when plans change last minute because 
it makes me feel unimportant. I need a heads-up 
as soon as you know there might be a change."

💡 Tips:
• Use feeling words (frustrated, hurt, worried, etc.)
• Be specific about the behavior
• Focus on impact, not intent
• Make clear, doable requests
• Avoid "you" statements that blame
''';
  }

  String getConflictInsights() {
    if (_sessions.isEmpty) {
      return 'No conflict sessions recorded yet.';
    }

    final resolved =
        _sessions.where((s) => s.status == ConflictStatus.resolved).length;
    final inProgress =
        _sessions.where((s) => s.status == ConflictStatus.inProgress).length;
    final resolutionRate = _totalSessions > 0
        ? (resolved / _totalSessions * 100).toStringAsFixed(0)
        : '0';

    final avgIntensity =
        _sessions.fold<double>(0, (sum, s) => sum + s.intensity) /
            _sessions.length;

    final byType = <ConflictType, int>{};
    for (final session in _sessions) {
      byType[session.type] = (byType[session.type] ?? 0) + 1;
    }

    final buffer = StringBuffer();
    buffer.writeln('🤝 Conflict Resolution Insights:');
    buffer.writeln('• Total Sessions: $_totalSessions');
    buffer.writeln('• Resolved: $resolved');
    buffer.writeln('• In Progress: $inProgress');
    buffer.writeln('• Resolution Rate: $resolutionRate%');
    buffer
        .writeln('• Average Intensity: ${avgIntensity.toStringAsFixed(1)}/10');
    buffer.writeln('');
    buffer.writeln('Conflicts by Type:');
    for (final entry in byType.entries) {
      buffer.writeln('  • ${entry.key.label}: ${entry.value}');
    }

    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'sessions': _sessions.take(50).map((s) => s.toJson()).toList(),
        'strategies': _strategies.map((s) => s.toJson()).toList(),
        'totalSessions': _totalSessions,
        'resolvedConflicts': _resolvedConflicts,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[ConflictResolution] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _sessions.clear();
        _sessions.addAll((data['sessions'] as List<dynamic>)
            .map((s) => ConflictSession.fromJson(s as Map<String, dynamic>)));

        _strategies.clear();
        if (data['strategies'] != null) {
          _strategies.addAll((data['strategies'] as List<dynamic>).map((s) =>
              CommunicationStrategy.fromJson(s as Map<String, dynamic>)));
        }

        _totalSessions = data['totalSessions'] as int;
        _resolvedConflicts = data['resolvedConflicts'] as int;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ConflictResolution] Load error: $e');
    }
  }
}

class ConflictSession {
  final String id;
  final String title;
  final String description;
  final ConflictType type;
  final int intensity; // 1-10 scale
  final List<String> involvedParties;
  ConflictStatus status;
  final List<CommunicationStrategy> strategies;
  String? outcome;
  String resolutionNotes;
  DateTime? resolvedAt;
  final DateTime createdAt;

  ConflictSession({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.intensity,
    required this.involvedParties,
    required this.status,
    required this.strategies,
    this.outcome,
    required this.resolutionNotes,
    this.resolvedAt,
    required this.createdAt,
  });

  ConflictSession copyWith({
    ConflictStatus? status,
    List<CommunicationStrategy>? strategies,
    String? outcome,
    String? resolutionNotes,
    DateTime? resolvedAt,
  }) {
    return ConflictSession(
      id: id,
      title: title,
      description: description,
      type: type,
      intensity: intensity,
      involvedParties: involvedParties,
      status: status ?? this.status,
      strategies: strategies ?? this.strategies,
      outcome: outcome ?? this.outcome,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'intensity': intensity,
        'involvedParties': involvedParties,
        'status': status.name,
        'strategies': strategies.map((s) => s.toJson()).toList(),
        'outcome': outcome,
        'resolutionNotes': resolutionNotes,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ConflictSession.fromJson(Map<String, dynamic> json) =>
      ConflictSession(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        type: ConflictType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ConflictType.miscommunication,
        ),
        intensity: json['intensity'],
        involvedParties: List<String>.from(json['involvedParties'] ?? []),
        status: ConflictStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ConflictStatus.identified,
        ),
        strategies: (json['strategies'] as List<dynamic>? ?? [])
            .map((s) =>
                CommunicationStrategy.fromJson(s as Map<String, dynamic>))
            .toList(),
        outcome: json['outcome'],
        resolutionNotes: json['resolutionNotes'] ?? '',
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class CommunicationStrategy {
  final String name;
  final String description;
  final StrategyCategory category;
  final int effectiveness; // 1-10
  final List<String> steps;

  CommunicationStrategy({
    required this.name,
    required this.description,
    required this.category,
    required this.effectiveness,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category.name,
        'effectiveness': effectiveness,
        'steps': steps,
      };

  factory CommunicationStrategy.fromJson(Map<String, dynamic> json) =>
      CommunicationStrategy(
        name: json['name'],
        description: json['description'],
        category: StrategyCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => StrategyCategory.communication,
        ),
        effectiveness: json['effectiveness'],
        steps: List<String>.from(json['steps'] ?? []),
      );
}

enum ConflictType {
  miscommunication('Miscommunication'),
  valuesDifference('Values Difference'),
  expectations('Unmet Expectations'),
  stress('Stress-Related'),
  trust('Trust Issue');

  final String label;
  const ConflictType(this.label);
}

enum ConflictStatus { identified, inProgress, resolved, escalated }

enum StrategyCategory {
  communication('Communication'),
  deEscalation('De-escalation'),
  empathy('Empathy'),
  collaboration('Collaboration'),
  relationship('Relationship');

  final String label;
  const StrategyCategory(this.label);
}
