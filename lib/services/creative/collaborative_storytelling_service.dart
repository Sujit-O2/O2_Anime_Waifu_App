import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📖 Collaborative Storytelling Service
///
/// Co-write stories, novels, or scripts with the AI.
class CollaborativeStorytellingService {
  CollaborativeStorytellingService._();
  static final CollaborativeStorytellingService instance =
      CollaborativeStorytellingService._();

  final List<StoryProject> _projects = [];
  final List<StoryChapter> _chapters = [];

  int _totalProjects = 0;
  int _totalChapters = 0;
  int _totalWords = 0;

  static const String _storageKey = 'collaborative_storytelling_v1';

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint('[Storytelling] Initialized with $_totalProjects projects');
  }

  Future<StoryProject> createStoryProject({
    required String title,
    required String genre,
    required String description,
    required StoryFormat format,
    required int targetChapters,
    String? targetWordCount,
  }) async {
    final project = StoryProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      genre: genre,
      description: description,
      format: format,
      targetChapters: targetChapters,
      targetWordCount: targetWordCount,
      currentChapter: 1,
      status: StoryStatus.planning,
      chapters: [],
      characters: [],
      worldBuilding: '',
      plotOutline: '',
      themes: [],
      createdAt: DateTime.now(),
    );

    _projects.insert(0, project);
    _totalProjects++;

    await _saveData();

    if (kDebugMode) debugPrint('[Storytelling] Created project: $title');
    return project;
  }

  Future<StoryChapter> createChapter({
    required String projectId,
    required String title,
    required String content,
    required int chapterNumber,
    String? summary,
    List<String>? characters,
    List<String>? themes,
  }) async {
    final chapter = StoryChapter(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      title: title,
      content: content,
      chapterNumber: chapterNumber,
      summary: summary,
      characters: characters ?? [],
      themes: themes ?? [],
      wordCount: content.split(' ').length,
      status: ChapterStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _chapters.insert(0, chapter);
    _totalChapters++;
    _totalWords += chapter.wordCount;

    // Update project
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex != -1) {
      final project = _projects[projectIndex];
      _projects[projectIndex] = project.copyWith(
        chapters: [...project.chapters, chapter.id],
        currentChapter: chapterNumber + 1,
        status: StoryStatus.inProgress,
      );
    }

    await _saveData();

    if (kDebugMode) debugPrint('[Storytelling] Created chapter: $title');
    return chapter;
  }

  Future<void> updateChapter({
    required String chapterId,
    required String content,
    String? summary,
    ChapterStatus? status,
  }) async {
    final chapterIndex = _chapters.indexWhere((c) => c.id == chapterId);
    if (chapterIndex == -1) return;

    final chapter = _chapters[chapterIndex];
    final newWordCount = content.split(' ').length;
    final wordCountDiff = newWordCount - chapter.wordCount;

    _chapters[chapterIndex] = chapter.copyWith(
      content: content,
      summary: summary,
      wordCount: newWordCount,
      status: status ?? chapter.status,
      updatedAt: DateTime.now(),
    );

    _totalWords += wordCountDiff;

    await _saveData();

    if (kDebugMode) debugPrint('[Storytelling] Updated chapter: $chapterId');
  }

  Future<void> addCharacterToProject({
    required String projectId,
    required String name,
    required String description,
    String? role,
    List<String>? traits,
    List<String>? backstory,
  }) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final character = StoryCharacter(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      role: role,
      traits: traits ?? [],
      backstory: backstory ?? [],
      createdAt: DateTime.now(),
    );

    final project = _projects[projectIndex];
    _projects[projectIndex] = project.copyWith(
      characters: [...project.characters, character],
    );

    await _saveData();

    if (kDebugMode) debugPrint('[Storytelling] Added character: $name');
  }

  Future<void> updateProjectOutline({
    required String projectId,
    String? worldBuilding,
    String? plotOutline,
    List<String>? themes,
  }) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final project = _projects[projectIndex];
    _projects[projectIndex] = project.copyWith(
      worldBuilding: worldBuilding ?? project.worldBuilding,
      plotOutline: plotOutline ?? project.plotOutline,
      themes: themes ?? project.themes,
    );

    await _saveData();

    if (kDebugMode)
      debugPrint('[Storytelling] Updated project outline: $projectId');
  }

  Future<void> updateProjectStatus(String projectId, StoryStatus status) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final project = _projects[projectIndex];
    _projects[projectIndex] = project.copyWith(status: status);

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[Storytelling] Updated project status: $projectId -> $status');
  }

  List<StoryChapter> getChaptersByProject(String projectId) {
    return _chapters.where((c) => c.projectId == projectId).toList()
      ..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
  }

  List<StoryProject> getProjectsByStatus(StoryStatus status) {
    return _projects.where((p) => p.status == status).toList();
  }

  List<StoryChapter> getChaptersByStatus(ChapterStatus status) {
    return _chapters.where((c) => c.status == status).toList();
  }

  String getStorySuggestions(String projectId) {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final chapters = getChaptersByProject(projectId);

    final suggestions = <String>[];

    if (chapters.isEmpty) {
      suggestions.add(
          'Start with an engaging opening scene that introduces your protagonist');
      suggestions.add(
          'Establish the setting and initial conflict within the first chapter');
      suggestions.add(
          'Introduce a supporting character who will play a key role later');
    } else if (chapters.length < project.targetChapters ~/ 2) {
      suggestions.add(
          'Develop the rising action - introduce complications and obstacles');
      suggestions
          .add('Deepen character relationships and reveal their motivations');
      suggestions
          .add('Add a plot twist that changes the direction of the story');
    } else {
      suggestions.add('Build toward the climax - increase tension and stakes');
      suggestions.add('Resolve major plot threads and character arcs');
      suggestions
          .add('Craft a satisfying conclusion that ties everything together');
    }

    // Genre-specific suggestions
    switch (project.genre.toLowerCase()) {
      case 'fantasy':
        suggestions
            .add('Expand your world-building with unique magical systems');
        suggestions.add('Introduce mythical creatures or legendary artifacts');
        break;
      case 'mystery':
        suggestions
            .add('Plant subtle clues that will make sense in retrospect');
        suggestions.add('Add red herrings to keep readers guessing');
        break;
      case 'romance':
        suggestions.add('Create moments of tension and misunderstanding');
        suggestions.add('Develop emotional intimacy between characters');
        break;
      case 'sci-fi':
        suggestions
            .add('Explore the implications of your technology on society');
        suggestions.add(
            'Introduce ethical dilemmas related to scientific advancement');
        break;
    }

    return '📝 Story Suggestions for "${project.title}":\n' +
        suggestions.map((s) => '• $s').join('\n');
  }

  String getWritingPrompts(String genre) {
    final prompts = <String>[];

    switch (genre.toLowerCase()) {
      case 'fantasy':
        prompts.addAll([
          'A forgotten prophecy suddenly becomes relevant when a long-lost artifact is discovered',
          'A magical academy student discovers their power works differently than everyone else\'s',
          'Two rival kingdoms must unite when an ancient evil awakens',
        ]);
        break;
      case 'mystery':
        prompts.addAll([
          'A detective receives an anonymous letter predicting their own murder',
          'Every witness to a crime gives a completely different account of what happened',
          'A locked room murder occurs during a blizzard with no footprints in or out',
        ]);
        break;
      case 'romance':
        prompts.addAll([
          'Two people who hate each other are forced to work together on a long project',
          'A mistaken text message leads to an unexpected connection',
          'Years after a painful breakup, former lovers meet again under different circumstances',
        ]);
        break;
      case 'sci-fi':
        prompts.addAll([
          'Humanity discovers they are not the creators of AI, but its creation',
          'A time traveler realizes they are the cause of the historical event they tried to prevent',
          'First contact reveals that all intelligent species share the same dream',
        ]);
        break;
      case 'horror':
        prompts.addAll([
          'A family moves into a house where the rooms rearrange themselves when no one is looking',
          'Someone realizes they are the only person who remembers a deceased loved one',
          'A small town\'s residents begin speaking in unison, but not in any known language',
        ]);
        break;
      default:
        prompts.addAll([
          'Write about a character who discovers they have been living someone else\'s life',
          'A seemingly ordinary object holds the key to solving a decades-old mystery',
          'Two strangers meet and realize they have more in common than they could have imagined',
        ]);
    }

    return '✍️ Writing Prompts (${genre.toUpperCase()}):\n' +
        prompts
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${e.value}')
            .join('\n');
  }

  String getStoryInsights() {
    if (_projects.isEmpty) {
      return 'No story projects started yet. Begin your creative journey!';
    }

    final inProgress =
        _projects.where((p) => p.status == StoryStatus.inProgress).length;
    final completed =
        _projects.where((p) => p.status == StoryStatus.completed).length;

    final buffer = StringBuffer();
    buffer.writeln('📖 Storytelling Insights:');
    buffer.writeln('• Total Projects: $_totalProjects');
    buffer.writeln('• In Progress: $inProgress');
    buffer.writeln('• Completed: $completed');
    buffer.writeln('• Total Chapters: $_totalChapters');
    buffer.writeln('• Total Words: $_totalWords');

    if (_totalChapters > 0) {
      final avgWords = _totalWords ~/ _totalChapters;
      buffer.writeln('• Average Words per Chapter: $avgWords');
      buffer.writeln(
          '• Estimated Pages: ${(_totalWords / 250).toStringAsFixed(0)}');
    }

    // Genre breakdown
    final byGenre = <String, int>{};
    for (final project in _projects) {
      byGenre[project.genre] = (byGenre[project.genre] ?? 0) + 1;
    }

    if (byGenre.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Projects by Genre:');
      for (final entry in byGenre.entries) {
        buffer.writeln('  • ${entry.key}: ${entry.value}');
      }
    }

    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'projects': _projects.take(20).map((p) => p.toJson()).toList(),
        'chapters': _chapters.take(100).map((c) => c.toJson()).toList(),
        'totalProjects': _totalProjects,
        'totalChapters': _totalChapters,
        'totalWords': _totalWords,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[Storytelling] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        _projects.clear();
        _projects.addAll((data['projects'] as List<dynamic>)
            .map((p) => StoryProject.fromJson(p as Map<String, dynamic>)));

        _chapters.clear();
        _chapters.addAll((data['chapters'] as List<dynamic>)
            .map((c) => StoryChapter.fromJson(c as Map<String, dynamic>)));

        _totalProjects = data['totalProjects'] as int;
        _totalChapters = data['totalChapters'] as int;
        _totalWords = data['totalWords'] as int;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Storytelling] Load error: $e');
    }
  }
}

