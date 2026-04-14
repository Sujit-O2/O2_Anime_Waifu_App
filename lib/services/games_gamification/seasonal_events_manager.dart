import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/games_gamification/game_sounds_service.dart';

/// Seasonal Events Manager
/// Limited-time events, campaigns, battle passes, exclusive rewards
/// 🎮 Features: Gacha pulls, event completion sounds, battle pass tiers
class SeasonalEventsManager {
  static final SeasonalEventsManager _instance = SeasonalEventsManager._internal();

  factory SeasonalEventsManager() {
    return _instance;
  }

  SeasonalEventsManager._internal();

  late SharedPreferences _prefs;
  final List<Season> _seasons = [];
  final Map<String, EventCampaign> _campaigns = {};
  final Map<String, UserEventProgress> _userProgress = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _initializeSeasons();
    _loadCampaigns();
    debugPrint('[Seasonal Events] Initialized');
  }

  // ===== SEASONS =====
  Future<Season> getCurrentSeason() async {
    final now = DateTime.now();
    return _seasons.firstWhere(
      (s) => s.startDate.isBefore(now) && s.endDate.isAfter(now),
      orElse: () => _seasons.first,
    );
  }

  Future<List<Season>> getUpcomingSeasons() async {
    final now = DateTime.now();
    return _seasons.where((s) => s.startDate.isAfter(now)).toList();
  }

  // ===== EVENTS =====
  Future<List<EventCampaign>> getActiveEvents() async {
    final now = DateTime.now();
    return _campaigns.values
        .where((c) => c.startTime.isBefore(now) && c.endTime.isAfter(now))
        .toList();
  }

  Future<EventCampaign> createEvent({
    required String eventName,
    required DateTime startTime,
    required DateTime endTime,
    required String eventType, // 'story', 'battle_event', 'limited_gacha'
    required int maxParticipants,
  }) async {
    final event = EventCampaign(
      eventId: 'event_${DateTime.now().millisecondsSinceEpoch}',
      eventName: eventName,
      description: 'Limited-time event: $eventName',
      startTime: startTime,
      endTime: endTime,
      eventType: eventType,
      rewards: _generateEventRewards(eventType),
      participants: [],
      completions: 0,
      maxParticipants: maxParticipants,
      progressionRequired: 100,
      currentProgression: 0,
    );

    _campaigns[event.eventId] = event;
    await _saveCampaigns();
    return event;
  }

  Future<void> participateInEvent(String userId, String eventId) async {
    final event = _campaigns[eventId];
    if (event != null && !event.participants.contains(userId)) {
      event.participants.add(userId);
      _userProgress[userId] ??= UserEventProgress(userId: userId, events: {});
      _userProgress[userId]!.events[eventId] = EventProgress(
        eventId: eventId,
        progression: 0,
        claimed: false,
        joinedAt: DateTime.now(),
      );
      await _saveCampaigns();
      await _saveUserProgress();
    }
  }

  Future<void> updateEventProgress(String userId, String eventId, int progressAmount) async {
    final event = _campaigns[eventId];
    final userProgress = _userProgress[userId];

    if (event != null && userProgress != null && userProgress.events.containsKey(eventId)) {
      final prog = userProgress.events[eventId]!;
      prog.progression = (prog.progression + progressAmount).clamp(0, event.progressionRequired);

      if (prog.progression >= event.progressionRequired && !prog.claimed) {
        prog.claimed = true;
        event.completions++;
        
        // 🎮 SOUND: Event complete!
        await GameSoundsService.instance.playEventComplete();
      }

      await _saveUserProgress();
    }
  }

  Future<EventReward> claimEventReward(String userId, String eventId) async {
    final event = _campaigns[eventId];
    final userProgress = _userProgress[userId];

    if (event != null && userProgress != null && userProgress.events[eventId]?.claimed == true) {
      final baseReward = event.rewards.first;
      final bonusMultiplier = 1.0 + (event.completions * 0.01);

      // 🎮 SOUND: Treasure found - reward!
      await GameSoundsService.instance.playTreasureFound();

      return EventReward(
        eventId: eventId,
        userId: userId,
        coins: (baseReward.coins * bonusMultiplier).toInt(),
        premiumCurrency: baseReward.premiumCurrency,
        items: baseReward.items,
        claimedAt: DateTime.now(),
      );
    }

    return EventReward(
      eventId: eventId,
      userId: userId,
      coins: 0,
      premiumCurrency: 0,
      items: [],
      claimedAt: DateTime.now(),
    );
  }

  // ===== LIMITED GACHA =====
  Future<GachaPool> createLimitedGacha({
    required String gachaName,
    required List<String> exclusiveCharacters,
    required DateTime endDate,
    required int guaranteedPity,
  }) async {
    final gacha = GachaPool(
      gachaId: 'gacha_${DateTime.now().millisecondsSinceEpoch}',
      gachaName: gachaName,
      exclusiveCharacters: exclusiveCharacters,
      endDate: endDate,
      guaranteedPity: guaranteedPity,
      currentPity: 0,
      userPulls: {},
    );

    await _prefs.setString('gacha_pool:${gacha.gachaId}', jsonEncode(gacha.toJson()));
    return gacha;
  }

  Future<GachaPullResult> pullFromLimitedGacha(String userId, String gachaId, {bool usePremium = false}) async {
    final stored = _prefs.getString('gacha_pool:$gachaId');
    if (stored == null) throw Exception('Gacha not found');

    final gacha = GachaPool.fromJson(jsonDecode(stored));
    gacha.userPulls[userId] = (gacha.userPulls[userId] ?? 0) + 1;

    // 🎮 SOUND: Gacha pull spin animation
    await GameSoundsService.instance.playGachaPull();

    // 3% chance for guaranteed, guaranteed at pity
    bool isExclusive = (DateTime.now().millisecond % 100) < 3 || gacha.currentPity >= gacha.guaranteedPity;

    final character = isExclusive
        ? gacha.exclusiveCharacters[(DateTime.now().millisecond % gacha.exclusiveCharacters.length)]
        : 'Standard Character';

    if (isExclusive) {
      gacha.currentPity = 0;
      
      // 🎮 SOUND: 5-star / Legendary pull - celebration!
      await GameSoundsService.instance.playGachaLegendary();
    } else {
      gacha.currentPity++;
    }

    await _prefs.setString('gacha_pool:$gachaId', jsonEncode(gacha.toJson()));

    return GachaPullResult(
      characterObtained: character,
      isExclusive: isExclusive,
      pityCounter: gacha.currentPity,
      pulls: gacha.userPulls[userId] ?? 0,
    );
  }

  // ===== BATTLE PASS =====
  Future<BattlePassSeason> getCurrentBattlePass() async {
    final season = await getCurrentSeason();
    final stored = _prefs.getString('battle_pass:${season.seasonId}');
    
    if (stored != null) {
      return BattlePassSeason.fromJson(jsonDecode(stored));
    }

    final bp = BattlePassSeason(
      battlePassId: 'bp_${season.seasonId}',
      seasonId: season.seasonId,
      level: 1,
      experience: 0,
      maxLevel: 100,
      rewards: List.generate(100, (i) => _generateBattlePassReward(i)),
      claimedRewards: {},
    );

    await _prefs.setString('battle_pass:${season.seasonId}', jsonEncode(bp.toJson()));
    return bp;
  }

  Future<void> addBattlePassExperience(int amount) async {
    final bp = await getCurrentBattlePass();
    bp.experience += amount;

    // Progression: 1000 XP per level
    while (bp.experience >= 1000 && bp.level < bp.maxLevel) {
      bp.experience -= 1000;
      bp.level++;
      
      // 🎮 SOUND: Battle pass tier level up!
      await GameSoundsService.instance.playBattlePassTier();
    }

    await _prefs.setString('battle_pass:${bp.seasonId}', jsonEncode(bp.toJson()));
  }

  Future<BattlePassReward?> claimBattlePassReward(int level) async {
    final bp = await getCurrentBattlePass();
    
    if (bp.claimedRewards.containsKey(level) || level > bp.level) {
      return null;
    }

    final reward = bp.rewards[level - 1];
    bp.claimedRewards[level] = true;

    // 🎮 SOUND: Reward collected!
    await GameSoundsService.instance.playRewardCollect();

    await _prefs.setString('battle_pass:${bp.seasonId}', jsonEncode(bp.toJson()));
    return reward;
  }

  // ===== DAILY/WEEKLY MISSIONS =====
  Future<List<Mission>> getDailyMissions(String userId) async {
    final stored = _prefs.getString('daily_missions:$userId:${DateTime.now().day}');
    if (stored != null) {
      try {
        return List<Mission>.from(
          (jsonDecode(stored) as List).map((m) => Mission.fromJson(m))
        );
      } catch (_) {}
    }

    final missions = [
      Mission(
        id: 'daily_chat',
        title: 'Chat with Copilot',
        description: 'Have a conversation',
        objective: 'Send 5 messages',
        progress: 0,
        target: 5,
        reward: MissionReward(coins: 100, experience: 50),
      ),
      Mission(
        id: 'daily_watch',
        title: 'Watch Anime',
        description: 'Get entertainment fix',
        objective: 'Watch 1 episode or scene',
        progress: 0,
        target: 1,
        reward: MissionReward(coins: 200, experience: 100),
      ),
      Mission(
        id: 'daily_battle',
        title: 'Battle Challenge',
        description: 'Test your skills',
        objective: 'Win 1 battle',
        progress: 0,
        target: 1,
        reward: MissionReward(coins: 150, experience: 75),
      ),
    ];

    await _prefs.setString('daily_missions:$userId:${DateTime.now().day}', jsonEncode(missions));
    return missions;
  }

  Future<void> progressMission(String userId, String missionId, int amount) async {
    final missions = await getDailyMissions(userId);
    final mission = missions.firstWhere((m) => m.id == missionId, orElse: () => Mission.default_());

    mission.progress = (mission.progress + amount).clamp(0, mission.target);
    await _prefs.setString('daily_missions:$userId:${DateTime.now().day}', jsonEncode(missions));
  }

  // ===== SEASONAL SHOP =====
  Future<List<ShopItem>> getSeasonalShop() async {
    return [
      ShopItem(
        shopItemId: 'seasonal_char_exclusive',
        itemName: 'Exclusive Character Skin',
        description: 'Limited edition',
        price: 2000,
        currency: 'premium',
        stock: 100,
        soldOut: false,
      ),
      ShopItem(
        shopItemId: 'seasonal_avatar',
        itemName: 'Avatar Frame',
        description: 'Season-exclusive frame',
        price: 500,
        currency: 'coins',
        stock: 500,
        soldOut: false,
      ),
    ];
  }

  // ===== INTERNAL HELPERS =====
  void _initializeSeasons() {
    _seasons.addAll([
      Season(
        seasonId: 'season_spring_2026',
        name: 'Spring 2026 - Blossoms & Battles',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 5, 31),
        theme: 'spring',
        exclusiveRewards: ['Spring Avatar', 'Cherry Blossom Theme'],
      ),
      Season(
        seasonId: 'season_summer_2026',
        name: 'Summer 2026 - Festival Season',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 8, 31),
        theme: 'summer',
        exclusiveRewards: ['Festival Costume', 'Summer Cosmetics'],
      ),
    ]);
  }

  void _loadCampaigns() {
    _campaigns['campaign_valentines'] = EventCampaign(
      eventId: 'campaign_valentines',
      eventName: 'Valentine\'s Day Event',
      description: 'Limited-time Valentine\'s event',
      startTime: DateTime(2026, 2, 1),
      endTime: DateTime(2026, 2, 28),
      eventType: 'story',
      rewards: [EventReward(
        eventId: 'campaign_valentines',
        userId: 'sys',
        coins: 1000,
        premiumCurrency: 50,
        items: ['Valentine Avatar', 'Heart Theme'],
        claimedAt: DateTime.now(),
      )],
      participants: [],
      completions: 0,
      maxParticipants: 999999,
      progressionRequired: 100,
      currentProgression: 0,
    );
  }

  List<EventReward> _generateEventRewards(String eventType) {
    switch (eventType) {
      case 'story':
        return [EventReward(
          eventId: 'story_event',
          userId: 'sys',
          coins: 2000,
          premiumCurrency: 100,
          items: ['Story Avatar', 'Narrative Theme'],
          claimedAt: DateTime.now(),
        )];
      case 'battle_event':
        return [EventReward(
          eventId: 'battle_event',
          userId: 'sys',
          coins: 3000,
          premiumCurrency: 150,
          items: ['Battle Trophy', 'Combat Theme'],
          claimedAt: DateTime.now(),
        )];
      default:
        return [EventReward(
          eventId: 'default_event',
          userId: 'sys',
          coins: 1000,
          premiumCurrency: 50,
          items: [],
          claimedAt: DateTime.now(),
        )];
    }
  }

  BattlePassReward _generateBattlePassReward(int level) {
    final isFreeTier = level % 5 == 0;
    return BattlePassReward(
      level: level + 1,
      itemName: isFreeTier ? 'Premium Item Lv${level + 1}' : 'Free Item Lv${level + 1}',
      rarity: level > 50 ? 'legendary' : level > 25 ? 'rare' : 'common',
      isPremiumOnly: !isFreeTier,
    );
  }

  Future<void> _saveCampaigns() async {
    final data = _campaigns.entries
        .map((e) => jsonEncode({'key': e.key, 'value': e.value.toJson()}))
        .toList();
    await _prefs.setStringList('campaigns', data);
  }

  Future<void> _saveUserProgress() async {
    final data = _userProgress.entries
        .map((e) => jsonEncode({'key': e.key, 'value': e.value.toJson()}))
        .toList();
    await _prefs.setStringList('event_user_progress', data);
  }
}

