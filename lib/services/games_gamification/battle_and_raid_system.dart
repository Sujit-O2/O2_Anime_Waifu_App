import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/games_gamification/game_sounds_service.dart';

/// Battle & Raid Combat System
/// Player vs Enemy (PvE), Raids, Co-op challenges, Enemy AI
/// 🎮 Features: Combat sounds, victory fanfares, reward audio feedback
class BattleAndRaidSystem {
  static final BattleAndRaidSystem _instance = BattleAndRaidSystem._internal();

  factory BattleAndRaidSystem() {
    return _instance;
  }

  BattleAndRaidSystem._internal();

  late SharedPreferences _prefs;
  final Map<String, BattleSession> _activeBattles = {};
  final List<RaidCampaign> _raids = [];
  final Map<String, EnemyAI> _enemies = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _initializeEnemyAI();
    _loadRaidCampaigns();
    debugPrint('[Battle System] Initialized');
  }

  // ===== PLAYER STATS =====
  Future<PlayerBattleStats> getPlayerStats(String userId) async {
    final stored = _prefs.getString('player_battle_stats:$userId');
    if (stored != null) {
      try {
        return PlayerBattleStats.fromJson(jsonDecode(stored));
      } catch (_) {}
    }
    return PlayerBattleStats.default_(userId);
  }

  Future<void> updatePlayerStats(String userId, PlayerBattleStats stats) async {
    await _prefs.setString('player_battle_stats:$userId', jsonEncode(stats.toJson()));
  }

  // ===== QUICK BATTLE MODE =====
  Future<BattleSession> startQuickBattle(String userId, String difficulty) async {
    final playerStats = await getPlayerStats(userId);
    final enemy = _generateEnemy(difficulty, playerStats.level);
    
    final battle = BattleSession(
      battleId: 'battle_${DateTime.now().millisecondsSinceEpoch}',
      playerId: userId,
      playerStats: playerStats,
      enemy: enemy,
      enemyAI: _enemies[difficulty] ?? EnemyAI.default_(),
      turns: [],
      battleState: 'ongoing',
      startTime: DateTime.now(),
    );

    _activeBattles[battle.battleId] = battle;
    return battle;
  }

  /// Execute turn in battle
  Future<BattleTurnResult> executeTurn(String battleId, String action, int targetHp) async {
    final battle = _activeBattles[battleId];
    if (battle == null) throw Exception('Battle not found');

    final playerDamage = _calculateDamage(battle.playerStats.attack, battle.enemy.defense);
    final enemyDamage = _calculateEnemyDamage(battle.enemyAI, battle.playerStats.defense);

    // 🎮 SOUND EFFECTS
    // Player attack sound
    if (playerDamage > 0) {
      if (playerDamage > battle.enemy.defense * 2) {
        await GameSoundsService.instance.playCriticalHit(); // Critical hit!
      } else {
        await GameSoundsService.instance.playBattleHit(); // Normal hit
      }
    }

    battle.enemy.hp -= playerDamage;
    
    // Enemy counter-attack sound
    if (enemyDamage > 0) {
      await GameSoundsService.instance.playEnemyAttack();
    } else {
      await GameSoundsService.instance.playBlock(); // Blocked attack
    }

    battle.playerStats.hp -= enemyDamage;

    final turn = BattleTurn(
      turnNumber: battle.turns.length + 1,
      playerAction: action,
      playerDamage: playerDamage,
      enemyDamage: enemyDamage,
      playerHp: battle.playerStats.hp,
      enemyHp: battle.enemy.hp,
    );

    battle.turns.add(turn);

    // Check battle end
    if (battle.enemy.hp <= 0) {
      battle.battleState = 'won';
      await GameSoundsService.instance.playBattleVictory(); // Victory fanfare
      await _rewardBattleWin(battle);
    } else if (battle.playerStats.hp <= 0) {
      battle.battleState = 'lost';
      await GameSoundsService.instance.playBattleDefeat(); // Defeat sound
    }

    return BattleTurnResult(
      turnResult: turn,
      battleState: battle.battleState,
      isBattleOver: battle.battleState != 'ongoing',
    );
  }

  /// Auto-battle for quick results
  Future<BattleResult> autoComplete(String battleId, int maxTurns) async {
    final battle = _activeBattles[battleId];
    if (battle == null) throw Exception('Battle not found');

    for (int i = 0; i < maxTurns; i++) {
      if (battle.battleState != 'ongoing') break;
      await executeTurn(battleId, 'attack', battle.enemy.hp);
    }

    final reward = battle.battleState == 'won'
        ? _calculateReward(battle)
        : BattleReward(coins: 10, experience: 20, rarity: 'common');

    return BattleResult(
      battleId: battleId,
      outcome: battle.battleState,
      reward: reward,
      turnCount: battle.turns.length,
      durationSeconds: DateTime.now().difference(battle.startTime).inSeconds,
    );
  }

  // ===== RAIDS =====
  Future<List<RaidCampaign>> getAvailableRaids(String userId) async {
    return _raids.where((r) => !r.isCompleted).toList();
  }

  Future<void> joinRaid(String userId, String raidId) async {
    final raid = _raids.firstWhere((r) => r.raidId == raidId, orElse: () => RaidCampaign.default_());
    
    if (!raid.participants.contains(userId)) {
      raid.participants.add(userId);
      raid.totalDamage += 0;
      
      // 🎮 SOUND: Raid start / player joined
      await GameSoundsService.instance.playRaidStart();
    }

    await _prefs.setString('raid_progress:$userId:$raidId', jsonEncode(raid.toJson()));
  }

  Future<void> contributeRaidDamage(String userId, String raidId, int damage) async {
    final raid = _raids.firstWhere((r) => r.raidId == raidId);
    
    // 🎮 SOUND: Damage hit in raid
    await GameSoundsService.instance.playBattleHit();
    
    raid.totalDamage += damage;
    raid.participantDamage[userId] = (raid.participantDamage[userId] ?? 0) + damage;

    if (raid.totalDamage >= raid.healthRequired) {
      raid.isCompleted = true;
      
      // 🎮 SOUND: Raid completed - victory!
      await GameSoundsService.instance.playRaidComplete();
      
      await _distributeRaidRewards(raid);
    }
  }

  Future<RaidReward> getRaidReward(String userId, String raidId) async {
    final raid = _raids.firstWhere((r) => r.raidId == raidId);
    final contribution = raid.participantDamage[userId] ?? 0;
    final totalDamage = raid.totalDamage;

    const baseReward = 5000;
    final contributionPercentage = totalDamage > 0 ? contribution / totalDamage : 0.0;
    final reward = (baseReward * contributionPercentage).toInt();

    // 🎮 SOUND: Treasure found!
    await GameSoundsService.instance.playRaidTreasure();

    return RaidReward(
      raidId: raidId,
      userId: userId,
      coinReward: reward,
      premiumCurrency: (reward * 0.1).toInt(),
      successLevel: totalDamage >= raid.healthRequired ? 'defeated' : 'damaged',
    );
  }

  // ===== CO-OP CHALLENGES =====
  Future<CoopChallenge> createCoopChallenge(String playerId, String challengeName, int maxPlayers) async {
    final challenge = CoopChallenge(
      challengeId: 'coop_${DateTime.now().millisecondsSinceEpoch}',
      name: challengeName,
      creator: playerId,
      players: [playerId],
      maxPlayers: maxPlayers,
      difficulty: 'medium',
      objective: 'Defeat all enemies cooperatively',
      status: 'waiting',
      createdAt: DateTime.now(),
    );

    await _prefs.setString('coop_challenge:${challenge.challengeId}', jsonEncode(challenge.toJson()));
    return challenge;
  }

  Future<void> joinCoopChallenge(String playerId, String challengeId) async {
    final stored = _prefs.getString('coop_challenge:$challengeId');
    if (stored != null) {
      final challenge = CoopChallenge.fromJson(jsonDecode(stored));
      if (challenge.players.length < challenge.maxPlayers) {
        challenge.players.add(playerId);
        await _prefs.setString('coop_challenge:$challengeId', jsonEncode(challenge.toJson()));
      }
    }
  }

  // ===== ENEMY AI =====
  void _initializeEnemyAI() {
    _enemies['easy'] = EnemyAI(
      name: 'Goblin',
      aggressiveness: 0.3,
      intelligence: 0.2,
      dodgeChance: 0.1,
    );
    _enemies['medium'] = EnemyAI(
      name: 'Demon Lord',
      aggressiveness: 0.6,
      intelligence: 0.7,
      dodgeChance: 0.3,
    );
    _enemies['hard'] = EnemyAI(
      name: 'Ancient Dragon',
      aggressiveness: 0.9,
      intelligence: 0.95,
      dodgeChance: 0.6,
    );
  }

  Enemy _generateEnemy(String difficulty, int playerLevel) {
    final baseLvl = playerLevel + (difficulty == 'hard' ? 5 : difficulty == 'medium' ? 2 : 0);
    return Enemy(
      name: 'Enemy Lv$baseLvl',
      level: baseLvl,
      hp: 100 + (baseLvl * 20),
      attack: 20 + (baseLvl * 3),
      defense: 10 + (baseLvl * 2),
      experience: 100 + (baseLvl * 50),
    );
  }

  int _calculateDamage(int attack, int defense) {
    final baseDamage = attack - (defense ~/ 2);
    final variance = (baseDamage * 0.2).toInt();
    return (baseDamage + (variance * (0.5 - (DateTime.now().millisecond % 1000) / 1000))).toInt().clamp(1, 9999);
  }

  int _calculateEnemyDamage(EnemyAI ai, int playerDefense) {
    final damage = _calculateDamage(50, playerDefense);
    return (damage * (1 + (ai.aggressiveness - 0.5))).toInt();
  }

  Future<void> _rewardBattleWin(BattleSession battle) async {
    final stats = battle.playerStats;
    stats.wins++;
    stats.experience += battle.enemy.experience;
    stats.coins += 100;

    // 🎮 SOUND: Reward collection
    await GameSoundsService.instance.playRewardCollect();

    while (stats.experience >= stats.nextLevelExperience) {
      stats.experience -= stats.nextLevelExperience;
      stats.level++;
      stats.attack += 5;
      stats.defense += 3;
      stats.hp += 20;
      stats.nextLevelExperience = (stats.nextLevelExperience * 1.1).toInt();
      
      // 🎮 SOUND: Level up!
      await GameSoundsService.instance.playLevelUp();
    }

    await updatePlayerStats(battle.playerId, stats);
  }

  BattleReward _calculateReward(BattleSession battle) {
    const baseCoins = 500;
    final levelBonus = battle.enemy.level * 50;
    final difficultyMultiplier = battle.turns.length < 5 ? 2.0 : 1.0;
    
    return BattleReward(
      coins: ((baseCoins + levelBonus) * difficultyMultiplier).toInt(),
      experience: battle.enemy.experience * 2,
      rarity: battle.turns.length < 3 ? 'legendary' : battle.turns.length < 5 ? 'rare' : 'common',
    );
  }

  Future<void> _distributeRaidRewards(RaidCampaign raid) async {
    for (final participant in raid.participants) {
      final _ = await getRaidReward(participant, raid.raidId);
      // Send to monetization service
    }
  }

  void _loadRaidCampaigns() {
    _raids.addAll([
      RaidCampaign(
        raidId: 'raid_titans',
        name: 'Titans Assault',
        healthRequired: 50000,
        totalDamage: 0,
        participants: [],
        participantDamage: {},
        isCompleted: false,
      ),
      RaidCampaign(
        raidId: 'raid_gods',
        name: 'God Slayers',
        healthRequired: 100000,
        totalDamage: 0,
        participants: [],
        participantDamage: {},
        isCompleted: false,
      ),
    ]);
  }
}

