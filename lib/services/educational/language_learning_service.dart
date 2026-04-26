import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌍 Language Learning Partner Service
///
/// Conversational practice with cultural context and corrections.
class LanguageLearningService {
  LanguageLearningService._();
  static final LanguageLearningService instance = LanguageLearningService._();

  final List<LanguageCourse> _courses = [];
  final List<Conversation> _conversations = [];
  final List<VocabularySet> _vocabularySets = [];

  int _totalCourses = 0;
  int _totalConversations = 0;
  int _totalWordsLearned = 0;

  static const String _storageKey = 'language_learning_v1';

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint('[LanguageLearning] Initialized with $_totalCourses courses');
  }

  Future<LanguageCourse> createCourse({
    required String title,
    required Language language,
    required String nativeLanguage,
    required ProficiencyLevel level,
    required String description,
    required List<String> goals,
  }) async {
    final course = LanguageCourse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      language: language,
      nativeLanguage: nativeLanguage,
      level: level,
      description: description,
      goals: goals,
      currentLesson: 1,
      totalLessons: 20,
      status: CourseStatus.inProgress,
      vocabularyLearned: 0,
      conversationsCompleted: 0,
      createdAt: DateTime.now(),
    );

    _courses.insert(0, course);
    _totalCourses++;

    await _saveData();

    if (kDebugMode) debugPrint('[LanguageLearning] Created course: $title');
    return course;
  }

  Future<Conversation> startConversation({
    required String courseId,
    required String topic,
    required String userMessage,
    required String aiResponse,
    required ConversationDifficulty difficulty,
  }) async {
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: courseId,
      topic: topic,
      userMessage: userMessage,
      aiResponse: aiResponse,
      difficulty: difficulty,
      corrections: [],
      suggestions: [],
      culturalNotes: [],
      rating: 0,
      completed: false,
      createdAt: DateTime.now(),
    );

    _conversations.insert(0, conversation);
    _totalConversations++;

    // Update course
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex != -1) {
      final course = _courses[courseIndex];
      _courses[courseIndex] = course.copyWith(
        conversationsCompleted: course.conversationsCompleted + 1,
      );
    }

    await _saveData();

    if (kDebugMode)
      debugPrint('[LanguageLearning] Started conversation: $topic');
    return conversation;
  }

  Future<void> addCorrection({
    required String conversationId,
    required String originalText,
    required String correctedText,
    required String explanation,
    required CorrectionType type,
  }) async {
    final conversationIndex =
        _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex == -1) return;

    final correction = Correction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: originalText,
      correctedText: correctedText,
      explanation: explanation,
      type: type,
      createdAt: DateTime.now(),
    );

    final conversation = _conversations[conversationIndex];
    _conversations[conversationIndex] = conversation.copyWith(
      corrections: [...conversation.corrections, correction],
    );

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[LanguageLearning] Added correction to conversation: $conversationId');
  }

  Future<void> addCulturalNote({
    required String conversationId,
    required String note,
    required String context,
  }) async {
    final conversationIndex =
        _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex == -1) return;

    final culturalNote = CulturalNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      note: note,
      context: context,
      createdAt: DateTime.now(),
    );

    final conversation = _conversations[conversationIndex];
    _conversations[conversationIndex] = conversation.copyWith(
      culturalNotes: [...conversation.culturalNotes, culturalNote],
    );

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[LanguageLearning] Added cultural note to conversation: $conversationId');
  }

  Future<VocabularySet> createVocabularySet({
    required String courseId,
    required String title,
    required String description,
    required List<VocabularyWord> words,
  }) async {
    final vocabularySet = VocabularySet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: courseId,
      title: title,
      description: description,
      words: words,
      masteredWords: 0,
      createdAt: DateTime.now(),
    );

    _vocabularySets.insert(0, vocabularySet);

    // Update course
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex != -1) {
      final course = _courses[courseIndex];
      _courses[courseIndex] = course.copyWith(
        vocabularyLearned: course.vocabularyLearned + words.length,
      );
      _totalWordsLearned += words.length;
    }

    await _saveData();

    if (kDebugMode)
      debugPrint('[LanguageLearning] Created vocabulary set: $title');
    return vocabularySet;
  }

  Future<void> markWordAsMastered(String vocabularySetId, String wordId) async {
    final setIndex = _vocabularySets.indexWhere((s) => s.id == vocabularySetId);
    if (setIndex == -1) return;

    final vocabularySet = _vocabularySets[setIndex];
    final updatedWords = vocabularySet.words.map((w) {
      if (w.id == wordId) {
        return w.copyWith(mastered: true, masteredAt: DateTime.now());
      }
      return w;
    }).toList();

    _vocabularySets[setIndex] = vocabularySet.copyWith(
      words: updatedWords,
      masteredWords: updatedWords.where((w) => w.mastered).length,
    );

    await _saveData();

    if (kDebugMode)
      debugPrint('[LanguageLearning] Marked word as mastered: $wordId');
  }

  Future<void> completeConversation(String conversationId, int rating) async {
    final conversationIndex =
        _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex == -1) return;

    final conversation = _conversations[conversationIndex];
    _conversations[conversationIndex] = conversation.copyWith(
      completed: true,
      rating: rating,
    );

    await _saveData();

    if (kDebugMode)
      debugPrint('[LanguageLearning] Completed conversation: $conversationId');
  }

  Future<void> updateCourseProgress(String courseId, int currentLesson) async {
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;

    final course = _courses[courseIndex];
    _courses[courseIndex] = course.copyWith(
      currentLesson: currentLesson,
      status: currentLesson >= course.totalLessons
          ? CourseStatus.completed
          : CourseStatus.inProgress,
    );

    await _saveData();

    if (kDebugMode)
      debugPrint('[LanguageLearning] Updated course progress: $courseId');
  }

  List<Conversation> getConversationsByCourse(String courseId) {
    return _conversations.where((c) => c.courseId == courseId).toList();
  }

  List<VocabularySet> getVocabularySetsByCourse(String courseId) {
    return _vocabularySets.where((s) => s.courseId == courseId).toList();
  }

  String getConversationPractice({
    required Language language,
    required String topic,
    required String userInput,
    required ProficiencyLevel level,
  }) {
    final corrections = _generateCorrections(userInput, language);
    final suggestions = _generateSuggestions(userInput, language, level);
    final culturalNotes = _generateCulturalNotes(topic, language);

    final buffer = StringBuffer();
    buffer.writeln('🗣️ Conversation Practice (${language.name})');
    buffer.writeln('Topic: $topic');
    buffer.writeln('');
    buffer.writeln('Your Input:');
    buffer.writeln(userInput);
    buffer.writeln('');

    if (corrections.isNotEmpty) {
      buffer.writeln('📝 Corrections:');
      for (final correction in corrections) {
        buffer.writeln('• ${correction.explanation}');
        buffer.writeln(
            '  "${correction.originalText}" → "${correction.correctedText}"');
      }
      buffer.writeln('');
    }

    if (suggestions.isNotEmpty) {
      buffer.writeln('💡 Suggestions:');
      for (final suggestion in suggestions) {
        buffer.writeln('• $suggestion');
      }
      buffer.writeln('');
    }

    if (culturalNotes.isNotEmpty) {
      buffer.writeln('🌍 Cultural Notes:');
      for (final note in culturalNotes) {
        buffer.writeln('• $note');
      }
    }

    return buffer.toString();
  }

  List<Correction> _generateCorrections(String text, Language language) {
    final corrections = <Correction>[];

    // Simplified correction logic
    if (language == Language.english) {
      if (text.contains(RegExp(r"\bhe don't\b", caseSensitive: false))) {
        corrections.add(Correction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalText: "he don't",
          correctedText: "he doesn't",
          explanation:
              'Third person singular requires "doesn\'t" instead of "don\'t"',
          type: CorrectionType.grammar,
          createdAt: DateTime.now(),
        ));
      }

      if (text.contains(RegExp(r'\bi seen\b', caseSensitive: false))) {
        corrections.add(Correction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          originalText: 'I seen',
          correctedText: 'I saw',
          explanation: 'Use simple past "saw" instead of "seen" after "I"',
          type: CorrectionType.grammar,
          createdAt: DateTime.now(),
        ));
      }
    }

    return corrections;
  }

  List<String> _generateSuggestions(
      String text, Language language, ProficiencyLevel level) {
    final suggestions = <String>[];

    if (level == ProficiencyLevel.beginner) {
      suggestions.add('Try using simpler vocabulary');
      suggestions.add('Focus on basic sentence structure');
    } else if (level == ProficiencyLevel.intermediate) {
      suggestions.add('Try using more complex sentence structures');
      suggestions.add('Incorporate idiomatic expressions');
    } else {
      suggestions.add('Consider using more nuanced vocabulary');
      suggestions.add('Try incorporating cultural references');
    }

    if (text.length < 20) {
      suggestions.add('Try expanding your response with more details');
    }

    return suggestions;
  }

  List<String> _generateCulturalNotes(String topic, Language language) {
    final notes = <String>[];

    if (language == Language.japanese &&
        topic.toLowerCase().contains('thank')) {
      notes.add(
          'In Japanese culture, expressing gratitude is very important and often more formal than in Western cultures');
    }

    if (language == Language.spanish &&
        topic.toLowerCase().contains('greeting')) {
      notes.add(
          'Spanish speakers often greet with kisses on the cheek in many countries');
    }

    if (language == Language.french && topic.toLowerCase().contains('meal')) {
      notes.add(
          'Meals in French culture are social events and can last for hours');
    }

    return notes;
  }

  String getLearningProgress(String courseId) {
    final course = _courses.firstWhere((c) => c.id == courseId);
    final progress =
        (course.currentLesson / course.totalLessons * 100).toStringAsFixed(0);

    final vocabularySets = getVocabularySetsByCourse(courseId);
    final totalWords =
        vocabularySets.fold<int>(0, (sum, set) => sum + set.words.length);
    final masteredWords =
        vocabularySets.fold<int>(0, (sum, set) => sum + set.masteredWords);

    final buffer = StringBuffer();
    buffer.writeln('📚 Learning Progress for "${course.title}":');
    buffer.writeln('');
    buffer.writeln('Course Progress: $progress%');
    buffer.writeln('Lesson ${course.currentLesson} of ${course.totalLessons}');
    buffer.writeln('');
    buffer.writeln('Vocabulary: $masteredWords/$totalWords words mastered');
    if (totalWords > 0) {
      final vocabProgress =
          (masteredWords / totalWords * 100).toStringAsFixed(0);
      buffer.writeln('Vocabulary Progress: $vocabProgress%');
    }
    buffer.writeln('');
    buffer.writeln('Conversations Completed: ${course.conversationsCompleted}');

    return buffer.toString();
  }

  String getLanguageTips(Language language) {
    final tips = <String>[];

    switch (language) {
      case Language.english:
        tips.addAll([
          'Practice listening to native speakers through movies and podcasts',
          'Focus on phrasal verbs - they\'re very common in English',
          'Learn idiomatic expressions to sound more natural',
          'Pay attention to word stress and intonation',
        ]);
        break;
      case Language.spanish:
        tips.addAll([
          'Practice rolling your R\'s for authentic pronunciation',
          'Learn the difference between ser and estar',
          'Pay attention to gender agreements in adjectives',
          'Immerse yourself in Spanish music and telenovelas',
        ]);
        break;
      case Language.french:
        tips.addAll([
          'Master the nasal vowel sounds early on',
          'Practice liaisons between words',
          'Learn verb conjugations systematically',
          'Don\'t be afraid to make mistakes - French appreciate effort',
        ]);
        break;
      case Language.japanese:
        tips.addAll([
          'Master hiragana and katakana before tackling kanji',
          'Pay attention to pitch accent - it changes meaning',
          'Learn keigo (polite language) for formal situations',
          'Practice writing kanji regularly to build muscle memory',
        ]);
        break;
      case Language.german:
        tips.addAll([
          'Learn noun genders with the noun from the beginning',
          'Practice cases - they\'re essential in German',
          'Pay attention to word order, especially with verbs',
          'Compound words are your friend - learn to build them',
        ]);
        break;
      case Language.chinese:
        tips.addAll([
          'Focus on tones - they\'re crucial for meaning',
          'Practice writing characters to understand their structure',
          'Learn radicals to help with character recognition',
          'Use spaced repetition for vocabulary retention',
        ]);
        break;
    }

    tips.add('Practice speaking daily, even if just for a few minutes');
    tips.add('Don\'t be afraid to make mistakes - they\'re part of learning');
    tips.add('Find a language partner or tutor for conversation practice');

    return '💡 Learning Tips for ${language.name}:\n' +
        tips.map((t) => '• $t').join('\n');
  }

  String getLanguageInsights() {
    if (_courses.isEmpty) {
      return 'No language courses started yet. Begin your language learning journey!';
    }

    final inProgress =
        _courses.where((c) => c.status == CourseStatus.inProgress).length;

    final byLanguage = <Language, int>{};
    for (final course in _courses) {
      byLanguage[course.language] = (byLanguage[course.language] ?? 0) + 1;
    }

    final buffer = StringBuffer();
    buffer.writeln('🌍 Language Learning Insights:');
    buffer.writeln('• Total Courses: $_totalCourses');
    buffer.writeln('• In Progress: $inProgress');
    buffer.writeln('• Total Words Learned: $_totalWordsLearned');
    buffer.writeln('• Total Conversations: $_totalConversations');
    buffer.writeln('');
    buffer.writeln('Courses by Language:');
    for (final entry in byLanguage.entries) {
      buffer.writeln('  • ${entry.key.name}: ${entry.value}');
    }

    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'courses': _courses.map((c) => c.toJson()).toList(),
        'conversations':
            _conversations.take(100).map((c) => c.toJson()).toList(),
        'vocabularySets':
            _vocabularySets.take(50).map((v) => v.toJson()).toList(),
        'totalCourses': _totalCourses,
        'totalConversations': _totalConversations,
        'totalWordsLearned': _totalWordsLearned,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[LanguageLearning] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _courses.clear();
        _courses.addAll((data['courses'] as List<dynamic>)
            .map((c) => LanguageCourse.fromJson(c as Map<String, dynamic>)));

        _conversations.clear();
        _conversations.addAll((data['conversations'] as List<dynamic>? ?? [])
            .map((c) => Conversation.fromJson(c as Map<String, dynamic>)));

        _vocabularySets.clear();
        _vocabularySets.addAll((data['vocabularySets'] as List<dynamic>? ?? [])
            .map((v) => VocabularySet.fromJson(v as Map<String, dynamic>)));

        _totalCourses = data['totalCourses'] as int;
        _totalConversations = data['totalConversations'] as int;
        _totalWordsLearned = data['totalWordsLearned'] as int;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LanguageLearning] Load error: $e');
    }
  }
}