// ===== DATA MODELS =====

class Season {
  String seasonId;
  String name;
  DateTime startDate;
  DateTime endDate;
  String theme;
  List<String> exclusiveRewards;

  Season({
    required this.seasonId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.theme,
    required this.exclusiveRewards,
  });
}

class EventCampaign {
  String eventId;
  String eventName;
  String description;
  DateTime startTime;
  DateTime endTime;
  String eventType;
  List<EventReward> rewards;
  List<String> participants;
  int completions;
  int maxParticipants;
  int progressionRequired;
  int currentProgression;

  EventCampaign({
    required this.eventId,
    required this.eventName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.eventType,
    required this.rewards,
    required this.participants,
    required this.completions,
    required this.maxParticipants,
    required this.progressionRequired,
    required this.currentProgression,
  });

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'eventName': eventName,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'eventType': eventType,
    'reward': rewards.isNotEmpty ? rewards.first.coins : 0,
    'participants': participants.length,
    'completions': completions,
    'maxParticipants': maxParticipants,
    'progressionRequired': progressionRequired,
    'currentProgression': currentProgression,
  };
}

class EventReward {
  String eventId;
  String userId;
  int coins;
  int premiumCurrency;
  List<String> items;
  DateTime claimedAt;

  EventReward({
    required this.eventId,
    required this.userId,
    required this.coins,
    required this.premiumCurrency,
    required this.items,
    required this.claimedAt,
  });
}

