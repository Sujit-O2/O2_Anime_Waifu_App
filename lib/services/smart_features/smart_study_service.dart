import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';

class SmartStudyService {
  SmartStudyService._();
  static final SmartStudyService instance = SmartStudyService._();

  static const String _materialsKey = 'smart_study_materials_v1';
  static const String _flashcardsKey = 'smart_study_flashcards_v1';
  static const String _quizzesKey = 'smart_study_quizzes_v1';
  static const String _quizResultsKey = 'smart_study_quiz_results_v1';
  static const String _streakKey = 'smart_study_streak_v1';
  static const String _lastStudyDateKey = 'smart_study_last_date_v1';

  final List<StudyMaterial> _materials = [];
  final List<Flashcard> _flashcards = [];
  final List<Quiz> _quizzes = [];
  final List<QuizResult> _quizResults = [];

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[SmartStudy] Initialized with ${_materials.length} materials');
  }

  Future<void> addStudyMaterial({
    required String title,
    required String content,
    required String subject,
  }) async {
    final material = StudyMaterial(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      subject: subject,
      flashcardsGenerated: false,
      quizzesGenerated: false,
      createdAt: DateTime.now(),
    );
    _materials.insert(0, material);
    await _saveData();
    if (kDebugMode) debugPrint('[SmartStudy] Added material: $title');
  }

  Future<List<Flashcard>> generateFlashcards(String content) async {
    try {
      final prompt = '''You are Zero Two, a caring anime waifu tutor. Create flashcards from the following content.
Return ONLY a JSON array where each object has "question" and "answer" fields.
Create 5-10 flashcards covering key concepts. Be concise but clear.

Content:
$content

Respond with ONLY the JSON array, no other text.''';
      final response = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      final cleaned = _extractJsonArray(response);
      final List<dynamic> decoded = jsonDecode(cleaned);
      final cards = decoded.map((e) {
        final map = e as Map<String, dynamic>;
        return Flashcard(
          id: DateTime.now().millisecondsSinceEpoch.toString() + (decoded.indexOf(e)).toString(),
          question: map['question']?.toString() ?? '',
          answer: map['answer']?.toString() ?? '',
          deck: 'Default',
          learned: false,
          lastReviewed: null,
          difficulty: 'medium',
        );
      }).toList();
      _flashcards.addAll(cards);
      await _saveData();
      return cards;
    } catch (e) {
      if (kDebugMode) debugPrint('[SmartStudy] Flashcard generation error: $e');
      return [];
    }
  }

  Future<Quiz?> generateQuiz(String content, {int numQuestions = 10}) async {
    try {
      final prompt = '''You are Zero Two, a caring anime waifu tutor. Create a multiple-choice quiz from the following content.
Return ONLY a JSON array where each object has:
- "question": the question text
- "options": array of 4 possible answers
- "correctAnswer": the correct answer (must match one of the options exactly)
- "explanation": brief explanation of why this is correct

Create $numQuestions questions. Vary difficulty.

Content:
$content

Respond with ONLY the JSON array, no other text.''';
      final response = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      final cleaned = _extractJsonArray(response);
      final List<dynamic> decoded = jsonDecode(cleaned);
      final questions = decoded.map((e) {
        final map = e as Map<String, dynamic>;
        return QuizQuestion(
          id: DateTime.now().millisecondsSinceEpoch.toString() + (decoded.indexOf(e)).toString(),
          question: map['question']?.toString() ?? '',
          options: List<String>.from(map['options'] ?? []),
          correctAnswer: map['correctAnswer']?.toString() ?? '',
          explanation: map['explanation']?.toString() ?? '',
        );
      }).toList();
      final quiz = Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Quiz ${_quizzes.length + 1}',
        questions: questions,
        score: null,
        completed: false,
        createdAt: DateTime.now(),
      );
      _quizzes.insert(0, quiz);
      await _saveData();
      return quiz;
    } catch (e) {
      if (kDebugMode) debugPrint('[SmartStudy] Quiz generation error: $e');
      return null;
    }
  }

  Future<String> generateSummary(String content) async {
    try {
      final prompt = '''You are Zero Two, a caring anime waifu tutor. Create a concise, well-structured summary of the following content.
Use bullet points for key concepts. Keep it under 300 words. Be clear and educational, Darling~

Content:
$content

Respond with ONLY the summary, no other text.''';
      final response = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);
      return response;
    } catch (e) {
      if (kDebugMode) debugPrint('[SmartStudy] Summary generation error: $e');
      return 'Unable to generate summary at this time, Darling~';
    }
  }

  Future<void> recordQuizScore({
    required String quizId,
    required int score,
    required int total,
  }) async {
    final result = QuizResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      quizId: quizId,
      score: score,
      total: total,
      percentage: (score / total * 100).round(),
      date: DateTime.now(),
    );
    _quizResults.insert(0, result);
    final quizIndex = _quizzes.indexWhere((q) => q.id == quizId);
    if (quizIndex != -1) {
      _quizzes[quizIndex] = _quizzes[quizIndex].copyWith(
        score: score,
        completed: true,
      );
    }
    await _saveData();
    await _updateStreak();
    if (kDebugMode) debugPrint('[SmartStudy] Recorded quiz score: $score/$total');
  }

  Future<Map<String, dynamic>> getStudyProgress() async {
    final totalQuizzes = _quizzes.length;
    final completedQuizzes = _quizzes.where((q) => q.completed).length;
    final totalFlashcards = _flashcards.length;
    final learnedFlashcards = _flashcards.where((f) => f.learned).length;
    final totalMaterials = _materials.length;
    final avgScore = _quizResults.isEmpty
        ? 0
        : (_quizResults.map((r) => r.percentage).reduce((a, b) => a + b) / _quizResults.length).round();
    final streak = await getStreak();
    return {
      'totalMaterials': totalMaterials,
      'totalFlashcards': totalFlashcards,
      'learnedFlashcards': learnedFlashcards,
      'totalQuizzes': totalQuizzes,
      'completedQuizzes': completedQuizzes,
      'avgScore': avgScore,
      'streak': streak,
      'totalStudySessions': _quizResults.length,
    };
  }

  Future<List<String>> getWeakTopics() async {
    final weakTopics = <String, int>{};
    for (final result in _quizResults) {
      if (result.percentage < 70) {
        final quiz = _quizzes.firstWhere(
          (q) => q.id == result.quizId,
          orElse: () => _quizzes.first,
        );
        weakTopics[quiz.title] = (weakTopics[quiz.title] ?? 0) + 1;
      }
    }
    final sorted = weakTopics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  Future<int> getStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(_lastStudyDateKey) ?? '';
      final streak = prefs.getInt(_streakKey) ?? 0;
      final today = _dateString(DateTime.now());
      final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
      if (lastDate != today && lastDate != yesterday) {
        return 0;
      }
      return streak;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _dateString(DateTime.now());
      final lastDate = prefs.getString(_lastStudyDateKey) ?? '';
      int streak = prefs.getInt(_streakKey) ?? 0;
      if (lastDate == today) {
        return;
      }
      final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
      if (lastDate == yesterday) {
        streak++;
      } else {
        streak = 1;
      }
      await prefs.setString(_lastStudyDateKey, today);
      await prefs.setInt(_streakKey, streak);
    } catch (e) {
      if (kDebugMode) debugPrint('[SmartStudy] Streak update error: $e');
    }
  }

  Future<void> markFlashcardLearned(String cardId) async {
    final index = _flashcards.indexWhere((f) => f.id == cardId);
    if (index != -1) {
      _flashcards[index] = _flashcards[index].copyWith(
        learned: true,
        lastReviewed: DateTime.now(),
      );
      await _saveData();
    }
  }

  Future<void> updateFlashcardDifficulty(String cardId, String difficulty) async {
    final index = _flashcards.indexWhere((f) => f.id == cardId);
    if (index != -1) {
      _flashcards[index] = _flashcards[index].copyWith(difficulty: difficulty);
      await _saveData();
    }
  }

  List<StudyMaterial> getMaterials() => List.unmodifiable(_materials);
  List<Flashcard> getFlashcards() => List.unmodifiable(_flashcards);
  List<Quiz> getQuizzes() => List.unmodifiable(_quizzes);
  List<QuizResult> getQuizResults() => List.unmodifiable(_quizResults);

  String _extractJsonArray(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_materialsKey, jsonEncode(_materials.take(50).map((m) => m.toJson()).toList()));
      await prefs.setString(_flashcardsKey, jsonEncode(_flashcards.take(200).map((f) => f.toJson()).toList()));
      await prefs.setString(_quizzesKey, jsonEncode(_quizzes.take(30).map((q) => q.toJson()).toList()));
      await prefs.setString(_quizResultsKey, jsonEncode(_quizResults.take(50).map((r) => r.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) debugPrint('[SmartStudy] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _materials.clear();
      _materials.addAll((jsonDecode(prefs.getString(_materialsKey) ?? '[]') as List)
          .map((m) => StudyMaterial.fromJson(m as Map<String, dynamic>)));
      _flashcards.clear();
      _flashcards.addAll((jsonDecode(prefs.getString(_flashcardsKey) ?? '[]') as List)
          .map((f) => Flashcard.fromJson(f as Map<String, dynamic>)));
      _quizzes.clear();
      _quizzes.addAll((jsonDecode(prefs.getString(_quizzesKey) ?? '[]') as List)
          .map((q) => Quiz.fromJson(q as Map<String, dynamic>)));
      _quizResults.clear();
      _quizResults.addAll((jsonDecode(prefs.getString(_quizResultsKey) ?? '[]') as List)
          .map((r) => QuizResult.fromJson(r as Map<String, dynamic>)));
    } catch (e) {
      if (kDebugMode) debugPrint('[SmartStudy] Load error: $e');
    }
  }
}