// ===== DATA MODELS =====

class PlayerBattleStats {
  String userId;
  int level;
  int experience;
  int nextLevelExperience;
  int hp;
  int maxHp;
  int attack;
  int defense;
  int coins;
  int wins;
  int losses;
  double winRate;

  PlayerBattleStats({
    required this.userId,
    required this.level,
    required this.experience,
    required this.nextLevelExperience,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.coins,
    required this.wins,
    required this.losses,
    required this.winRate,
  });

  factory PlayerBattleStats.default_(String userId) => PlayerBattleStats(
    userId: userId,
    level: 1,
    experience: 0,
    nextLevelExperience: 100,
    hp: 100,
    maxHp: 100,
    attack: 20,
    defense: 10,
    coins: 0,
    wins: 0,
    losses: 0,
    winRate: 0.0,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'level': level,
    'exp': experience,
    'nextLvlExp': nextLevelExperience,
    'hp': hp,
    'maxHp': maxHp,
    'atk': attack,
    'def': defense,
    'coins': coins,
    'wins': wins,
    'losses': losses,
    'wr': winRate,
  };

  factory PlayerBattleStats.fromJson(Map<String, dynamic> json) => PlayerBattleStats(
    userId: json['userId'],
    level: json['level'],
    experience: json['exp'],
    nextLevelExperience: json['nextLvlExp'],
    hp: json['hp'],
    maxHp: json['maxHp'],
    attack: json['atk'],
    defense: json['def'],
    coins: json['coins'],
    wins: json['wins'],
    losses: json['losses'],
    winRate: (json['wr'] as num).toDouble(),
  );
}