class EventProgress {
  String eventId;
  int progression;
  bool claimed;
  DateTime joinedAt;

  EventProgress({
    required this.eventId,
    required this.progression,
    required this.claimed,
    required this.joinedAt,
  });
}

class UserEventProgress {
  String userId;
  Map<String, EventProgress> events;

  UserEventProgress({required this.userId, required this.events});

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'events': events.map((k, v) => MapEntry(k, {
      'eventId': v.eventId,
      'progression': v.progression,
      'claimed': v.claimed,
      'joinedAt': v.joinedAt.toIso8601String(),
    })),
  };
}

class GachaPool {
  String gachaId;
  String gachaName;
  List<String> exclusiveCharacters;
  DateTime endDate;
  int guaranteedPity;
  int currentPity;
  Map<String, int> userPulls;

  GachaPool({
    required this.gachaId,
    required this.gachaName,
    required this.exclusiveCharacters,
    required this.endDate,
    required this.guaranteedPity,
    required this.currentPity,
    required this.userPulls,
  });

  Map<String, dynamic> toJson() => {
    'gachaId': gachaId,
    'gachaName': gachaName,
    'exclusiveCharacters': exclusiveCharacters,
    'endDate': endDate.toIso8601String(),
    'guaranteedPity': guaranteedPity,
    'currentPity': currentPity,
    'userPulls': userPulls,
  };

