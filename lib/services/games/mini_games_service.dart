import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// 🎮 Interactive Mini-Games Service
class MiniGamesService {
  MiniGamesService._();
  static final MiniGamesService instance = MiniGamesService._();

  GameSession? _currentSession;
  final math.Random _random = math.Random();

  GameSession? get currentSession => _currentSession;

  Future<GameSession> startGame({required GameType type, required GameDifficulty difficulty}) async {
    _currentSession = GameSession(type: type, difficulty: difficulty, startTime: DateTime.now(), score: 0, questionsAnswered: 0);
    if (kDebugMode) debugPrint('[MiniGames] Started: ${type.label} (${difficulty.label})');
    return _currentSession!;
  }

  TriviaQuestion generateTriviaQuestion(GameDifficulty difficulty) {
    final questions = _getTriviaQuestions(difficulty);
    return questions[_random.nextInt(questions.length)];
  }

  List<TriviaQuestion> _getTriviaQuestions(GameDifficulty difficulty) {
    if (difficulty == GameDifficulty.easy) {
      return [
        TriviaQuestion(question: 'What is Zero Two\'s code number?', options: ['002', '001', '003', '004'], correctIndex: 0, points: 10),
        TriviaQuestion(question: 'What color is Zero Two\'s hair?', options: ['Pink', 'Blue', 'Red', 'White'], correctIndex: 0, points: 10),
        TriviaQuestion(question: 'What does Zero Two call her partner?', options: ['Darling', 'Honey', 'Love', 'Dear'], correctIndex: 0, points: 10),
      ];
    } else if (difficulty == GameDifficulty.medium) {
      return [
        TriviaQuestion(question: 'What is Zero Two\'s Franxx unit called?', options: ['Strelizia', 'Delphinium', 'Argentea', 'Genista'], correctIndex: 0, points: 20),
        TriviaQuestion(question: 'What species is Zero Two?', options: ['Klaxosaur-human hybrid', 'Pure human', 'Pure Klaxosaur', 'Android'], correctIndex: 0, points: 20),
      ];
    } else {
      return [
        TriviaQuestion(question: 'What is the name of Zero Two\'s picture book?', options: ['The Beast and the Prince', 'The Princess and the Beast', 'The Golden City', 'The Blue Bird'], correctIndex: 0, points: 30),
        TriviaQuestion(question: 'What squad number is Zero Two part of?', options: ['Squad 13', 'Squad 26', 'Squad 9', 'Squad 7'], correctIndex: 0, points: 30),
      ];
    }
  }

  WordGameChallenge generateWordGame() {
    final words = ['DARLING', 'LOVE', 'HEART', 'SWEET', 'KISS', 'HUG', 'SMILE', 'HAPPY'];
    final word = words[_random.nextInt(words.length)];
    final scrambled = (word.split('')..shuffle()).join();
    return WordGameChallenge(originalWord: word, scrambledWord: scrambled, timeLimit: 30);
  }

  TruthOrDarePrompt generateTruthOrDare(bool isTruth) {
    if (isTruth) {
      final truths = [
        'What\'s your biggest secret?',
        'Who was your first crush?',
        'What\'s your most embarrassing moment?',
        'What\'s something you\'ve never told anyone?',
        'What\'s your biggest fear?',
      ];
      return TruthOrDarePrompt(prompt: truths[_random.nextInt(truths.length)], isTruth: true);
    } else {
      final dares = [
        'Send me a selfie right now!',
        'Tell me something you love about me',
        'Sing a song for me',
        'Do 10 jumping jacks',
        'Tell me a joke',
      ];
      return TruthOrDarePrompt(prompt: dares[_random.nextInt(dares.length)], isTruth: false);
    }
  }

  void recordAnswer(bool correct, int points) {
    if (_currentSession != null) {
      _currentSession!.questionsAnswered++;
      if (correct) _currentSession!.score += points;
    }
  }

  GameResult endGame() {
    if (_currentSession == null) return GameResult(score: 0, duration: Duration.zero, accuracy: 0);
    final duration = DateTime.now().difference(_currentSession!.startTime);
    final accuracy = _currentSession!.questionsAnswered > 0 ? _currentSession!.score / (_currentSession!.questionsAnswered * 20) : 0;
    final result = GameResult(score: _currentSession!.score, duration: duration, accuracy: accuracy.toDouble());
    _currentSession = null;
    return result;
  }
}

class GameSession {
  final GameType type;
  final GameDifficulty difficulty;
  final DateTime startTime;
  int score;
  int questionsAnswered;

  GameSession({required this.type, required this.difficulty, required this.startTime, required this.score, required this.questionsAnswered});
}

class TriviaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final int points;

  TriviaQuestion({required this.question, required this.options, required this.correctIndex, required this.points});
}

class WordGameChallenge {
  final String originalWord;
  final String scrambledWord;
  final int timeLimit;

  WordGameChallenge({required this.originalWord, required this.scrambledWord, required this.timeLimit});
}

class TruthOrDarePrompt {
  final String prompt;
  final bool isTruth;

  TruthOrDarePrompt({required this.prompt, required this.isTruth});
}

class GameResult {
  final int score;
  final Duration duration;
  final double accuracy;

  GameResult({required this.score, required this.duration, required this.accuracy});
}

enum GameType {
  trivia, wordGame, truthOrDare, riddles, quickMath, memoryMatch, storyBuilder, emojiGuess;

  String get label {
    switch (this) {
      case GameType.trivia: return 'Trivia';
      case GameType.wordGame: return 'Word Game';
      case GameType.truthOrDare: return 'Truth or Dare';
      case GameType.riddles: return 'Riddles';
      case GameType.quickMath: return 'Quick Math';
      case GameType.memoryMatch: return 'Memory Match';
      case GameType.storyBuilder: return 'Story Builder';
      case GameType.emojiGuess: return 'Emoji Guess';
    }
  }
}

enum GameDifficulty { easy, medium, hard;
  String get label {
    switch (this) {
      case GameDifficulty.easy: return 'Easy';
      case GameDifficulty.medium: return 'Medium';
      case GameDifficulty.hard: return 'Hard';
    }
  }
}