class LanguageCourse {
  final String id;
  final String title;
  final Language language;
  final String nativeLanguage;
  final ProficiencyLevel level;
  final String description;
  final List<String> goals;
  int currentLesson;
  final int totalLessons;
  CourseStatus status;
  int vocabularyLearned;
  int conversationsCompleted;
  final DateTime createdAt;

  LanguageCourse({
    required this.id,
    required this.title,
    required this.language,
    required this.nativeLanguage,
    required this.level,
    required this.description,
    required this.goals,
    required this.currentLesson,
    required this.totalLessons,
    required this.status,
    required this.vocabularyLearned,
    required this.conversationsCompleted,
    required this.createdAt,
  });

  LanguageCourse copyWith({
    int? currentLesson,
    CourseStatus? status,
    int? vocabularyLearned,
    int? conversationsCompleted,
  }) {
    return LanguageCourse(
      id: id,
      title: title,
      language: language,
      nativeLanguage: nativeLanguage,
      level: level,
      description: description,
      goals: goals,
      currentLesson: currentLesson ?? this.currentLesson,
      totalLessons: totalLessons,
      status: status ?? this.status,
      vocabularyLearned: vocabularyLearned ?? this.vocabularyLearned,
      conversationsCompleted:
          conversationsCompleted ?? this.conversationsCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'language': language.name,
        'nativeLanguage': nativeLanguage,
        'level': level.name,
        'description': description,
        'goals': goals,
        'currentLesson': currentLesson,
        'totalLessons': totalLessons,
        'status': status.name,
        'vocabularyLearned': vocabularyLearned,
        'conversationsCompleted': conversationsCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LanguageCourse.fromJson(Map<String, dynamic> json) => LanguageCourse(
        id: json['id'],
        title: json['title'],
        language: Language.values.firstWhere(
          (e) => e.name == json['language'],
          orElse: () => Language.english,
        ),
        nativeLanguage: json['nativeLanguage'],
        level: ProficiencyLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => ProficiencyLevel.beginner,
        ),
        description: json['description'],
        goals: List<String>.from(json['goals'] ?? []),
        currentLesson: json['currentLesson'],
        totalLessons: json['totalLessons'],
        status: CourseStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CourseStatus.inProgress,
        ),
        vocabularyLearned: json['vocabularyLearned'],
        conversationsCompleted: json['conversationsCompleted'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Conversation {
  final String id;
  final String courseId;
  final String topic;
  final String userMessage;
  final String aiResponse;
  final ConversationDifficulty difficulty;
  final List<Correction> corrections;
  final List<String> suggestions;
  final List<CulturalNote> culturalNotes;
  final int rating;
  bool completed;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.courseId,
    required this.topic,
    required this.userMessage,
    required this.aiResponse,
    required this.difficulty,
    required this.corrections,
    required this.suggestions,
    required this.culturalNotes,
    required this.rating,
    required this.completed,
    required this.createdAt,
  });

  Conversation copyWith({
    List<Correction>? corrections,
    List<String>? suggestions,
    List<CulturalNote>? culturalNotes,
    bool? completed,
    int? rating,
  }) {
    return Conversation(
      id: id,
      courseId: courseId,
      topic: topic,
      userMessage: userMessage,
      aiResponse: aiResponse,
      difficulty: difficulty,
      corrections: corrections ?? this.corrections,
      suggestions: suggestions ?? this.suggestions,
      culturalNotes: culturalNotes ?? this.culturalNotes,
      rating: rating ?? this.rating,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'topic': topic,
        'userMessage': userMessage,
        'aiResponse': aiResponse,
        'difficulty': difficulty.name,
        'corrections': corrections.map((c) => c.toJson()).toList(),
        'suggestions': suggestions,
        'culturalNotes': culturalNotes.map((n) => n.toJson()).toList(),
        'rating': rating,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'],
        courseId: json['courseId'],
        topic: json['topic'],
        userMessage: json['userMessage'],
        aiResponse: json['aiResponse'],
        difficulty: ConversationDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => ConversationDifficulty.beginner,
        ),
        corrections: (json['corrections'] as List<dynamic>? ?? [])
            .map((c) => Correction.fromJson(c as Map<String, dynamic>))
            .toList(),
        suggestions: List<String>.from(json['suggestions'] ?? []),
        culturalNotes: (json['culturalNotes'] as List<dynamic>? ?? [])
            .map((n) => CulturalNote.fromJson(n as Map<String, dynamic>))
            .toList(),
        rating: json['rating'] ?? 0,
        completed: json['completed'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Correction {
  final String id;
  final String originalText;
  final String correctedText;
  final String explanation;
  final CorrectionType type;
  final DateTime createdAt;

  Correction({
    required this.id,
    required this.originalText,
    required this.correctedText,
    required this.explanation,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalText': originalText,
        'correctedText': correctedText,
        'explanation': explanation,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Correction.fromJson(Map<String, dynamic> json) => Correction(
        id: json['id'],
        originalText: json['originalText'],
        correctedText: json['correctedText'],
        explanation: json['explanation'],
        type: CorrectionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CorrectionType.grammar,
        ),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class CulturalNote {
  final String id;
  final String note;
  final String context;
  final DateTime createdAt;

  CulturalNote({
    required this.id,
    required this.note,
    required this.context,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'note': note,
        'context': context,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CulturalNote.fromJson(Map<String, dynamic> json) => CulturalNote(
        id: json['id'],
        note: json['note'],
        context: json['context'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class VocabularySet {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<VocabularyWord> words;
  int masteredWords;
  final DateTime createdAt;

  VocabularySet({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.words,
    required this.masteredWords,
    required this.createdAt,
  });

  VocabularySet copyWith({
    List<VocabularyWord>? words,
    int? masteredWords,
  }) {
    return VocabularySet(
      id: id,
      courseId: courseId,
      title: title,
      description: description,
      words: words ?? this.words,
      masteredWords: masteredWords ?? this.masteredWords,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'description': description,
        'words': words.map((w) => w.toJson()).toList(),
        'masteredWords': masteredWords,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VocabularySet.fromJson(Map<String, dynamic> json) => VocabularySet(
        id: json['id'],
        courseId: json['courseId'],
        title: json['title'],
        description: json['description'],
        words: (json['words'] as List<dynamic>)
            .map((w) => VocabularyWord.fromJson(w as Map<String, dynamic>))
            .toList(),
        masteredWords: json['masteredWords'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class VocabularyWord {
  final String id;
  final String word;
  final String translation;
  final String pronunciation;
  final String example;
  final String partOfSpeech;
  bool mastered;
  DateTime? masteredAt;

  VocabularyWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.pronunciation,
    required this.example,
    required this.partOfSpeech,
    this.mastered = false,
    this.masteredAt,
  });

  VocabularyWord copyWith({
    bool? mastered,
    DateTime? masteredAt,
  }) {
    return VocabularyWord(
      id: id,
      word: word,
      translation: translation,
      pronunciation: pronunciation,
      example: example,
      partOfSpeech: partOfSpeech,
      mastered: mastered ?? this.mastered,
      masteredAt: masteredAt ?? this.masteredAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'translation': translation,
        'pronunciation': pronunciation,
        'example': example,
        'partOfSpeech': partOfSpeech,
        'mastered': mastered,
        'masteredAt': masteredAt?.toIso8601String(),
      };

  factory VocabularyWord.fromJson(Map<String, dynamic> json) => VocabularyWord(
        id: json['id'],
        word: json['word'],
        translation: json['translation'],
        pronunciation: json['pronunciation'],
        example: json['example'],
        partOfSpeech: json['partOfSpeech'],
        mastered: json['mastered'] ?? false,
        masteredAt: json['masteredAt'] != null
            ? DateTime.parse(json['masteredAt'])
            : null,
      );
}

enum Language { english, spanish, french, german, japanese, chinese }

enum ProficiencyLevel { beginner, intermediate, advanced }

enum CourseStatus { planning, inProgress, completed, onHold }

enum ConversationDifficulty { beginner, intermediate, advanced }

enum CorrectionType { grammar, vocabulary, pronunciation, usage }
