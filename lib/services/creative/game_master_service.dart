import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎮 Game Master Mode Service
/// 
/// For tabletop RPGs - generate NPCs, plot twists, and world-building elements.
class GameMasterService {
  GameMasterService._();
  static final GameMasterService instance = GameMasterService._();

  final List<RPGCampaign> _campaigns = [];
  final List<NPC> _npcs = [];
  final List<PlotTwist> _plotTwists = [];
  final List<WorldElement> _worldElements = [];
  
  int _totalCampaigns = 0;
  int _totalNPCs = 0;
  
  static const String _storageKey = 'game_master_v1';
  static const int _maxCampaigns = 50;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[GameMaster] Initialized with $_totalCampaigns campaigns');
  }

  Future<RPGCampaign> createCampaign({
    required String title,
    required RPGGenre genre,
    required String description,
    required String setting,
    required int playerCount,
    required DifficultyLevel difficulty,
  }) async {
    final campaign = RPGCampaign(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      genre: genre,
      description: description,
      setting: setting,
      playerCount: playerCount,
      difficulty: difficulty,
      status: CampaignStatus.planning,
      sessions: [],
      npcs: [],
      plotTwists: [],
      worldElements: [],
      currentSession: 0,
      mainPlot: '',
      themes: [],
      createdAt: DateTime.now(),
    );
    
    _campaigns.insert(0, campaign);
    _totalCampaigns++;
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[GameMaster] Created campaign: $title');
    return campaign;
  }

  Future<NPC> generateNPC({
    required String campaignId,
    required String name,
    required NPCRole role,
    required String description,
    required String personality,
    List<String>? motivations,
    List<String>? secrets,
    String? relationships,
  }) async {
    final npc = NPC(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      campaignId: campaignId,
      name: name,
      role: role,
      description: description,
      personality: personality,
      motivations: motivations ?? [],
      secrets: secrets ?? [],
      relationships: relationships,
      dialogueStyle: _generateDialogueStyle(personality),
      createdAt: DateTime.now(),
    );
    
    _npcs.insert(0, npc);
    _totalNPCs++;
    
    // Add to campaign
    final campaignIndex = _campaigns.indexWhere((c) => c.id == campaignId);
    if (campaignIndex != -1) {
      final campaign = _campaigns[campaignIndex];
      _campaigns[campaignIndex] = campaign.copyWith(
        npcs: [...campaign.npcs, npc.id],
      );
    }
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[GameMaster] Generated NPC: $name');
    return npc;
  }

  String _generateDialogueStyle(String personality) {
    final styles = <String>[];
    
    if (personality.toLowerCase().contains('friendly') || personality.toLowerCase().contains('warm')) {
      styles.add('Uses welcoming language and exclamations');
      styles.add('Asks questions to engage others');
      styles.add('Shares personal anecdotes');
    }
    
    if (personality.toLowerCase().contains('serious') || personality.toLowerCase().contains('stoic')) {
      styles.add('Speaks in measured, deliberate tones');
      styles.add('Prefers facts over emotions');
      styles.add('Uses formal language');
    }
    
    if (personality.toLowerCase().contains('chaotic') || personality.toLowerCase().contains('unpredictable')) {
      styles.add('Talks in riddles or metaphors');
      styles.add('Changes topics suddenly');
      styles.add('Uses dramatic pauses');
    }
    
    if (personality.toLowerCase().contains('wise') || personality.toLowerCase().contains('sage')) {
      styles.add('Speaks in parables and analogies');
      styles.add('Offers cryptic advice');
      styles.add('References ancient wisdom');
    }
    
    if (styles.isEmpty) {
      styles.add('Converses naturally with varied tone');
      styles.add('Adapts to conversation context');
    }
    
    return styles.join('\n');
  }

  Future<PlotTwist> generatePlotTwist({
    required String campaignId,
    required String title,
    required String description,
    required TwistType type,
    required int sessionHint,
    required String foreshadowing,
  }) async {
    final twist = PlotTwist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      campaignId: campaignId,
      title: title,
      description: description,
      type: type,
      sessionHint: sessionHint,
      foreshadowing: foreshadowing,
      revealed: false,
      createdAt: DateTime.now(),
    );
    
    _plotTwists.insert(0, twist);
    
    // Add to campaign
    final campaignIndex = _campaigns.indexWhere((c) => c.id == campaignId);
    if (campaignIndex != -1) {
      final campaign = _campaigns[campaignIndex];
      _campaigns[campaignIndex] = campaign.copyWith(
        plotTwists: [...campaign.plotTwists, twist.id],
      );
    }
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[GameMaster] Generated plot twist: $title');
    return twist;
  }

  Future<WorldElement> generateWorldElement({
    required String campaignId,
    required String name,
    required ElementType type,
    required String description,
    required String significance,
    List<String>? locations,
    List<String>? lore,
  }) async {
    final element = WorldElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      campaignId: campaignId,
      name: name,
      type: type,
      description: description,
      significance: significance,
      locations: locations ?? [],
      lore: lore ?? [],
      discovered: false,
      createdAt: DateTime.now(),
    );
    
    _worldElements.insert(0, element);
    
    // Add to campaign
    final campaignIndex = _campaigns.indexWhere((c) => c.id == campaignId);
    if (campaignIndex != -1) {
      final campaign = _campaigns[campaignIndex];
      _campaigns[campaignIndex] = campaign.copyWith(
        worldElements: [...campaign.worldElements, element.id],
      );
    }
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[GameMaster] Generated world element: $name');
    return element;
  }

  Future<void> addSession(String campaignId, String title, String description) async {
    final campaignIndex = _campaigns.indexWhere((c) => c.id == campaignId);
    if (campaignIndex == -1) return;
    
    final session = CampaignSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      sessionNumber: _campaigns[campaignIndex].sessions.length + 1,
      date: DateTime.now(),
      notes: '',
      events: [],
    );
    
    final campaign = _campaigns[campaignIndex];
    _campaigns[campaignIndex] = campaign.copyWith(
      sessions: [...campaign.sessions, session.id],
      currentSession: campaign.sessions.length + 1,
      status: CampaignStatus.inProgress,
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[GameMaster] Added session: $title');
  }

  Future<void> revealPlotTwist(String twistId) async {
    final twistIndex = _plotTwists.indexWhere((t) => t.id == twistId);
    if (twistIndex == -1) return;
    
    final twist = _plotTwists[twistIndex];
    _plotTwists[twistIndex] = twist.copyWith(revealed: true);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[GameMaster] Revealed plot twist: $twistId');
  }

  Future<void> discoverWorldElement(String elementId) async {
    final elementIndex = _worldElements.indexWhere((e) => e.id == elementId);
    if (elementIndex == -1) return;
    
    final element = _worldElements[elementIndex];
    _worldElements[elementIndex] = element.copyWith(discovered: true);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[GameMaster] Discovered world element: $elementId');
  }

  String generateRandomEncounter({
    required RPGGenre genre,
    required DifficultyLevel difficulty,
  }) {
    final encounters = <String>[];
    
    switch (genre) {
      case RPGGenre.fantasy:
        encounters.addAll([
          'A wounded traveler seeks shelter from a storm, but their wounds tell a different story',
          'Ancient ruins hold a puzzle that guards a forgotten treasure',
          'A dragon\'s shadow darkens the sky as it circles overhead',
          'Village children have gone missing, and tracks lead into the dark forest',
          'A merchant offers a map to a legendary city, but their eyes dart nervously',
        ]);
        break;
      case RPGGenre.scifi:
        encounters.addAll([
          'A derelict spaceship drifts silently, its distress signal repeating',
          'Alien ruins contain technology that defies understanding',
          'A space station reports a mysterious illness affecting the crew',
          'Smugglers offer passage through a dangerous nebula for a price',
          'An AI has gone rogue and taken control of a planetary defense system',
        ]);
        break;
      case RPGGenre.horror:
        encounters.addAll([
          'Something moves in the darkness just beyond the firelight',
          'The abandoned house whispers names from forgotten graves',
          'A mirror reflects a room that doesn\'t exist',
          'The forest path leads back to the same clearing again and again',
          'Voices from the walls promise secrets and power',
        ]);
        break;
      case RPGGenre.mystery:
        encounters.addAll([
          'A locked room murder with no apparent entrance or exit',
          'A coded message appears in the society pages of the newspaper',
          'A wealthy collector\'s prized artifact vanishes without a trace',
          'Witnesses describe impossible events at the scene of a crime',
          'A pattern emerges in seemingly unrelated deaths across the city',
        ]);
        break;
      case RPGGenre.superhero:
        encounters.addAll([
          'A bank robbery turns into a hostage situation with super-powered criminals',
          'A new hero appears in the city, but their methods are questionable',
          'Villains team up for a coordinated attack on multiple locations',
          'A natural disaster reveals an ancient artifact with strange powers',
          'The public turns against heroes after collateral damage from a battle',
        ]);
        break;
    }
    
    final baseEncounter = encounters[DateTime.now().millisecondsSinceEpoch % encounters.length];
    
    switch (difficulty) {
      case DifficultyLevel.easy:
        return '🌟 Simple Encounter:\n$baseEncounter\n\nThe threat is manageable with careful planning.';
      case DifficultyLevel.medium:
        return '⚠️ Moderate Challenge:\n$baseEncounter\n\nThis will test the party\'s skills and teamwork.';
      case DifficultyLevel.hard:
        return '🔥 Difficult Encounter:\n$baseEncounter\n\nOnly experienced adventurers should attempt this!';
      case DifficultyLevel.deadly:
        return '💀 Deadly Challenge:\n$baseEncounter\n\nThis could be the party\'s final adventure...';
    }
  }

  String generateNPCDialogue(NPC npc, String situation) {
    final dialogue = <String>[];
    
    dialogue.add('"${npc.name} says, adapting their tone to the situation:"');
    dialogue.add('');
    
    switch (situation.toLowerCase()) {
      case 'greeting':
        dialogue.add(_generateGreeting(npc));
        break;
      case 'threat':
        dialogue.add(_generateThreat(npc));
        break;
      case 'request':
        dialogue.add(_generateRequest(npc));
        break;
      case 'secret':
        dialogue.add(_generateSecret(npc));
        break;
      case 'farewell':
        dialogue.add(_generateFarewell(npc));
        break;
      default:
        dialogue.add(_generateGenericResponse(npc));
    }
    
    dialogue.add('');
    dialogue.add('Dialogue Style:');
    dialogue.add(npc.dialogueStyle);
    
    return dialogue.join('\n');
  }

  String _generateGreeting(NPC npc) {
    final greetings = <String>[];
    
    if (npc.role == NPCRole.ally) {
      greetings.add('"It\'s good to see you again, friend!"');
      greetings.add('"I was hoping you\'d come by today."');
    } else if (npc.role == NPCRole.merchant) {
      greetings.add('"Welcome, welcome! Looking for something special?"');
      greetings.add('"I have just the thing you\'ve been searching for."');
    } else if (npc.role == NPCRole.villain) {
      greetings.add('"Ah, so you\'ve finally arrived. I expected you sooner."');
      greetings.add('"We meet again, though not under the best circumstances."');
    } else {
      greetings.add('"Greetings, traveler. What brings you to these parts?"');
      greetings.add('"It\'s not often we see strangers in these lands."');
    }
    
    return greetings[DateTime.now().millisecondsSinceEpoch % greetings.length];
  }

  String _generateThreat(NPC npc) {
    final threats = <String>[];
    
    if (npc.role == NPCRole.villain) {
      threats.add('"You dare challenge me? You\'ll regret this decision."');
      threats.add('"I\'ve been expecting someone foolish enough to try."');
    } else if (npc.role == NPCRole.neutral) {
      threats.add('"I don\'t want trouble, but I won\'t back down either."');
      threats.add('"You should reconsider before things get ugly."');
    } else {
      threats.add('"Please, let\'s not do this. There must be another way."');
      threats.add('"I don\'t want to fight, but I will defend myself if I must."');
    }
    
    return threats[DateTime.now().millisecondsSinceEpoch % threats.length];
  }

  String _generateRequest(NPC npc) {
    final requests = <String>[];
    
    if (npc.role == NPCRole.questGiver) {
      requests.add('"There\'s a task that needs doing, and I think you\'re the one for it."');
      requests.add('"I have a proposition that could benefit us both greatly."');
    } else if (npc.role == NPCRole.informant) {
      requests.add('"I have information you need, but it comes at a price."');
      requests.add('"I know things, but sharing knowledge requires trust."');
    } else {
      requests.add('"Could you help me with something? I\'m in a bit of a bind."');
      requests.add('"There\'s something I need, but I can\'t get it myself."');
    }
    
    return requests[DateTime.now().millisecondsSinceEpoch % requests.length];
  }

  String _generateSecret(NPC npc) {
    final secrets = <String>[];
    
    if (npc.secrets.isNotEmpty) {
      secrets.add('"Between us, ${npc.secrets.first}"');
    }
    
    secrets.addAll([
      '"I shouldn\'t be telling you this, but..."',
      '"This stays between us, understood?"',
      '"I\'m taking a risk sharing this with you..."',
    ]);
    
    return secrets[DateTime.now().millisecondsSinceEpoch % secrets.length];
  }

  String _generateFarewell(NPC npc) {
    final farewells = <String>[];
    
    if (npc.role == NPCRole.ally) {
      farewells.add('"Stay safe out there, friend. We\'ll meet again."');
      farewells.add('"May fortune favor you until our paths cross again."');
    } else if (npc.role == NPCRole.villain) {
      farewells.add('"This isn\'t over. I\'ll be watching you."');
      farewells.add('"You may have won this time, but the game continues."');
    } else {
      farewells.add('"Safe travels, and may your journey be prosperous."');
      farewells.add('"Take care, and don\'t be a stranger."');
    }
    
    return farewells[DateTime.now().millisecondsSinceEpoch % farewells.length];
  }

  String _generateGenericResponse(NPC npc) {
    final responses = <String>[];
    
    responses.add('"That\'s an interesting point you raise."');
    responses.add('"I see what you mean, but have you considered..."');
    responses.add('"Let me think about that for a moment."');
    responses.add('"That reminds me of something that happened long ago..."');
    
    return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
  }

  String getCampaignIdeas({
    required RPGGenre genre,
    required DifficultyLevel difficulty,
    required int playerCount,
  }) {
    final ideas = <String>[];
    
    switch (genre) {
      case RPGGenre.fantasy:
        ideas.addAll([
          'The Lost Kingdom: Explore ancient ruins to find a forgotten civilization',
          'Dragon\'s Wrath: A dragon threatens to destroy everything unless appeased',
          'The Prophecy: Fulfill an ancient prophecy before darkness consumes the world',
          'Political Intrigue: Navigate court politics while dark forces gather',
          'The Tournament: Compete in a grand tournament with world-changing stakes',
        ]);
        break;
      case RPGGenre.scifi:
        ideas.addAll([
          'First Contact: Humanity\'s first encounter with alien intelligence',
          'AI Uprising: Artificial intelligence has decided humans are obsolete',
          'Space Opera: Navigate galactic politics and interstellar warfare',
          'Time Paradox: Fix temporal anomalies before reality collapses',
          'Colonial Rebellion: Lead a revolution against an oppressive empire',
        ]);
        break;
      case RPGGenre.horror:
        ideas.addAll([
          'The Haunting: Investigate supernatural occurrences in an abandoned asylum',
          'Cosmic Horror: Face entities that defy human understanding',
          'Survival Horror: Stranded in a hostile environment with something hunting you',
          'Psychological Terror: Question what\'s real and what\'s in your mind',
          'The Curse: Break a generations-old curse before it claims more victims',
        ]);
        break;
      case RPGGenre.mystery:
        ideas.addAll([
          'The Perfect Crime: Solve a murder that seems impossible',
          'Conspiracy Unveiled: Uncover a secret society controlling world events',
          'Missing Person: Find someone who never existed in official records',
          'Art Heist: Track down stolen masterpieces with supernatural connections',
          'Cold Case: Reopen a decades-old investigation with new evidence',
        ]);
        break;
      case RPGGenre.superhero:
        ideas.addAll([
          'Origin Stories: How the heroes got their powers and came together',
          'Villain Team-Up: Face multiple villains working in concert',
          'Civil War: Heroes divided over how to use their powers',
          'Alien Invasion: Earth\'s mightiest defenders against extraterrestrial threats',
          'Legacy: Pass the torch to a new generation of heroes',
        ]);
        break;
    }
    
    final difficultyMod = difficulty == DifficultyLevel.easy ? 'Beginner-Friendly' :
                         difficulty == DifficultyLevel.medium ? 'Moderate Challenge' :
                         difficulty == DifficultyLevel.hard ? 'Experienced Players' : 'Veterans Only';
    
    return '🎲 Campaign Ideas (${genre.name} - $difficultyMod, $playerCount players):\n' + 
           ideas.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
  }

  String getGMAdvice() {
    final advice = [
      '🎯 Know your players\' preferences and comfort levels',
      '📝 Prepare thoroughly but stay flexible during sessions',
      '🎭 Give each player moments to shine',
      '⚖️ Balance challenge with fun - don\'t be afraid to adjust difficulty',
      '🎨 Describe scenes vividly to immerse players in the world',
      '🎵 Use music and sound effects to enhance atmosphere',
      '📖 Keep notes organized for continuity between sessions',
      '🤝 Encourage player creativity and problem-solving',
      '🎲 Remember that dice are tools, not dictators',
      '✨ Make failure interesting, not just frustrating',
    ];
    
    return '🎮 Game Master Advice:\n' + advice.map((a) => '• $a').join('\n');
  }

  String getCampaignInsights() {
    if (_campaigns.isEmpty) {
      return 'No campaigns created yet. Start your first RPG adventure!';
    }
    
    final active = _campaigns.where((c) => c.status == CampaignStatus.inProgress).length;
    const completed = 0; // Would calculate from completed campaigns
    
    final byGenre = <RPGGenre, int>{};
    for (final campaign in _campaigns) {
      byGenre[campaign.genre] = (byGenre[campaign.genre] ?? 0) + 1;
    }
    
    final buffer = StringBuffer();
    buffer.writeln('🎲 Game Master Insights:');
    buffer.writeln('• Total Campaigns: $_totalCampaigns');
    buffer.writeln('• Active Campaigns: $active');
    buffer.writeln('• Total NPCs: $_totalNPCs');
    buffer.writeln('• Plot Twists: ${_plotTwists.length}');
    buffer.writeln('• World Elements: ${_worldElements.length}');
    buffer.writeln('');
    buffer.writeln('Campaigns by Genre:');
    for (final entry in byGenre.entries) {
      buffer.writeln('  • ${entry.key.name}: ${entry.value}');
    }
    
    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'campaigns': _campaigns.take(20).map((c) => c.toJson()).toList(),
        'npcs': _npcs.take(100).map((n) => n.toJson()).toList(),
        'plotTwists': _plotTwists.take(50).map((p) => p.toJson()).toList(),
        'worldElements': _worldElements.take(50).map((w) => w.toJson()).toList(),
        'totalCampaigns': _totalCampaigns,
        'totalNPCs': _totalNPCs,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[GameMaster] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _campaigns.clear();
        _campaigns.addAll(
          (data['campaigns'] as List<dynamic>? ?? [])
              .map((c) => RPGCampaign.fromJson(c as Map<String, dynamic>))
        );
        
        _npcs.clear();
        _npcs.addAll(
          (data['npcs'] as List<dynamic>? ?? [])
              .map((n) => NPC.fromJson(n as Map<String, dynamic>))
        );
        
        _plotTwists.clear();
        _plotTwists.addAll(
          (data['plotTwists'] as List<dynamic>? ?? [])
              .map((p) => PlotTwist.fromJson(p as Map<String, dynamic>))
        );
        
        _worldElements.clear();
        _worldElements.addAll(
          (data['worldElements'] as List<dynamic>? ?? [])
              .map((w) => WorldElement.fromJson(w as Map<String, dynamic>))
        );
        
        _totalCampaigns = data['totalCampaigns'] as int? ?? 0;
        _totalNPCs = data['totalNPCs'] as int? ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[GameMaster] Load error: $e');
    }
  }
}

