import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎯 Personalized Learning Paths Service
/// 
/// Curated content recommendations for skill acquisition.
class PersonalizedLearningService {
  PersonalizedLearningService._();
  static final PersonalizedLearningService instance = PersonalizedLearningService._();

  final List<LearningPath> _paths = [];
  final List<ContentRecommendation> _recommendations = [];
  final List<LearningSession> _sessions = [];
  
  int _totalPaths = 0;
  int _totalRecommendations = 0;
  int _totalSessions = 0;
  
  static const String _storageKey = 'personalized_learning_v1';
  static const int _maxPaths = 50;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[PersonalizedLearning] Initialized with $_totalPaths paths');
  }

  Future<LearningPath> createLearningPath({
    required String title,
    required String description,
    required SkillCategory category,
    required DifficultyLevel difficulty,
    required int estimatedHours,
    required List<String> topics,
    required List<String> prerequisites,
  }) async {
    final path = LearningPath(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      difficulty: difficulty,
      estimatedHours: estimatedHours,
      topics: topics,
      prerequisites: prerequisites,
      modules: [],
      status: PathStatus.notStarted,
      progress: 0,
      currentModule: 0,
      createdAt: DateTime.now(),
    );
    
    _paths.insert(0, path);
    _totalPaths++;
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[PersonalizedLearning] Created learning path: $title');
    return path;
  }

  Future<void> addModuleToPath({
    required String pathId,
    required String title,
    required String description,
    required List<String> resources,
    required int estimatedMinutes,
  }) async {
    final pathIndex = _paths.indexWhere((p) => p.id == pathId);
    if (pathIndex == -1) return;
    
    final module = LearningModule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      resources: resources,
      estimatedMinutes: estimatedMinutes,
      completed: false,
      createdAt: DateTime.now(),
    );
    
    final path = _paths[pathIndex];
    _paths[pathIndex] = path.copyWith(
      modules: [...path.modules, module],
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[PersonalizedLearning] Added module to path: $pathId');
  }

  Future<ContentRecommendation> generateRecommendation({
    required String userId,
    required SkillCategory category,
    required DifficultyLevel difficulty,
    required List<String> interests,
    required List<String> completedTopics,
  }) async {
    final recommendation = ContentRecommendation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      category: category,
      difficulty: difficulty,
      title: _generateRecommendationTitle(category, difficulty),
      description: _generateRecommendationDescription(category, difficulty),
      contentType: _selectContentType(category),
      resources: _generateResources(category, difficulty),
      estimatedTime: _estimateTime(difficulty),
      relevanceScore: _calculateRelevanceScore(interests, completedTopics),
      prerequisites: _generatePrerequisites(category, difficulty),
      learningOutcomes: _generateLearningOutcomes(category),
      status: RecommendationStatus.pending,
      createdAt: DateTime.now(),
    );
    
    _recommendations.insert(0, recommendation);
    _totalRecommendations++;
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[PersonalizedLearning] Generated recommendation: ${recommendation.title}');
    return recommendation;
  }

  String _generateRecommendationTitle(SkillCategory category, DifficultyLevel difficulty) {
    final titles = {
      SkillCategory.programming: {
        DifficultyLevel.beginner: 'Introduction to Programming Fundamentals',
        DifficultyLevel.intermediate: 'Advanced Programming Concepts',
        DifficultyLevel.advanced: 'Expert Programming Techniques',
      },
      SkillCategory.dataScience: {
        DifficultyLevel.beginner: 'Getting Started with Data Analysis',
        DifficultyLevel.intermediate: 'Statistical Methods for Data Science',
        DifficultyLevel.advanced: 'Machine Learning and AI Fundamentals',
      },
      SkillCategory.design: {
        DifficultyLevel.beginner: 'Design Principles for Beginners',
        DifficultyLevel.intermediate: 'Advanced UI/UX Design',
        DifficultyLevel.advanced: 'Design Systems and Architecture',
      },
      SkillCategory.business: {
        DifficultyLevel.beginner: 'Business Fundamentals',
        DifficultyLevel.intermediate: 'Strategic Business Planning',
        DifficultyLevel.advanced: 'Advanced Business Strategy',
      },
      SkillCategory.marketing: {
        DifficultyLevel.beginner: 'Marketing Basics',
        DifficultyLevel.intermediate: 'Digital Marketing Strategies',
        DifficultyLevel.advanced: 'Advanced Marketing Analytics',
      },
      SkillCategory.communication: {
        DifficultyLevel.beginner: 'Effective Communication Skills',
        DifficultyLevel.intermediate: 'Advanced Communication Techniques',
        DifficultyLevel.advanced: 'Mastering Professional Communication',
      },
      SkillCategory.leadership: {
        DifficultyLevel.beginner: 'Introduction to Leadership',
        DifficultyLevel.intermediate: 'Team Leadership and Management',
        DifficultyLevel.advanced: 'Executive Leadership Strategies',
      },
      SkillCategory.creativity: {
        DifficultyLevel.beginner: 'Unlocking Your Creative Potential',
        DifficultyLevel.intermediate: 'Advanced Creative Techniques',
        DifficultyLevel.advanced: 'Mastering Creative Innovation',
      },
    };
    
    return titles[category]?[difficulty] ?? 'Learning Path';
  }

  String _generateRecommendationDescription(SkillCategory category, DifficultyLevel difficulty) {
    final descriptions = {
      SkillCategory.programming: 'Master the art of coding and software development',
      SkillCategory.dataScience: 'Learn to extract insights from data and make informed decisions',
      SkillCategory.design: 'Develop your visual and user experience design skills',
      SkillCategory.business: 'Build essential business acumen and strategic thinking',
      SkillCategory.marketing: 'Understand how to reach and engage your target audience',
      SkillCategory.communication: 'Enhance your ability to express ideas clearly and persuasively',
      SkillCategory.leadership: 'Develop the skills to inspire and guide others effectively',
      SkillCategory.creativity: 'Cultivate innovative thinking and creative problem-solving',
    };
    
    return descriptions[category] ?? 'Expand your knowledge and skills in this area';
  }

  ContentType _selectContentType(SkillCategory category) {
    final typeMap = {
      SkillCategory.programming: ContentType.interactiveCourse,
      SkillCategory.dataScience: ContentType.videoLecture,
      SkillCategory.design: ContentType.handsOnProject,
      SkillCategory.business: ContentType.caseStudy,
      SkillCategory.marketing: ContentType.interactiveCourse,
      SkillCategory.communication: ContentType.workshop,
      SkillCategory.leadership: ContentType.mentoringSession,
      SkillCategory.creativity: ContentType.handsOnProject,
    };
    
    return typeMap[category] ?? ContentType.interactiveCourse;
  }

  List<String> _generateResources(SkillCategory category, DifficultyLevel difficulty) {
    final resources = <String>[];
    
    switch (category) {
      case SkillCategory.programming:
        resources.addAll([
          'Interactive coding exercises',
          'Video tutorials',
          'Code review sessions',
          'Practice projects',
        ]);
        break;
      case SkillCategory.dataScience:
        resources.addAll([
          'Dataset collections',
          'Analysis templates',
          'Tool tutorials',
          'Case studies',
        ]);
        break;
      case SkillCategory.design:
        resources.addAll([
          'Design templates',
          'Tool tutorials',
          'Portfolio examples',
          'Feedback sessions',
        ]);
        break;
      case SkillCategory.business:
        resources.addAll([
          'Business case studies',
          'Strategy frameworks',
          'Industry reports',
          'Expert interviews',
        ]);
        break;
      case SkillCategory.marketing:
        resources.addAll([
          'Campaign templates',
          'Analytics tools',
          'Content calendars',
          'Strategy guides',
        ]);
        break;
      case SkillCategory.communication:
        resources.addAll([
          'Practice scenarios',
          'Feedback exercises',
          'Role-playing activities',
          'Communication frameworks',
        ]);
        break;
      case SkillCategory.leadership:
        resources.addAll([
          'Leadership assessments',
          'Team exercises',
          'Case studies',
          'Mentoring guides',
        ]);
        break;
      case SkillCategory.creativity:
        resources.addAll([
          'Creative exercises',
          'Inspiration galleries',
          'Tool tutorials',
          'Project templates',
        ]);
        break;
    }
    
    if (difficulty == DifficultyLevel.advanced) {
      resources.add('Expert consultation');
      resources.add('Advanced certification');
    }
    
    return resources;
  }

  int _estimateTime(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 10;
      case DifficultyLevel.intermediate:
        return 20;
      case DifficultyLevel.advanced:
        return 40;
    }
  }

  double _calculateRelevanceScore(List<String> interests, List<String> completedTopics) {
    double score = 5.0; // Base score
    
    // Increase score based on interests alignment
    if (interests.length > 3) score += 2.0;
    if (interests.length > 5) score += 1.0;
    
    // Decrease score if too many topics already completed
    if (completedTopics.length > 10) score -= 1.0;
    if (completedTopics.length > 20) score -= 1.0;
    
    return score.clamp(1.0, 10.0);
  }

  List<String> _generatePrerequisites(SkillCategory category, DifficultyLevel difficulty) {
    final prerequisites = <String>[];
    
    if (difficulty != DifficultyLevel.beginner) {
      prerequisites.add('Basic understanding of $category concepts');
    }
    
    if (difficulty == DifficultyLevel.advanced) {
      prerequisites.add('Intermediate level knowledge');
      prerequisites.add('Practical experience in related areas');
    }
    
    return prerequisites;
  }

  List<String> _generateLearningOutcomes(SkillCategory category) {
    final outcomes = <String>[];
    
    switch (category) {
      case SkillCategory.programming:
        outcomes.addAll([
          'Write clean, efficient code',
          'Solve complex programming problems',
          'Understand software architecture principles',
        ]);
        break;
      case SkillCategory.dataScience:
        outcomes.addAll([
          'Analyze datasets effectively',
          'Build predictive models',
          'Communicate data insights clearly',
        ]);
        break;
      case SkillCategory.design:
        outcomes.addAll([
          'Create user-centered designs',
          'Develop visual design skills',
          'Build design systems',
        ]);
        break;
      case SkillCategory.business:
        outcomes.addAll([
          'Develop strategic thinking',
          'Analyze business problems',
          'Create effective business plans',
        ]);
        break;
      case SkillCategory.marketing:
        outcomes.addAll([
          'Develop marketing strategies',
          'Analyze campaign performance',
          'Create engaging content',
        ]);
        break;
      case SkillCategory.communication:
        outcomes.addAll([
          'Express ideas clearly',
          'Listen actively',
          'Adapt communication style',
        ]);
        break;
      case SkillCategory.leadership:
        outcomes.addAll([
          'Inspire and motivate teams',
          'Make strategic decisions',
          'Develop others effectively',
        ]);
        break;
      case SkillCategory.creativity:
        outcomes.addAll([
          'Generate innovative ideas',
          'Solve problems creatively',
          'Think outside the box',
        ]);
        break;
    }
    
    return outcomes;
  }

  Future<void> startLearningSession({
    required String recommendationId,
    required String userId,
  }) async {
    final recommendationIndex = _recommendations.indexWhere((r) => r.id == recommendationId);
    if (recommendationIndex == -1) return;
    
    final session = LearningSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      recommendationId: recommendationId,
      userId: userId,
      startTime: DateTime.now(),
      endTime: null,
      progress: 0,
      notes: '',
      completed: false,
    );
    
    _sessions.insert(0, session);
    _totalSessions++;
    
    // Update recommendation status
    final recommendation = _recommendations[recommendationIndex];
    _recommendations[recommendationIndex] = recommendation.copyWith(
      status: RecommendationStatus.inProgress,
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[PersonalizedLearning] Started learning session: $recommendationId');
  }

  Future<void> updateSessionProgress(String sessionId, int progress, String notes) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;
    
    final session = _sessions[sessionIndex];
    _sessions[sessionIndex] = session.copyWith(
      progress: progress,
      notes: notes,
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[PersonalizedLearning] Updated session progress: $sessionId');
  }

  Future<void> completeSession(String sessionId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;
    
    final session = _sessions[sessionIndex];
    _sessions[sessionIndex] = session.copyWith(
      endTime: DateTime.now(),
      completed: true,
    );
    
    // Update recommendation status
    final recommendationIndex = _recommendations.indexWhere((r) => r.id == session.recommendationId);
    if (recommendationIndex != -1) {
      final recommendation = _recommendations[recommendationIndex];
      _recommendations[recommendationIndex] = recommendation.copyWith(
        status: RecommendationStatus.completed,
      );
    }
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[PersonalizedLearning] Completed session: $sessionId');
  }

  Future<void> addModuleToPathAndComplete(String pathId, String moduleId) async {
    final pathIndex = _paths.indexWhere((p) => p.id == pathId);
    if (pathIndex == -1) return;
    
    final path = _paths[pathIndex];
    final moduleIndex = path.modules.indexWhere((m) => m.id == moduleId);
    if (moduleIndex == -1) return;
    
    final updatedModules = List<LearningModule>.from(path.modules);
    updatedModules[moduleIndex] = updatedModules[moduleIndex].copyWith(completed: true);
    
    final completedModules = updatedModules.where((m) => m.completed).length;
    final progress = (completedModules / updatedModules.length * 100).round();
    
    _paths[pathIndex] = path.copyWith(
      modules: updatedModules,
      progress: progress,
      currentModule: completedModules,
      status: progress >= 100 ? PathStatus.completed : PathStatus.inProgress,
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[PersonalizedLearning] Completed module in path: $pathId');
  }

  List<LearningPath> getPathsByCategory(SkillCategory category) {
    return _paths.where((p) => p.category == category).toList();
  }

  List<ContentRecommendation> getRecommendationsByCategory(SkillCategory category) {
    return _recommendations.where((r) => r.category == category).toList();
  }

  List<LearningSession> getActiveSessions() {
    return _sessions.where((s) => !s.completed).toList();
  }

  String getLearningPathRecommendations(String userId) {
    final buffer = StringBuffer();
    buffer.writeln('🎯 Personalized Learning Path Recommendations for User $userId:');
    buffer.writeln('');
    
    final pendingRecommendations = _recommendations
        .where((r) => r.userId == userId && r.status == RecommendationStatus.pending)
        .toList();
    
    if (pendingRecommendations.isEmpty) {
      buffer.writeln('No pending recommendations. Generate new ones based on your interests!');
    } else {
      for (final recommendation in pendingRecommendations.take(5)) {
        buffer.writeln('📚 ${recommendation.title}');
        buffer.writeln('   Category: ${recommendation.category.label}');
        buffer.writeln('   Difficulty: ${recommendation.difficulty.label}');
        buffer.writeln('   Estimated Time: ${recommendation.estimatedTime} minutes');
        buffer.writeln('   Relevance Score: ${recommendation.relevanceScore.toStringAsFixed(1)}/10');
        buffer.writeln('   Type: ${recommendation.contentType.label}');
        buffer.writeln('');
      }
    }
    
    return buffer.toString();
  }

  String getLearningInsights() {
    if (_paths.isEmpty && _recommendations.isEmpty) {
      return 'No learning paths or recommendations yet. Start your learning journey!';
    }
    
    final inProgressPaths = _paths.where((p) => p.status == PathStatus.inProgress).length;
    final completedPaths = _paths.where((p) => p.status == PathStatus.completed).length;
    final activeSessions = getActiveSessions().length;
    
    final byCategory = <SkillCategory, int>{};
    for (final path in _paths) {
      byCategory[path.category] = (byCategory[path.category] ?? 0) + 1;
    }
    
    final buffer = StringBuffer();
    buffer.writeln('🎓 Personalized Learning Insights:');
    buffer.writeln('• Total Learning Paths: $_totalPaths');
    buffer.writeln('• In Progress: $inProgressPaths');
    buffer.writeln('• Total Recommendations: $_totalRecommendations');
    buffer.writeln('• Active Learning Sessions: $activeSessions');
    buffer.writeln('');
    buffer.writeln('Learning Paths by Category:');
    for (final entry in byCategory.entries) {
      buffer.writeln('  • ${entry.key.label}: ${entry.value}');
    }
    
    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'paths': _paths.take(20).map((p) => p.toJson()).toList(),
        'recommendations': _recommendations.take(50).map((r) => r.toJson()).toList(),
        'sessions': _sessions.take(50).map((s) => s.toJson()).toList(),
        'totalPaths': _totalPaths,
        'totalRecommendations': _totalRecommendations,
        'totalSessions': _totalSessions,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[PersonalizedLearning] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _paths.clear();
        _paths.addAll(
          (data['paths'] as List<dynamic>? ?? [])
              .map((p) => LearningPath.fromJson(p as Map<String, dynamic>))
        );
        
        _recommendations.clear();
        _recommendations.addAll(
          (data['recommendations'] as List<dynamic>? ?? [])
              .map((r) => ContentRecommendation.fromJson(r as Map<String, dynamic>))
        );
        
        _sessions.clear();
        _sessions.addAll(
          (data['sessions'] as List<dynamic>? ?? [])
              .map((s) => LearningSession.fromJson(s as Map<String, dynamic>))
        );
        
        _totalPaths = data['totalPaths'] as int? ?? 0;
        _totalRecommendations = data['totalRecommendations'] as int? ?? 0;
        _totalSessions = data['totalSessions'] as int? ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PersonalizedLearning] Load error: $e');
    }
  }
}