class BattleSession {
  String battleId;
  String playerId;
  PlayerBattleStats playerStats;
  Enemy enemy;
  EnemyAI enemyAI;
  List<BattleTurn> turns;
  String battleState;
  DateTime startTime;

  BattleSession({
    required this.battleId,
    required this.playerId,
    required this.playerStats,
    required this.enemy,
    required this.enemyAI,
    required this.turns,
    required this.battleState,
    required this.startTime,
  });
}

class BattleTurn {
  int turnNumber;
  String playerAction;
  int playerDamage;
  int enemyDamage;
  int playerHp;
  int enemyHp;

  BattleTurn({
    required this.turnNumber,
    required this.playerAction,
    required this.playerDamage,
    required this.enemyDamage,
    required this.playerHp,
    required this.enemyHp,
  });
}

class BattleTurnResult {
  BattleTurn turnResult;
  String battleState;
  bool isBattleOver;

  BattleTurnResult({
    required this.turnResult,
    required this.battleState,
    required this.isBattleOver,
  });
}

class BattleResult {
  String battleId;
  String outcome;
  BattleReward reward;
  int turnCount;
  int durationSeconds;

  BattleResult({
    required this.battleId,
    required this.outcome,
    required this.reward,
    required this.turnCount,
    required this.durationSeconds,
  });
}