class StoryProject {
  final String id;
  final String title;
  final String genre;
  final String description;
  final StoryFormat format;
  final int targetChapters;
  final String? targetWordCount;
  int currentChapter;
  StoryStatus status;
  final List<String> chapters;
  final List<StoryCharacter> characters;
  String worldBuilding;
  String plotOutline;
  final List<String> themes;
  final DateTime createdAt;

  StoryProject({
    required this.id,
    required this.title,
    required this.genre,
    required this.description,
    required this.format,
    required this.targetChapters,
    this.targetWordCount,
    required this.currentChapter,
    required this.status,
    required this.chapters,
    required this.characters,
    required this.worldBuilding,
    required this.plotOutline,
    required this.themes,
    required this.createdAt,
  });

  StoryProject copyWith({
    int? currentChapter,
    StoryStatus? status,
    List<String>? chapters,
    List<StoryCharacter>? characters,
    String? worldBuilding,
    String? plotOutline,
    List<String>? themes,
  }) {
    return StoryProject(
      id: id,
      title: title,
      genre: genre,
      description: description,
      format: format,
      targetChapters: targetChapters,
      targetWordCount: targetWordCount,
      currentChapter: currentChapter ?? this.currentChapter,
      status: status ?? this.status,
      chapters: chapters ?? this.chapters,
      characters: characters ?? this.characters,
      worldBuilding: worldBuilding ?? this.worldBuilding,
      plotOutline: plotOutline ?? this.plotOutline,
      themes: themes ?? this.themes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'genre': genre,
        'description': description,
        'format': format.name,
        'targetChapters': targetChapters,
        'targetWordCount': targetWordCount,
        'currentChapter': currentChapter,
        'status': status.name,
        'chapters': chapters,
        'characters': characters.map((c) => c.toJson()).toList(),
        'worldBuilding': worldBuilding,
        'plotOutline': plotOutline,
        'themes': themes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StoryProject.fromJson(Map<String, dynamic> json) => StoryProject(
        id: json['id'],
        title: json['title'],
        genre: json['genre'],
        description: json['description'],
        format: StoryFormat.values.firstWhere(
          (e) => e.name == json['format'],
          orElse: () => StoryFormat.novel,
        ),
        targetChapters: json['targetChapters'],
        targetWordCount: json['targetWordCount'],
        currentChapter: json['currentChapter'],
        status: StoryStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => StoryStatus.planning,
        ),
        chapters: List<String>.from(json['chapters'] ?? []),
        characters: (json['characters'] as List<dynamic>? ?? [])
            .map((c) => StoryCharacter.fromJson(c as Map<String, dynamic>))
            .toList(),
        worldBuilding: json['worldBuilding'] ?? '',
        plotOutline: json['plotOutline'] ?? '',
        themes: List<String>.from(json['themes'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class StoryChapter {
  final String id;
  final String projectId;
  final String title;
  final String content;
  final int chapterNumber;
  final String? summary;
  final List<String> characters;
  final List<String> themes;
  final int wordCount;
  ChapterStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoryChapter({
    required this.id,
    required this.projectId,
    required this.title,
    required this.content,
    required this.chapterNumber,
    this.summary,
    required this.characters,
    required this.themes,
    required this.wordCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  StoryChapter copyWith({
    String? content,
    String? summary,
    int? wordCount,
    ChapterStatus? status,
    DateTime? updatedAt,
  }) {
    return StoryChapter(
      id: id,
      projectId: projectId,
      title: title,
      content: content ?? this.content,
      chapterNumber: chapterNumber,
      summary: summary ?? this.summary,
      characters: characters,
      themes: themes,
      wordCount: wordCount ?? this.wordCount,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'content': content,
        'chapterNumber': chapterNumber,
        'summary': summary,
        'characters': characters,
        'themes': themes,
        'wordCount': wordCount,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StoryChapter.fromJson(Map<String, dynamic> json) => StoryChapter(
        id: json['id'],
        projectId: json['projectId'],
        title: json['title'],
        content: json['content'],
        chapterNumber: json['chapterNumber'],
        summary: json['summary'],
        characters: List<String>.from(json['characters'] ?? []),
        themes: List<String>.from(json['themes'] ?? []),
        wordCount: json['wordCount'],
        status: ChapterStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ChapterStatus.draft,
        ),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class StoryCharacter {
  final String id;
  final String name;
  final String description;
  final String? role;
  final List<String> traits;
  final List<String> backstory;
  final DateTime createdAt;

  StoryCharacter({
    required this.id,
    required this.name,
    required this.description,
    this.role,
    required this.traits,
    required this.backstory,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'role': role,
        'traits': traits,
        'backstory': backstory,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StoryCharacter.fromJson(Map<String, dynamic> json) => StoryCharacter(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        role: json['role'],
        traits: List<String>.from(json['traits'] ?? []),
        backstory: List<String>.from(json['backstory'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

enum StoryFormat { novel, shortStory, screenplay, comic, interactive }

enum StoryStatus { planning, inProgress, completed, onHold }

enum ChapterStatus { draft, revised, finalized, published }