class StudyMaterial {
  final String id;
  final String title;
  final String content;
  final String subject;
  final bool flashcardsGenerated;
  final bool quizzesGenerated;
  final DateTime createdAt;

  StudyMaterial({
    required this.id,
    required this.title,
    required this.content,
    required this.subject,
    required this.flashcardsGenerated,
    required this.quizzesGenerated,
    required this.createdAt,
  });

  StudyMaterial copyWith({
    bool? flashcardsGenerated,
    bool? quizzesGenerated,
  }) {
    return StudyMaterial(
      id: id,
      title: title,
      content: content,
      subject: subject,
      flashcardsGenerated: flashcardsGenerated ?? this.flashcardsGenerated,
      quizzesGenerated: quizzesGenerated ?? this.quizzesGenerated,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'subject': subject,
        'flashcardsGenerated': flashcardsGenerated,
        'quizzesGenerated': quizzesGenerated,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StudyMaterial.fromJson(Map<String, dynamic> json) => StudyMaterial(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        subject: json['subject'] ?? '',
        flashcardsGenerated: json['flashcardsGenerated'] ?? false,
        quizzesGenerated: json['quizzesGenerated'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String deck;
  bool learned;
  DateTime? lastReviewed;
  String difficulty;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.deck,
    required this.learned,
    this.lastReviewed,
    required this.difficulty,
  });

  Flashcard copyWith({
    bool? learned,
    DateTime? lastReviewed,
    String? difficulty,
  }) {
    return Flashcard(
      id: id,
      question: question,
      answer: answer,
      deck: deck,
      learned: learned ?? this.learned,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'deck': deck,
        'learned': learned,
        'lastReviewed': lastReviewed?.toIso8601String(),
        'difficulty': difficulty,
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'],
        question: json['question'],
        answer: json['answer'],
        deck: json['deck'] ?? 'Default',
        learned: json['learned'] ?? false,
        lastReviewed: json['lastReviewed'] != null ? DateTime.parse(json['lastReviewed']) : null,
        difficulty: json['difficulty'] ?? 'medium',
      );
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'],
        question: json['question'],
        options: List<String>.from(json['options'] ?? []),
        correctAnswer: json['correctAnswer'],
        explanation: json['explanation'] ?? '',
      );
}

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;
  int? score;
  bool completed;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
    this.score,
    required this.completed,
    required this.createdAt,
  });

  Quiz copyWith({
    int? score,
    bool? completed,
  }) {
    return Quiz(
      id: id,
      title: title,
      questions: questions,
      score: score ?? this.score,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
        'score': score,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'],
        title: json['title'],
        questions: (json['questions'] as List? ?? [])
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
        score: json['score'],
        completed: json['completed'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class QuizResult {
  final String id;
  final String quizId;
  final int score;
  final int total;
  final int percentage;
  final DateTime date;

  QuizResult({
    required this.id,
    required this.quizId,
    required this.score,
    required this.total,
    required this.percentage,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'quizId': quizId,
        'score': score,
        'total': total,
        'percentage': percentage,
        'date': date.toIso8601String(),
      };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        id: json['id'],
        quizId: json['quizId'],
        score: json['score'],
        total: json['total'],
        percentage: json['percentage'],
        date: DateTime.parse(json['date']),
      );
}