class LearningPath {
  final String id;
  final String title;
  final String description;
  final SkillCategory category;
  final DifficultyLevel difficulty;
  final int estimatedHours;
  final List<String> topics;
  final List<String> prerequisites;
  final List<LearningModule> modules;
  PathStatus status;
  int progress;
  int currentModule;
  final DateTime createdAt;

  LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedHours,
    required this.topics,
    required this.prerequisites,
    required this.modules,
    required this.status,
    required this.progress,
    required this.currentModule,
    required this.createdAt,
  });

  LearningPath copyWith({
    List<LearningModule>? modules,
    PathStatus? status,
    int? progress,
    int? currentModule,
  }) {
    return LearningPath(
      id: id,
      title: title,
      description: description,
      category: category,
      difficulty: difficulty,
      estimatedHours: estimatedHours,
      topics: topics,
      prerequisites: prerequisites,
      modules: modules ?? this.modules,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentModule: currentModule ?? this.currentModule,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'difficulty': difficulty.name,
    'estimatedHours': estimatedHours,
    'topics': topics,
    'prerequisites': prerequisites,
    'modules': modules.map((m) => m.toJson()).toList(),
    'status': status.name,
    'progress': progress,
    'currentModule': currentModule,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LearningPath.fromJson(Map<String, dynamic> json) => LearningPath(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    category: SkillCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => SkillCategory.communication,
    ),
    difficulty: DifficultyLevel.values.firstWhere(
      (e) => e.name == json['difficulty'],
      orElse: () => DifficultyLevel.beginner,
    ),
    estimatedHours: json['estimatedHours'],
    topics: List<String>.from(json['topics'] ?? []),
    prerequisites: List<String>.from(json['prerequisites'] ?? []),
    modules: (json['modules'] as List<dynamic>? ?? [])
        .map((m) => LearningModule.fromJson(m as Map<String, dynamic>))
        .toList(),
    status: PathStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => PathStatus.notStarted,
    ),
    progress: json['progress'] ?? 0,
    currentModule: json['currentModule'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class LearningModule {
  final String id;
  final String title;
  final String description;
  final List<String> resources;
  final int estimatedMinutes;
  bool completed;
  final DateTime createdAt;

  LearningModule({
    required this.id,
    required this.title,
    required this.description,
    required this.resources,
    required this.estimatedMinutes,
    required this.completed,
    required this.createdAt,
  });

  LearningModule copyWith({
    bool? completed,
  }) {
    return LearningModule(
      id: id,
      title: title,
      description: description,
      resources: resources,
      estimatedMinutes: estimatedMinutes,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'resources': resources,
    'estimatedMinutes': estimatedMinutes,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LearningModule.fromJson(Map<String, dynamic> json) => LearningModule(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    resources: List<String>.from(json['resources'] ?? []),
    estimatedMinutes: json['estimatedMinutes'],
    completed: json['completed'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class ContentRecommendation {
  final String id;
  final String userId;
  final SkillCategory category;
  final DifficultyLevel difficulty;
  final String title;
  final String description;
  final ContentType contentType;
  final List<String> resources;
  final int estimatedTime;
  final double relevanceScore;
  final List<String> prerequisites;
  final List<String> learningOutcomes;
  RecommendationStatus status;
  final DateTime createdAt;

  ContentRecommendation({
    required this.id,
    required this.userId,
    required this.category,
    required this.difficulty,
    required this.title,
    required this.description,
    required this.contentType,
    required this.resources,
    required this.estimatedTime,
    required this.relevanceScore,
    required this.prerequisites,
    required this.learningOutcomes,
    required this.status,
    required this.createdAt,
  });

  ContentRecommendation copyWith({
    RecommendationStatus? status,
  }) {
    return ContentRecommendation(
      id: id,
      userId: userId,
      category: category,
      difficulty: difficulty,
      title: title,
      description: description,
      contentType: contentType,
      resources: resources,
      estimatedTime: estimatedTime,
      relevanceScore: relevanceScore,
      prerequisites: prerequisites,
      learningOutcomes: learningOutcomes,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'category': category.name,
    'difficulty': difficulty.name,
    'title': title,
    'description': description,
    'contentType': contentType.name,
    'resources': resources,
    'estimatedTime': estimatedTime,
    'relevanceScore': relevanceScore,
    'prerequisites': prerequisites,
    'learningOutcomes': learningOutcomes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ContentRecommendation.fromJson(Map<String, dynamic> json) => ContentRecommendation(
    id: json['id'],
    userId: json['userId'],
    category: SkillCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => SkillCategory.communication,
    ),
    difficulty: DifficultyLevel.values.firstWhere(
      (e) => e.name == json['difficulty'],
      orElse: () => DifficultyLevel.beginner,
    ),
    title: json['title'],
    description: json['description'],
    contentType: ContentType.values.firstWhere(
      (e) => e.name == json['contentType'],
      orElse: () => ContentType.interactiveCourse,
    ),
    resources: List<String>.from(json['resources'] ?? []),
    estimatedTime: json['estimatedTime'],
    relevanceScore: (json['relevanceScore'] as num).toDouble(),
    prerequisites: List<String>.from(json['prerequisites'] ?? []),
    learningOutcomes: List<String>.from(json['learningOutcomes'] ?? []),
    status: RecommendationStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => RecommendationStatus.pending,
    ),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class LearningSession {
  final String id;
  final String recommendationId;
  final String userId;
  final DateTime startTime;
  DateTime? endTime;
  int progress;
  final String notes;
  bool completed;

  LearningSession({
    required this.id,
    required this.recommendationId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.progress,
    required this.notes,
    required this.completed,
  });

  LearningSession copyWith({
    DateTime? endTime,
    int? progress,
    String? notes,
    bool? completed,
  }) {
    return LearningSession(
      id: id,
      recommendationId: recommendationId,
      userId: userId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recommendationId': recommendationId,
    'userId': userId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'progress': progress,
    'notes': notes,
    'completed': completed,
  };

  factory LearningSession.fromJson(Map<String, dynamic> json) => LearningSession(
    id: json['id'],
    recommendationId: json['recommendationId'],
    userId: json['userId'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    progress: json['progress'],
    notes: json['notes'] ?? '',
    completed: json['completed'] ?? false,
  );
}

enum SkillCategory {
  programming('Programming'),
  dataScience('Data Science'),
  design('Design'),
  business('Business'),
  marketing('Marketing'),
  communication('Communication'),
  leadership('Leadership'),
  creativity('Creativity');
  
  final String label;
  const SkillCategory(this.label);
}

enum DifficultyLevel {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');
  
  final String label;
  const DifficultyLevel(this.label);
}

enum PathStatus { notStarted, inProgress, completed }

enum ContentType {
  interactiveCourse('Interactive Course'),
  videoLecture('Video Lecture'),
  handsOnProject('Hands-on Project'),
  caseStudy('Case Study'),
  workshop('Workshop'),
  mentoringSession('Mentoring Session');
  
  final String label;
  const ContentType(this.label);
}

enum RecommendationStatus { pending, inProgress, completed, skipped }