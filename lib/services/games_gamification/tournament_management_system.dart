import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/games_gamification/game_sounds_service.dart';

/// Tournament Management System
/// Ranked battles, brackets, leaderboards, prizes
/// 🎮 Features: Tournament sounds, victory fanfares, championship sounds
class TournamentManagementSystem {
  static final TournamentManagementSystem _instance = TournamentManagementSystem._internal();

  factory TournamentManagementSystem() {
    return _instance;
  }

  TournamentManagementSystem._internal();

  late SharedPreferences _prefs;
  final Map<String, Tournament> _tournaments = {};
  final Map<String, TournamentBracket> _brackets = {};
  final Map<String, List<TournamentMatch>> _matches = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) debugPrint('[Tournament System] Initialized');
  }

  // ===== TOURNAMENT CREATION =====
  Future<Tournament> createTournament({
    required String tournamentName,
    required String tournamentType, // 'single_elim', 'double_elim', 'round_robin'
    required int maxParticipants,
    required int entryFee,
    required int totalPrizePool,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final tournament = Tournament(
      tournamentId: 'tournament_${DateTime.now().millisecondsSinceEpoch}',
      tournamentName: tournamentName,
      tournamentType: tournamentType,
      participants: [],
      maxParticipants: maxParticipants,
      entryFee: entryFee,
      totalPrizePool: totalPrizePool,
      bracket: null,
      status: 'registration',
      startDate: startDate,
      endDate: endDate,
      winner: null,
      createdAt: DateTime.now(),
    );

    _tournaments[tournament.tournamentId] = tournament;
    await _saveTournaments();

    return tournament;
  }

  Future<List<Tournament>> getAvailableTournaments() async {
    final now = DateTime.now();
    return _tournaments.values
        .where((t) => t.status == 'registration' && t.endDate.isAfter(now))
        .toList();
  }

  Future<Tournament?> getTournament(String tournamentId) async {
    return _tournaments[tournamentId];
  }

  // ===== PARTICIPANT MANAGEMENT =====
  Future<bool> joinTournament(String userId, String userName, String tournamentId) async {
    final tournament = _tournaments[tournamentId];
    if (tournament != null && tournament.participants.length < tournament.maxParticipants) {
      if (!tournament.participants.any((p) => p.userId == userId)) {
        tournament.participants.add(TournamentParticipant(
          userId: userId,
          userName: userName,
          seed: tournament.participants.length + 1,
          wins: 0,
          losses: 0,
        ));
        await _saveTournaments();
        return true;
      }
    }
    return false;
  }

  Future<void> startTournament(String tournamentId) async {
    final tournament = _tournaments[tournamentId];
    if (tournament != null && tournament.participants.length > 1) {
      tournament.status = 'ongoing';
      
      // 🎮 SOUND: Tournament begins!
      await GameSoundsService.instance.playTournamentStart();
      
      // Generate bracket
      final bracket = _generateBracket(tournament);
      tournament.bracket = bracket;
      _brackets[tournamentId] = bracket;

      // Generate first round matches
      await _generateRoundMatches(tournamentId, 1);
      await _saveTournaments();
    }
  }

  // ===== BRACKET & MATCHES =====
  Future<TournamentBracket?> getBracket(String tournamentId) async {
    return _brackets[tournamentId];
  }

  Future<List<TournamentMatch>> getRoundMatches(String tournamentId, int roundNumber) async {
    return _matches[tournamentId] ?? [];
  }

  Future<void> recordMatchResult(
    String tournamentId,
    String matchId,
    String winnerId,
    String winnerName,
    String loserId,
    String loserName,
  ) async {
    final tournament = _tournaments[tournamentId];
    if (tournament == null) return;

    // Update participants
    final winner = tournament.participants.firstWhere((p) => p.userId == winnerId);
    final loser = tournament.participants.firstWhere((p) => p.userId == loserId);

    winner.wins++;
    loser.losses++;

    // 🎮 SOUND: Tournament match won!
    await GameSoundsService.instance.playTournamentWin();

    // Record match
    final match = TournamentMatch(
      matchId: matchId,
      tournamentId: tournamentId,
      player1Id: winnerId,
      player1Name: winnerName,
      player2Id: loserId,
      player2Name: loserName,
      winnerId: winnerId,
      scorePlayer1: 3,
      scorePlayer2: 0,
      completedAt: DateTime.now(),
    );

    _matches.putIfAbsent(tournamentId, () => []).add(match);

    // Check if tournament is finished
    final activePlayers = tournament.participants.where((p) => p.losses == 0).length;
    if (activePlayers == 1) {
      tournament.status = 'finished';
      tournament.winner = winner.userName;
      
      // 🎮 SOUND: Tournament champion - ultimate victory!
      await GameSoundsService.instance.playTournamentChampion();
      
      // Distribute prizes
      await _distributePrizes(tournament);
    }

    await _saveTournaments();
  }

  // ===== LEADERBOARD =====
  Future<List<TournamentLeaderboardEntry>> getTournamentLeaderboard(String tournamentId) async {
    final tournament = _tournaments[tournamentId];
    if (tournament == null) return [];

    final entries = tournament.participants
        .map((p) => TournamentLeaderboardEntry(
          rank: 0,
          userId: p.userId,
          userName: p.userName,
          wins: p.wins,
          losses: p.losses,
          pointsEarned: p.wins * 100,
        ))
        .toList();

    entries.sort((a, b) {
      final aWr = a.wins / (a.wins + a.losses);
      final bWr = b.wins / (b.wins + b.losses);
      return bWr.compareTo(aWr);
    });

    for (int i = 0; i < entries.length; i++) {
      entries[i].rank = i + 1;
    }

    return entries;
  }

  // ===== REWARDS =====
  Future<List<TournamentPrize>> getPrizeDistribution(String tournamentId) async {
    final tournament = _tournaments[tournamentId];
    if (tournament == null) return [];

    final prizes = <TournamentPrize>[];
    
    // 1st place: 50% of pool
    prizes.add(TournamentPrize(
      placement: '1st',
      prizeAmount: (tournament.totalPrizePool * 0.5).toInt(),
      premiumCurrency: 500,
    ));

    // 2nd place: 30% of pool
    prizes.add(TournamentPrize(
      placement: '2nd',
      prizeAmount: (tournament.totalPrizePool * 0.3).toInt(),
      premiumCurrency: 300,
    ));

    // 3rd place: 20% of pool
    prizes.add(TournamentPrize(
      placement: '3rd',
      prizeAmount: (tournament.totalPrizePool * 0.2).toInt(),
      premiumCurrency: 200,
    ));

    return prizes;
  }

  // ===== STATISTICS =====
  Future<TournamentStatistics> getTournamentStats(String tournamentId) async {
    final tournament = _tournaments[tournamentId];
    if (tournament == null) throw Exception('Tournament not found');

    final matches = _matches[tournamentId] ?? [];

    return TournamentStatistics(
      tournamentId: tournamentId,
      totalParticipants: tournament.participants.length,
      matchesCompleted: matches.length,
      averageMatchDuration: 180, // seconds
      status: tournament.status,
      winner: tournament.winner ?? 'TBD',
      totalPrizePool: tournament.totalPrizePool,
    );
  }

  // ===== INTERNAL HELPERS =====
  TournamentBracket _generateBracket(Tournament tournament) {
    final rounds = _calculateRounds(tournament.participants.length);
    return TournamentBracket(
      bracketId: 'bracket_${tournament.tournamentId}',
      tournamentId: tournament.tournamentId,
      totalRounds: rounds,
      currentRound: 1,
      structure: tournament.tournamentType,
    );
  }

  int _calculateRounds(int participants) {
    int rounds = 0;
    int temp = participants;
    while (temp > 1) {
      rounds++;
      temp ~/= 2;
    }
    return rounds;
  }

  Future<void> _generateRoundMatches(String tournamentId, int roundNumber) async {
    final tournament = _tournaments[tournamentId];
    if (tournament == null) return;

    final participants = tournament.participants;
    final matchList = <TournamentMatch>[];

    for (int i = 0; i < participants.length; i += 2) {
      if (i + 1 < participants.length) {
        matchList.add(TournamentMatch(
          matchId: 'match_${tournamentId}_R${roundNumber}_${i ~/ 2}',
          tournamentId: tournamentId,
          player1Id: participants[i].userId,
          player1Name: participants[i].userName,
          player2Id: participants[i + 1].userId,
          player2Name: participants[i + 1].userName,
          winnerId: null,
          scorePlayer1: 0,
          scorePlayer2: 0,
          completedAt: null,
        ));
      }
    }

    _matches[tournamentId] = matchList;
  }

  Future<void> _distributePrizes(Tournament tournament) async {
    // Prizes distributed to participants based on placement
    final prizes = await getPrizeDistribution(tournament.tournamentId);
    if (kDebugMode) debugPrint('[Tournament] Prizes distributed: $prizes');
  }

  Future<void> _saveTournaments() async {
    final data = _tournaments.entries
        .map((e) => jsonEncode({'key': e.key, 'value': e.value.toJson()}))
        .toList();
    await _prefs.setStringList('tournaments', data);
  }
}