class BattleReward {
  int coins;
  int experience;
  String rarity;

  BattleReward({
    required this.coins,
    required this.experience,
    required this.rarity,
  });
}

class Enemy {
  String name;
  int level;
  int hp;
  int attack;
  int defense;
  int experience;

  Enemy({
    required this.name,
    required this.level,
    required this.hp,
    required this.attack,
    required this.defense,
    required this.experience,
  });
}

class EnemyAI {
  String name;
  double aggressiveness;
  double intelligence;
  double dodgeChance;

  EnemyAI({
    required this.name,
    required this.aggressiveness,
    required this.intelligence,
    required this.dodgeChance,
  });

  factory EnemyAI.default_() => EnemyAI(
    name: 'Enemy',
    aggressiveness: 0.5,
    intelligence: 0.5,
    dodgeChance: 0.2,
  );
}

class RaidCampaign {
  String raidId;
  String name;
  int healthRequired;
  int totalDamage;
  List<String> participants;
  Map<String, int> participantDamage;
  bool isCompleted;

  RaidCampaign({
    required this.raidId,
    required this.name,
    required this.healthRequired,
    required this.totalDamage,
    required this.participants,
    required this.participantDamage,
    required this.isCompleted,
  });

  factory RaidCampaign.default_() => RaidCampaign(
    raidId: '',
    name: '',
    healthRequired: 10000,
    totalDamage: 0,
    participants: [],
    participantDamage: {},
    isCompleted: false,
  );

  Map<String, dynamic> toJson() => {
    'raidId': raidId,
    'name': name,
    'healthRequired': healthRequired,
    'totalDamage': totalDamage,
    'participants': participants,
    'participantDamage': participantDamage,
    'isCompleted': isCompleted,
  };

  factory RaidCampaign.fromJson(Map<String, dynamic> json) => RaidCampaign(
    raidId: json['raidId'],
    name: json['name'],
    healthRequired: json['healthRequired'],
    totalDamage: json['totalDamage'],
    participants: List<String>.from(json['participants']),
    participantDamage: Map<String, int>.from(json['participantDamage']),
    isCompleted: json['isCompleted'],
  );
}

class RaidReward {
  String raidId;
  String userId;
  int coinReward;
  int premiumCurrency;
  String successLevel;

  RaidReward({
    required this.raidId,
    required this.userId,
    required this.coinReward,
    required this.premiumCurrency,
    required this.successLevel,
  });
}

class CoopChallenge {
  String challengeId;
  String name;
  String creator;
  List<String> players;
  int maxPlayers;
  String difficulty;
  String objective;
  String status;
  DateTime createdAt;

  CoopChallenge({
    required this.challengeId,
    required this.name,
    required this.creator,
    required this.players,
    required this.maxPlayers,
    required this.difficulty,
    required this.objective,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'challengeId': challengeId,
    'name': name,
    'creator': creator,
    'players': players,
    'maxPlayers': maxPlayers,
    'difficulty': difficulty,
    'objective': objective,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CoopChallenge.fromJson(Map<String, dynamic> json) => CoopChallenge(
    challengeId: json['challengeId'],
    name: json['name'],
    creator: json['creator'],
    players: List<String>.from(json['players']),
    maxPlayers: json['maxPlayers'],
    difficulty: json['difficulty'],
    objective: json['objective'],
    status: json['status'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}