  factory GachaPool.fromJson(Map<String, dynamic> json) => GachaPool(
    gachaId: json['gachaId'],
    gachaName: json['gachaName'],
    exclusiveCharacters: List<String>.from(json['exclusiveCharacters']),
    endDate: DateTime.parse(json['endDate']),
    guaranteedPity: json['guaranteedPity'],
    currentPity: json['currentPity'],
    userPulls: Map<String, int>.from(json['userPulls']),
  );
}

class GachaPullResult {
  String characterObtained;
  bool isExclusive;
  int pityCounter;
  int pulls;

  GachaPullResult({
    required this.characterObtained,
    required this.isExclusive,
    required this.pityCounter,
    required this.pulls,
  });
}

class BattlePassSeason {
  String battlePassId;
  String seasonId;
  int level;
  int experience;
  int maxLevel;
  List<BattlePassReward> rewards;
  Map<int, bool> claimedRewards;

  BattlePassSeason({
    required this.battlePassId,
    required this.seasonId,
    required this.level,
    required this.experience,
    required this.maxLevel,
    required this.rewards,
    required this.claimedRewards,
  });

  Map<String, dynamic> toJson() => {
    'battlePassId': battlePassId,
    'seasonId': seasonId,
    'level': level,
    'experience': experience,
    'maxLevel': maxLevel,
    'claimedRewards': claimedRewards,
  };