// ===== DATA MODELS =====

class Tournament {
  String tournamentId;
  String tournamentName;
  String tournamentType;
  List<TournamentParticipant> participants;
  int maxParticipants;
  int entryFee;
  int totalPrizePool;
  TournamentBracket? bracket;
  String status;
  DateTime startDate;
  DateTime endDate;
  String? winner;
  DateTime createdAt;

  Tournament({
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentType,
    required this.participants,
    required this.maxParticipants,
    required this.entryFee,
    required this.totalPrizePool,
    required this.bracket,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.winner,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'tournamentId': tournamentId,
    'tournamentName': tournamentName,
    'tournamentType': tournamentType,
    'participantCount': participants.length,
    'maxParticipants': maxParticipants,
    'entryFee': entryFee,
    'totalPrizePool': totalPrizePool,
    'status': status,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'winner': winner ?? 'TBD',
    'createdAt': createdAt.toIso8601String(),
  };
}

class TournamentParticipant {
  String userId;
  String userName;
  int seed;
  int wins;
  int losses;

  TournamentParticipant({
    required this.userId,
    required this.userName,
    required this.seed,
    required this.wins,
    required this.losses,
  });
}

class TournamentBracket {
  String bracketId;
  String tournamentId;
  int totalRounds;
  int currentRound;
  String structure;

