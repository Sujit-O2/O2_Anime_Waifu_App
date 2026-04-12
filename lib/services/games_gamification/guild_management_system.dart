import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anime_waifu/services/games_gamification/game_sounds_service.dart';

/// Guild/Clan Management System
/// Team formation, guild wars, treasury, ranks, perks
/// 🎮 Features: Guild war sounds, treasury sounds, perk unlock sounds
class GuildManagementSystem {
  static final GuildManagementSystem _instance = GuildManagementSystem._internal();

  factory GuildManagementSystem() {
    return _instance;
  }

  GuildManagementSystem._internal();

  late SharedPreferences _prefs;
  final Map<String, Guild> _guilds = {};
  final Map<String, GuildMember> _members = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadGuilds();
    debugPrint('[Guild System] Initialized');
  }

  // ===== GUILD CREATION & MANAGEMENT =====
  Future<Guild> createGuild({
    required String guildName,
    required String ownerId,
    required String ownerName,
    required String description,
    required int maxMembers,
  }) async {
    final guild = Guild(
      guildId: 'guild_${DateTime.now().millisecondsSinceEpoch}',
      guildName: guildName,
      ownerId: ownerId,
      ownerName: ownerName,
      description: description,
      members: [ownerId],
      maxMembers: maxMembers,
      level: 1,
      experience: 0,
      treasury: 0,
      founded: DateTime.now(),
      logo: '🏛️',
      perks: _getGuildPerks(1),
    );

    _guilds[guild.guildId] = guild;
    await _addGuildMember(ownerId, guild.guildId, 'leader', ownerName);
    await _saveGuilds();

    return guild;
  }

  Future<Guild?> getGuild(String guildId) async {
    return _guilds[guildId];
  }

  Future<void> updateGuildInfo(String guildId, String description) async {
    if (_guilds[guildId] != null) {
      _guilds[guildId]!.description = description;
      await _saveGuilds();
    }
  }

  // ===== MEMBERSHIP =====
  Future<void> joinGuild(String userId, String userName, String guildId) async {
    final guild = _guilds[guildId];
    if (guild != null && guild.members.length < guild.maxMembers) {
      if (!guild.members.contains(userId)) {
        guild.members.add(userId);
        await _addGuildMember(userId, guildId, 'member', userName);
        await _saveGuilds();
      }
    }
  }

  Future<void> leaveGuild(String userId, String guildId) async {
    final guild = _guilds[guildId];
    if (guild != null && guild.ownerId != userId) {
      guild.members.remove(userId);
      _members.remove('${guildId}_$userId');
      await _saveGuilds();
    }
  }

  Future<void> promoteToOfficer(String userId, String guildId) async {
    final memberKey = '${guildId}_$userId';
    if (_members[memberKey] != null) {
      _members[memberKey]!.rank = 'officer';
    }
  }

  Future<List<GuildMember>> getGuildMembers(String guildId) async {
    return _members.values
        .where((m) => m.guildId == guildId)
        .toList();
  }

  // ===== GUILD TREASURY & FUNDS =====
  Future<void> depositToTreasury(String guildId, int coins) async {
    final guild = _guilds[guildId];
    if (guild != null) {
      guild.treasury += coins;
      
      // 🎮 SOUND: Coin deposit into treasury
      await GameSoundsService.instance.playTreasuryDeposit();
      
      await _saveGuilds();
    }
  }

  Future<bool> withdrawFromTreasury(String guildId, int coins) async {
    final guild = _guilds[guildId];
    if (guild != null && guild.treasury >= coins) {
      guild.treasury -= coins;
      await _saveGuilds();
      return true;
    }
    return false;
  }

  // ===== GUILD WARS & BATTLES =====
  Future<GuildWar> declareWar(String attackingGuildId, String defendingGuildId) async {
    final war = GuildWar(
      warId: 'war_${DateTime.now().millisecondsSinceEpoch}',
      attackingGuildId: attackingGuildId,
      defendingGuildId: defendingGuildId,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(days: 7)),
      attackingGuildScore: 0,
      defendingGuildScore: 0,
      battleLog: [],
      status: 'ongoing',
    );

    // 🎮 SOUND: Guild war declared!
    await GameSoundsService.instance.playGuildWarStart();

    await _prefs.setString('guild_war:${war.warId}', jsonEncode(war.toJson()));
    return war;
  }

  Future<void> recordBattleResult(String warId, String winnerGuildId, String loserGuildId, int damageDealt) async {
    final stored = _prefs.getString('guild_war:$warId');
    if (stored != null) {
      final war = GuildWar.fromJson(jsonDecode(stored));

      if (war.attackingGuildId == winnerGuildId) {
        war.attackingGuildScore += damageDealt;
      } else {
        war.defendingGuildScore += damageDealt;
      }

      war.battleLog.add({
        'winner': winnerGuildId,
        'loser': loserGuildId,
        'damage': damageDealt,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 🎮 SOUND: Guild war victory!
      await GameSoundsService.instance.playGuildWarVictory();

      await _prefs.setString('guild_war:$warId', jsonEncode(war.toJson()));
    }
  }

  Future<GuildWar?> getGuildWar(String warId) async {
    final stored = _prefs.getString('guild_war:$warId');
    if (stored != null) {
      return GuildWar.fromJson(jsonDecode(stored));
    }
    return null;
  }

  // ===== GUILD LEVEL & PERKS =====
  Future<void> addGuildExperience(String guildId, int experience) async {
    final guild = _guilds[guildId];
    if (guild != null) {
      guild.experience += experience;

      const expPerLevel = 5000;
      while (guild.experience >= expPerLevel && guild.level < 100) {
        guild.experience -= expPerLevel;
        guild.level++;
        guild.perks = _getGuildPerks(guild.level);
        
        // 🎮 SOUND: Guild perk unlocked!
        await GameSoundsService.instance.playGuildPerkUnlocked();
      }

      await _saveGuilds();
    }
  }

  Future<List<GuildPerk>> getGuildPerks(String guildId) async {
    final guild = _guilds[guildId];
    return guild?.perks ?? [];
  }

  // ===== GUILD ANNOUNCEMENTS & POSTS =====
  Future<void> postAnnouncement(String guildId, String authorId, String title, String content) async {
    final post = GuildPost(
      postId: 'post_${DateTime.now().millisecondsSinceEpoch}',
      guildId: guildId,
      authorId: authorId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      likes: 0,
    );

    final key = 'guild_post:${post.postId}';
    await _prefs.setString(key, jsonEncode(post.toJson()));
  }

  Future<List<GuildPost>> getGuildAnnouncements(String guildId) async {
    final allEntries = _prefs.getKeys().where((k) => k.startsWith('guild_post:'));
    
    final posts = <GuildPost>[];
    for (final key in allEntries) {
      final stored = _prefs.getString(key);
      if (stored != null) {
        try {
          final post = GuildPost.fromJson(jsonDecode(stored));
          if (post.guildId == guildId) {
            posts.add(post);
          }
        } catch (_) {}
      }
    }

    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts.take(20).toList();
  }

  // ===== STATISTICS =====
  Future<GuildStatistics> getGuildStatistics(String guildId) async {
    final guild = _guilds[guildId];
    if (guild == null) throw Exception('Guild not found');

    final members = await getGuildMembers(guildId);
    final memberLvlAvg = members.isEmpty ? 0 : 0; // Would sum actual levels

    return GuildStatistics(
      guildId: guildId,
      totalMembers: guild.members.length,
      level: guild.level,
      treasury: guild.treasury,
      totalWars: 3, // Mock data
      winsCount: 2,
      averageMemberLevel: memberLvlAvg,
      founded: guild.founded,
    );
  }

  // ===== INTERNAL HELPERS =====
  List<GuildPerk> _getGuildPerks(int level) {
    final perks = <GuildPerk>[];
    
    if (level >= 1) perks.add(GuildPerk(perkName: 'Basic Guild', unlockLevel: 1, description: 'Create and manage guild'));
    if (level >= 5) perks.add(GuildPerk(perkName: 'Guild Wars', unlockLevel: 5, description: 'Declare wars with other guilds'));
    if (level >= 10) perks.add(GuildPerk(perkName: 'Treasury', unlockLevel: 10, description: '+5% coin collection'));
    if (level >= 20) perks.add(GuildPerk(perkName: 'Blessing', unlockLevel: 20, description: '+10% experience gain'));
    if (level >= 50) perks.add(GuildPerk(perkName: 'Dominance', unlockLevel: 50, description: '+20% attack in guild battles'));

    return perks;
  }

  Future<void> _addGuildMember(String userId, String guildId, String rank, String userName) async {
    _members['${guildId}_$userId'] = GuildMember(
      guildId: guildId,
      userId: userId,
      userName: userName,
      joinedAt: DateTime.now(),
      rank: rank,
      contribution: 0,
    );
  }

  Future<void> _loadGuilds() async {
    // Load all guilds from storage
  }

  Future<void> _saveGuilds() async {
    final data = _guilds.entries
        .map((e) => jsonEncode({'key': e.key, 'value': e.value.toJson()}))
        .toList();
    await _prefs.setStringList('guilds', data);
  }
}

// ===== DATA MODELS =====

class Guild {
  String guildId;
  String guildName;
  String ownerId;
  String ownerName;
  String description;
  List<String> members;
  int maxMembers;
  int level;
  int experience;
  int treasury;
  DateTime founded;
  String logo;
  List<GuildPerk> perks;

  Guild({
    required this.guildId,
    required this.guildName,
    required this.ownerId,
    required this.ownerName,
    required this.description,
    required this.members,
    required this.maxMembers,
    required this.level,
    required this.experience,
    required this.treasury,
    required this.founded,
    required this.logo,
    required this.perks,
  });

  Map<String, dynamic> toJson() => {
    'guildId': guildId,
    'guildName': guildName,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'description': description,
    'members': members.length,
    'maxMembers': maxMembers,
    'level': level,
    'experience': experience,
    'treasury': treasury,
    'founded': founded.toIso8601String(),
    'logo': logo,
  };
}

class GuildMember {
  String guildId;
  String userId;
  String userName;
  DateTime joinedAt;
  String rank;
  int contribution;

  GuildMember({
    required this.guildId,
    required this.userId,
    required this.userName,
    required this.joinedAt,
    required this.rank,
    required this.contribution,
  });
}

class GuildWar {
  String warId;
  String attackingGuildId;
  String defendingGuildId;
  DateTime startTime;
  DateTime endTime;
  int attackingGuildScore;
  int defendingGuildScore;
  List<Map<String, dynamic>> battleLog;
  String status;

  GuildWar({
    required this.warId,
    required this.attackingGuildId,
    required this.defendingGuildId,
    required this.startTime,
    required this.endTime,
    required this.attackingGuildScore,
    required this.defendingGuildScore,
    required this.battleLog,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'warId': warId,
    'attackingGuildId': attackingGuildId,
    'defendingGuildId': defendingGuildId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'attackingScore': attackingGuildScore,
    'defendingScore': defendingGuildScore,
    'battleLog': battleLog,
    'status': status,
  };

  factory GuildWar.fromJson(Map<String, dynamic> json) => GuildWar(
    warId: json['warId'],
    attackingGuildId: json['attackingGuildId'],
    defendingGuildId: json['defendingGuildId'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    attackingGuildScore: json['attackingScore'],
    defendingGuildScore: json['defendingScore'],
    battleLog: List<Map<String, dynamic>>.from(json['battleLog'] ?? []),
    status: json['status'],
  );
}

class GuildPerk {
  String perkName;
  int unlockLevel;
  String description;

  GuildPerk({
    required this.perkName,
    required this.unlockLevel,
    required this.description,
  });
}

class GuildPost {
  String postId;
  String guildId;
  String authorId;
  String title;
  String content;
  DateTime createdAt;
  int likes;

  GuildPost({
    required this.postId,
    required this.guildId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.likes,
  });

  Map<String, dynamic> toJson() => {
    'postId': postId,
    'guildId': guildId,
    'authorId': authorId,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'likes': likes,
  };

  factory GuildPost.fromJson(Map<String, dynamic> json) => GuildPost(
    postId: json['postId'],
    guildId: json['guildId'],
    authorId: json['authorId'],
    title: json['title'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    likes: json['likes'],
  );
}

class GuildStatistics {
  String guildId;
  int totalMembers;
  int level;
  int treasury;
  int totalWars;
  int winsCount;
  int averageMemberLevel;
  DateTime founded;

  GuildStatistics({
    required this.guildId,
    required this.totalMembers,
    required this.level,
    required this.treasury,
    required this.totalWars,
    required this.winsCount,
    required this.averageMemberLevel,
    required this.founded,
  });
}