  factory BattlePassSeason.fromJson(Map<String, dynamic> json) => BattlePassSeason(
    battlePassId: json['battlePassId'],
    seasonId: json['seasonId'],
    level: json['level'],
    experience: json['experience'],
    maxLevel: json['maxLevel'],
    rewards: [],
    claimedRewards: Map<int, bool>.from(json['claimedRewards'] ?? {}),
  );
}

class BattlePassReward {
  int level;
  String itemName;
  String rarity;
  bool isPremiumOnly;

  BattlePassReward({
    required this.level,
    required this.itemName,
    required this.rarity,
    required this.isPremiumOnly,
  });
}

class Mission {
  String id;
  String title;
  String description;
  String objective;
  int progress;
  int target;
  MissionReward reward;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.objective,
    required this.progress,
    required this.target,
    required this.reward,
  });

  factory Mission.default_() => Mission(
    id: '',
    title: '',
    description: '',
    objective: '',
    progress: 0,
    target: 0,
    reward: MissionReward(coins: 0, experience: 0),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'objective': objective,
    'progress': progress,
    'target': target,
    'reward': {'coins': reward.coins, 'experience': reward.experience},
  };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    objective: json['objective'],
    progress: json['progress'],
    target: json['target'],
    reward: MissionReward(
      coins: json['reward']['coins'],
      experience: json['reward']['experience'],
    ),
  );
}

class MissionReward {
  int coins;
  int experience;

  MissionReward({required this.coins, required this.experience});
}

class ShopItem {
  String shopItemId;
  String itemName;
  String description;
  int price;
  String currency;
  int stock;
  bool soldOut;

  ShopItem({
    required this.shopItemId,
    required this.itemName,
    required this.description,
    required this.price,
    required this.currency,
    required this.stock,
    required this.soldOut,
  });
}