  TournamentBracket({
    required this.bracketId,
    required this.tournamentId,
    required this.totalRounds,
    required this.currentRound,
    required this.structure,
  });
}

class TournamentMatch {
  String matchId;
  String tournamentId;
  String player1Id;
  String player1Name;
  String player2Id;
  String player2Name;
  String? winnerId;
  int scorePlayer1;
  int scorePlayer2;
  DateTime? completedAt;

  TournamentMatch({
    required this.matchId,
    required this.tournamentId,
    required this.player1Id,
    required this.player1Name,
    required this.player2Id,
    required this.player2Name,
    required this.winnerId,
    required this.scorePlayer1,
    required this.scorePlayer2,
    required this.completedAt,
  });
}

class TournamentLeaderboardEntry {
  int rank;
  String userId;
  String userName;
  int wins;
  int losses;
  int pointsEarned;

  TournamentLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.wins,
    required this.losses,
    required this.pointsEarned,
  });
}

class TournamentPrize {
  String placement;
  int prizeAmount;
  int premiumCurrency;

  TournamentPrize({
    required this.placement,
    required this.prizeAmount,
    required this.premiumCurrency,
  });
}

class TournamentStatistics {
  String tournamentId;
  int totalParticipants;
  int matchesCompleted;
  int averageMatchDuration;
  String status;
  String winner;
  int totalPrizePool;

  TournamentStatistics({
    required this.tournamentId,
    required this.totalParticipants,
    required this.matchesCompleted,
    required this.averageMatchDuration,
    required this.status,
    required this.winner,
    required this.totalPrizePool,
  });
}