class RPGCampaign {
  final String id;
  final String title;
  final RPGGenre genre;
  final String description;
  final String setting;
  final int playerCount;
  final DifficultyLevel difficulty;
  CampaignStatus status;
  final List<String> sessions;
  final List<String> npcs;
  final List<String> plotTwists;
  final List<String> worldElements;
  int currentSession;
  final String mainPlot;
  final List<String> themes;
  final DateTime createdAt;

  RPGCampaign({
    required this.id,
    required this.title,
    required this.genre,
    required this.description,
    required this.setting,
    required this.playerCount,
    required this.difficulty,
    required this.status,
    required this.sessions,
    required this.npcs,
    required this.plotTwists,
    required this.worldElements,
    required this.currentSession,
    required this.mainPlot,
    required this.themes,
    required this.createdAt,
  });

  RPGCampaign copyWith({
    CampaignStatus? status,
    List<String>? sessions,
    List<String>? npcs,
    List<String>? plotTwists,
    List<String>? worldElements,
    int? currentSession,
    String? mainPlot,
    List<String>? themes,
  }) {
    return RPGCampaign(
      id: id,
      title: title,
      genre: genre,
      description: description,
      setting: setting,
      playerCount: playerCount,
      difficulty: difficulty,
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      npcs: npcs ?? this.npcs,
      plotTwists: plotTwists ?? this.plotTwists,
      worldElements: worldElements ?? this.worldElements,
      currentSession: currentSession ?? this.currentSession,
      mainPlot: mainPlot ?? this.mainPlot,
      themes: themes ?? this.themes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'genre': genre.name,
    'description': description,
    'setting': setting,
    'playerCount': playerCount,
    'difficulty': difficulty.name,
    'status': status.name,
    'sessions': sessions,
    'npcs': npcs,
    'plotTwists': plotTwists,
    'worldElements': worldElements,
    'currentSession': currentSession,
    'mainPlot': mainPlot,
    'themes': themes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RPGCampaign.fromJson(Map<String, dynamic> json) => RPGCampaign(
    id: json['id'],
    title: json['title'],
    genre: RPGGenre.values.firstWhere(
      (e) => e.name == json['genre'],
      orElse: () => RPGGenre.fantasy,
    ),
    description: json['description'],
    setting: json['setting'],
    playerCount: json['playerCount'],
    difficulty: DifficultyLevel.values.firstWhere(
      (e) => e.name == json['difficulty'],
      orElse: () => DifficultyLevel.medium,
    ),
    status: CampaignStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => CampaignStatus.planning,
    ),
    sessions: List<String>.from(json['sessions'] ?? []),
    npcs: List<String>.from(json['npcs'] ?? []),
    plotTwists: List<String>.from(json['plotTwists'] ?? []),
    worldElements: List<String>.from(json['worldElements'] ?? []),
    currentSession: json['currentSession'] ?? 0,
    mainPlot: json['mainPlot'] ?? '',
    themes: List<String>.from(json['themes'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class NPC {
  final String id;
  final String campaignId;
  final String name;
  final NPCRole role;
  final String description;
  final String personality;
  final List<String> motivations;
  final List<String> secrets;
  final String? relationships;
  final String dialogueStyle;
  final DateTime createdAt;

  NPC({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.role,
    required this.description,
    required this.personality,
    required this.motivations,
    required this.secrets,
    required this.relationships,
    required this.dialogueStyle,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'name': name,
    'role': role.name,
    'description': description,
    'personality': personality,
    'motivations': motivations,
    'secrets': secrets,
    'relationships': relationships,
    'dialogueStyle': dialogueStyle,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NPC.fromJson(Map<String, dynamic> json) => NPC(
    id: json['id'],
    campaignId: json['campaignId'],
    name: json['name'],
    role: NPCRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => NPCRole.neutral,
    ),
    description: json['description'],
    personality: json['personality'],
    motivations: List<String>.from(json['motivations'] ?? []),
    secrets: List<String>.from(json['secrets'] ?? []),
    relationships: json['relationships'],
    dialogueStyle: json['dialogueStyle'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class PlotTwist {
  final String id;
  final String campaignId;
  final String title;
  final String description;
  final TwistType type;
  final int sessionHint;
  final String foreshadowing;
  bool revealed;
  final DateTime createdAt;

  PlotTwist({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.description,
    required this.type,
    required this.sessionHint,
    required this.foreshadowing,
    required this.revealed,
    required this.createdAt,
  });

  PlotTwist copyWith({
    bool? revealed,
  }) {
    return PlotTwist(
      id: id,
      campaignId: campaignId,
      title: title,
      description: description,
      type: type,
      sessionHint: sessionHint,
      foreshadowing: foreshadowing,
      revealed: revealed ?? this.revealed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'title': title,
    'description': description,
    'type': type.name,
    'sessionHint': sessionHint,
    'foreshadowing': foreshadowing,
    'revealed': revealed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PlotTwist.fromJson(Map<String, dynamic> json) => PlotTwist(
    id: json['id'],
    campaignId: json['campaignId'],
    title: json['title'],
    description: json['description'],
    type: TwistType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TwistType.betrayal,
    ),
    sessionHint: json['sessionHint'],
    foreshadowing: json['foreshadowing'] ?? '',
    revealed: json['revealed'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class WorldElement {
  final String id;
  final String campaignId;
  final String name;
  final ElementType type;
  final String description;
  final String significance;
  final List<String> locations;
  final List<String> lore;
  bool discovered;
  final DateTime createdAt;

  WorldElement({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.type,
    required this.description,
    required this.significance,
    required this.locations,
    required this.lore,
    required this.discovered,
    required this.createdAt,
  });

  WorldElement copyWith({
    bool? discovered,
  }) {
    return WorldElement(
      id: id,
      campaignId: campaignId,
      name: name,
      type: type,
      description: description,
      significance: significance,
      locations: locations,
      lore: lore,
      discovered: discovered ?? this.discovered,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'name': name,
    'type': type.name,
    'description': description,
    'significance': significance,
    'locations': locations,
    'lore': lore,
    'discovered': discovered,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WorldElement.fromJson(Map<String, dynamic> json) => WorldElement(
    id: json['id'],
    campaignId: json['campaignId'],
    name: json['name'],
    type: ElementType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ElementType.location,
    ),
    description: json['description'],
    significance: json['significance'] ?? '',
    locations: List<String>.from(json['locations'] ?? []),
    lore: List<String>.from(json['lore'] ?? []),
    discovered: json['discovered'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class CampaignSession {
  final String id;
  final String title;
  final String description;
  final int sessionNumber;
  final DateTime date;
  final String notes;
  final List<String> events;

  CampaignSession({
    required this.id,
    required this.title,
    required this.description,
    required this.sessionNumber,
    required this.date,
    required this.notes,
    required this.events,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'sessionNumber': sessionNumber,
    'date': date.toIso8601String(),
    'notes': notes,
    'events': events,
  };

  factory CampaignSession.fromJson(Map<String, dynamic> json) => CampaignSession(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    sessionNumber: json['sessionNumber'],
    date: DateTime.parse(json['date']),
    notes: json['notes'] ?? '',
    events: List<String>.from(json['events'] ?? []),
  );
}

enum RPGGenre { fantasy, scifi, horror, mystery, superhero }
enum DifficultyLevel { easy, medium, hard, deadly }
enum CampaignStatus { planning, inProgress, completed, onHold }
enum NPCRole { ally, villain, neutral, merchant, questGiver, informant }
enum TwistType { betrayal, revelation, complication, deusExMachina, redHerring }
enum ElementType { location, artifact, creature, organization, legend }