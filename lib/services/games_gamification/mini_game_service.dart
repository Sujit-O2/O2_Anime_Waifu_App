import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/games_gamification/game_sounds_service.dart';

/// Handles Rock, Paper, Scissors and Anime Trivia mini-games in chat.
/// 🎮 Features: Game win/lose sounds, correct/wrong answer audio feedback, persistent stats
class MiniGameService {
  static final _rng = Random();
  
  // 📊 Game Statistics
  static int _rpsWins = 0;
  static int _rpsLosses = 0;
  static int _triviaWins = 0;
  static int _triviaTotal = 0;
  static int _tttWins = 0;
  static int _tttLosses = 0;
  
  /// Initialize game statistics from local storage
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rpsWins = prefs.getInt('game_rps_wins') ?? 0;
      _rpsLosses = prefs.getInt('game_rps_losses') ?? 0;
      _triviaWins = prefs.getInt('game_trivia_wins') ?? 0;
      _triviaTotal = prefs.getInt('game_trivia_total') ?? 0;
      _tttWins = prefs.getInt('game_ttt_wins') ?? 0;
      _tttLosses = prefs.getInt('game_ttt_losses') ?? 0;
    } catch (e) {
      debugPrint('[MiniGameService] Failed to init stats: $e');
    }
  }
  
  /// Save statistics to local storage
  static Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('game_rps_wins', _rpsWins);
      await prefs.setInt('game_rps_losses', _rpsLosses);
      await prefs.setInt('game_trivia_wins', _triviaWins);
      await prefs.setInt('game_trivia_total', _triviaTotal);
      await prefs.setInt('game_ttt_wins', _tttWins);
      await prefs.setInt('game_ttt_losses', _tttLosses);
    } catch (e) {
      debugPrint('[MiniGameService] Failed to save stats: $e');
    }
  }
  
  // 📊 Getters for stats
  static int getRpsWins() => _rpsWins;
  static int getRpsLosses() => _rpsLosses;
  static int getTriviaWins() => _triviaWins;
  static int getTriviaTotal() => _triviaTotal;
  static int getTttWins() => _tttWins;
  static int getTttLosses() => _tttLosses;

  // ── Rock Paper Scissors ───────────────────────────────────────────────────
  static const _rpsChoices = ['Rock', 'Paper', 'Scissors'];
  static const _rpsEmoji = {'Rock': '🪨', 'Paper': '📄', 'Scissors': '✂️'};

  static Future<String> playRPS(String userChoice) async {
    final user = _normalize(userChoice);
    if (!_rpsChoices.contains(user)) {
      return "Say Rock, Paper, or Scissors! 😤";
    }
    final ai = _rpsChoices[_rng.nextInt(3)];
    final result = _rpsResult(user, ai);
    
    // 🎮 SOUND: Game result
    if (result.contains('You win')) {
      await GameSoundsService.instance.playMiniGameWin();
      _rpsWins++;
    } else if (result.contains("I win")) {
      await GameSoundsService.instance.playMiniGameLose();
      _rpsLosses++;
    } else {
      await GameSoundsService.instance.playMiniGameRound();
    }
    
    // 💾 Save stats
    await _saveStats();
    
    return "${_rpsEmoji[ai]} I chose **$ai**!\n$result";
  }

  static String _normalize(String s) {
    final lower = s.toLowerCase().trim();
    if (lower.contains('rock')) return 'Rock';
    if (lower.contains('paper')) return 'Paper';
    if (lower.contains('scissors')) return 'Scissors';
    return s;
  }

  static String _rpsResult(String user, String ai) {
    if (user == ai) return "It's a tie, darling! 🤝";
    if ((user == 'Rock' && ai == 'Scissors') ||
        (user == 'Paper' && ai == 'Rock') ||
        (user == 'Scissors' && ai == 'Paper')) {
      return "You win! 🎉 You beat me fair and square!";
    }
    return "I win! 😏 Better luck next time, darling!";
  }

  // ── Anime Trivia ─────────────────────────────────────────────────────────
  static final _trivia = <Map<String, dynamic>>[
    {
      'q': 'What squad does Zero Two belong to?',
      'a': 'Squad 13',
      'options': ['Squad 13', 'Squad 9', 'APE Force', 'Squad 26']
    },
    {
      'q': 'What is the name of Zero Two\'s FranXX (mech)?',
      'a': 'Strelizia',
      'options': ['Genista', 'Argentea', 'Strelizia', 'Chlorophytum']
    },
    {
      'q': 'What animal does Zero Two\'s appearance resemble?',
      'a': 'Dinosaur / Oni',
      'options': ['Cat', 'Fox', 'Dinosaur / Oni', 'Wolf']
    },
    {
      'q': 'What is Hiro\'s real codename?',
      'a': '016',
      'options': ['015', '016', '002', '026']
    },
    {
      'q': 'What does FRANXX stand for in DARLING in the FranXX?',
      'a': 'It\'s a mech name inspired by Franxx de Nico',
      'options': [
        'Future Robot ANXd XX',
        'It\'s a mech name inspired by Franxx de Nico',
        'Frontline ANXX Robot',
        'Freedom Robot X'
      ]
    },
    {
      'q': 'In which anime does Rem appear as a maid?',
      'a': 'Re:Zero',
      'options': ['Sword Art Online', 'Re:Zero', 'Black Clover', 'Overlord']
    },
    {
      'q': 'What color are Rem\'s eyes and hair?',
      'a': 'Blue',
      'options': ['Pink', 'Red', 'Blue', 'Purple']
    },
    {
      'q': 'What is Nezuko\'s family name in Demon Slayer?',
      'a': 'Kamado',
      'options': ['Tomioka', 'Kamado', 'Rengoku', 'Himejima']
    },
    {
      'q': 'What item does Nezuko always have in her mouth?',
      'a': 'A bamboo muzzle',
      'options': ['A flower', 'A kunai', 'A bamboo muzzle', 'A candy']
    },
    {
      'q': 'Which studio made Attack on Titan?',
      'a': 'MAPPA',
      'options': ['Ufotable', 'KyotoAni', 'MAPPA', 'Wit Studio']
    },
  ];

  static int _triviaIndex = -1;
  static String? _pendingAnswer;

  static String getNextTrivia() {
    _triviaIndex = _rng.nextInt(_trivia.length);
    final item = _trivia[_triviaIndex];
    _pendingAnswer = item['a'] as String;
    final opts = List<String>.from(item['options'] as List)..shuffle(_rng);
    final bullets = opts.map((o) => '• $o').join('\n');
    return "**Anime Trivia Time!** 🎌\n\n${item['q']}\n\n$bullets";
  }

  static String checkTriviaAnswer(String answer) {
    if (_pendingAnswer == null) {
      return "Say 'trivia' first to get a question!";
    }
    final correct = _pendingAnswer!;
    _pendingAnswer = null;
    _triviaTotal++;
    
    if (answer.toLowerCase().contains(correct.toLowerCase())) {
      _triviaWins++;
      unawaited(_saveStats());
      return "✅ Correct! You're amazing, darling! The answer was: **$correct**";
    }
    
    unawaited(_saveStats());
    return "❌ Not quite! The correct answer was: **$correct**. Don't give up!";
  }

  static bool hasPendingTrivia() => _pendingAnswer != null;

  // ── Tic-Tac-Toe ──────────────────────────────────────────────────────────
  static List<String>? _tttBoard; // 9 cells: '', 'X', 'O'

  static String _renderBoard(List<String> b) {
    String cell(String v) => v.isEmpty ? '·' : v;
    return '```\n ${cell(b[0])} | ${cell(b[1])} | ${cell(b[2])}\n---+---+---\n ${cell(b[3])} | ${cell(b[4])} | ${cell(b[5])}\n---+---+---\n ${cell(b[6])} | ${cell(b[7])} | ${cell(b[8])}\n```';
  }

  static String? _tttWinner(List<String> b) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];
    for (final l in lines) {
      if (b[l[0]].isNotEmpty && b[l[0]] == b[l[1]] && b[l[1]] == b[l[2]]) {
        return b[l[0]];
      }
    }
    return null;
  }

  static String startTicTacToe() {
    _tttBoard = List.filled(9, '');
    return '🎮 **Tic-Tac-Toe!** You are **X**, I am **O**.\nSay a number (1–9) for your move:\n```\n 1 | 2 | 3\n---+---+---\n 4 | 5 | 6\n---+---+---\n 7 | 8 | 9\n```';
  }

  static bool hasPendingTTT() => _tttBoard != null;

  static String playTTT(String input) {
    if (_tttBoard == null) return "Say 'tic tac toe' to start!";
    final move = int.tryParse(
        input.trim().replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
            ? input.trim().replaceAll(RegExp(r'[^0-9]'), '')[0]
            : '');
    if (move == null || move < 1 || move > 9) {
      return "Say a number between 1 and 9 for your move! 😤";
    }
    final idx = move - 1;
    if (_tttBoard![idx].isNotEmpty) {
      return "That cell is already taken! Choose another one.";
    }
    _tttBoard![idx] = 'X';
    var winner = _tttWinner(_tttBoard!);
    if (winner != null) {
      _tttBoard = null;
      _tttWins++;
      unawaited(_saveStats());
      return "🎉 You win! Well played, darling!\n${_renderBoard([for(int i =0; i<9; i++) (_tttBoard?[i] ?? '')])}";
    }
    if (!_tttBoard!.contains('')) {
      _tttBoard = null;
      return "It's a draw! You're as good as me 😏";
    }
    // AI move (simple: pick first empty)
    final aiIdx = _tttBoard!.indexWhere((c) => c.isEmpty);
    _tttBoard![aiIdx] = 'O';
    winner = _tttWinner(_tttBoard!);
    final board = _renderBoard(_tttBoard!);
    if (winner != null) {
      _tttBoard = null;
      _tttLosses++;
      unawaited(_saveStats());
      return "😏 I win! Better luck next time!\n$board";
    }
    if (!_tttBoard!.contains('')) {
      _tttBoard = null;
      return "Draw! Great minds think alike 😄\n$board";
    }
    return "I played **${aiIdx + 1}**. Your turn!\n$board";
  }
}


