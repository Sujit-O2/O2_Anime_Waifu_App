import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎵 Music Composition Partner Service
/// 
/// Help create melodies, lyrics, or produce simple tracks.
class MusicCompositionService {
  MusicCompositionService._();
  static final MusicCompositionService instance = MusicCompositionService._();

  final List<MusicProject> _projects = [];
  final List<Track> _tracks = [];
  
  int _totalProjects = 0;
  int _totalTracks = 0;
  
  static const String _storageKey = 'music_composition_v1';
  static const int _maxProjects = 50;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode) debugPrint('[MusicComposition] Initialized with $_totalProjects projects');
  }

  Future<MusicProject> createMusicProject({
    required String title,
    required MusicGenre genre,
    required String description,
    required ProjectType type,
    required String mood,
    required int targetTracks,
  }) async {
    final project = MusicProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      genre: genre,
      description: description,
      type: type,
      mood: mood,
      targetTracks: targetTracks,
      status: ProjectStatus.planning,
      tracks: [],
      key: 'C',
      bpm: 120,
      scale: 'Major',
      lyrics: '',
      melody: '',
      chordProgression: '',
      instruments: [],
      createdAt: DateTime.now(),
    );
    
    _projects.insert(0, project);
    _totalProjects++;
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[MusicComposition] Created project: $title');
    return project;
  }

  Future<Track> createTrack({
    required String projectId,
    required String title,
    required TrackType type,
    required String content,
    String? lyrics,
    String? melody,
    String? chordProgression,
    List<String>? instruments,
  }) async {
    final track = Track(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      title: title,
      type: type,
      content: content,
      lyrics: lyrics,
      melody: melody,
      chordProgression: chordProgression,
      instruments: instruments ?? [],
      duration: _estimateDuration(content),
      status: TrackStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _tracks.insert(0, track);
    _totalTracks++;
    
    // Update project
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex != -1) {
      final project = _projects[projectIndex];
      _projects[projectIndex] = project.copyWith(
        tracks: [...project.tracks, track.id],
        status: ProjectStatus.inProgress,
      );
    }
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[MusicComposition] Created track: $title');
    return track;
  }

  int _estimateDuration(String content) {
    // Rough estimate: 150 words per minute for lyrics
    final words = content.split(' ').length;
    return (words / 150 * 60).round();
  }

  Future<void> updateTrack({
    required String trackId,
    String? content,
    String? lyrics,
    String? melody,
    String? chordProgression,
    List<String>? instruments,
    TrackStatus? status,
  }) async {
    final trackIndex = _tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex == -1) return;
    
    final track = _tracks[trackIndex];
    _tracks[trackIndex] = track.copyWith(
      content: content ?? track.content,
      lyrics: lyrics ?? track.lyrics,
      melody: melody ?? track.melody,
      chordProgression: chordProgression ?? track.chordProgression,
      instruments: instruments ?? track.instruments,
      status: status ?? track.status,
      updatedAt: DateTime.now(),
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[MusicComposition] Updated track: $trackId');
  }

  Future<void> updateProjectKey({
    required String projectId,
    required String key,
    required String scale,
    required int bpm,
  }) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;
    
    final project = _projects[projectIndex];
    _projects[projectIndex] = project.copyWith(
      key: key,
      scale: scale,
      bpm: bpm,
    );
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[MusicComposition] Updated project key: $projectId');
  }

  Future<void> addInstrumentToProject(String projectId, String instrument) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;
    
    final project = _projects[projectIndex];
    if (!project.instruments.contains(instrument)) {
      _projects[projectIndex] = project.copyWith(
        instruments: [...project.instruments, instrument],
      );
      await _saveData();
    }
  }

  Future<void> updateProjectStatus(String projectId, ProjectStatus status) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;
    
    final project = _projects[projectIndex];
    _projects[projectIndex] = project.copyWith(status: status);
    
    await _saveData();
    
    if (kDebugMode) debugPrint('[MusicComposition] Updated project status: $projectId -> $status');
  }

  List<Track> getTracksByProject(String projectId) {
    return _tracks.where((t) => t.projectId == projectId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<MusicProject> getProjectsByStatus(ProjectStatus status) {
    return _projects.where((p) => p.status == status).toList();
  }

  String generateLyrics({
    required String theme,
    required MusicGenre genre,
    required String mood,
    int verses = 2,
    bool includeChorus = true,
    bool includeBridge = false,
  }) {
    final buffer = StringBuffer();
    
    // Verse 1
    buffer.writeln('[Verse 1]');
    buffer.writeln(_generateVerse(theme, mood, genre));
    buffer.writeln();
    
    // Chorus
    if (includeChorus) {
      buffer.writeln('[Chorus]');
      buffer.writeln(_generateChorus(theme, mood, genre));
      buffer.writeln();
    }
    
    // Verse 2
    if (verses >= 2) {
      buffer.writeln('[Verse 2]');
      buffer.writeln(_generateVerse(theme, mood, genre, secondVerse: true));
      buffer.writeln();
    }
    
    // Chorus repeat
    if (includeChorus) {
      buffer.writeln('[Chorus]');
      buffer.writeln(_generateChorus(theme, mood, genre));
      buffer.writeln();
    }
    
    // Bridge
    if (includeBridge) {
      buffer.writeln('[Bridge]');
      buffer.writeln(_generateBridge(theme, mood, genre));
      buffer.writeln();
      
      if (includeChorus) {
        buffer.writeln('[Chorus]');
        buffer.writeln(_generateChorus(theme, mood, genre));
      }
    }
    
    return buffer.toString();
  }

  String _generateVerse(String theme, String mood, MusicGenre genre, {bool secondVerse = false}) {
    final lines = <String>[];
    
    switch (genre) {
      case MusicGenre.pop:
        lines.add('Walking through the city lights at night');
        lines.add('Thinking about you makes everything feel right');
        if (secondVerse) {
          lines.add('Every moment that we share feels so true');
          lines.add('I never want to be without you');
        }
        break;
      case MusicGenre.rock:
        lines.add('Thunder rolling in the distance');
        lines.add('Breaking through the resistance');
        if (secondVerse) {
          lines.add('Standing tall against the storm');
          lines.add('Finding shelter, keeping warm');
        }
        break;
      case MusicGenre.hipHop:
        lines.add('Yeah, checking in from the underground');
        lines.add('Making moves without a sound');
        if (secondVerse) {
          lines.add('Building up from the concrete floor');
          lines.add('Always asking for something more');
        }
        break;
      case MusicGenre.electronic:
        lines.add('Neon pulses in the dark');
        lines.add('Sparks are flying, making their mark');
        if (secondVerse) {
          lines.add('Digital dreams and synthetic skies');
          lines.add('Living life through electric eyes');
        }
        break;
      case MusicGenre.country:
        lines.add('Dusty roads and open skies');
        lines.add('Honest truth and no disguise');
        if (secondVerse) {
          lines.add('Fields of gold and morning dew');
          lines.add('Every breath I take is you');
        }
        break;
      case MusicGenre.jazz:
        lines.add('Midnight shadows, soft and deep');
        lines.add('Secrets that the night will keep');
        if (secondVerse) {
          lines.add('Blue notes hanging in the air');
          lines.add('Moments that we have to spare');
        }
        break;
      case MusicGenre.classical:
        lines.add('In the silence of the hall');
        lines.add('Where the echoes softly fall');
        if (secondVerse) {
          lines.add('Strings that weep and voices soar');
          lines.add('Opening up an ancient door');
        }
        break;
      case MusicGenre.rnb:
        lines.add('Smooth and slow, late at night');
        lines.add('Everything about you feels so right');
        if (secondVerse) {
          lines.add('Your touch is like a melody');
          lines.add('Setting my soul completely free');
        }
        break;
    }
    
    return lines.join('\n');
  }

  String _generateChorus(String theme, String mood, MusicGenre genre) {
    final lines = <String>[];
    
    switch (genre) {
      case MusicGenre.pop:
        lines.add('Oh, this is where we\'re meant to be');
        lines.add('Lost in you and you in me');
        lines.add('Nothing else could ever compare');
        lines.add('To the love that we share');
        break;
      case MusicGenre.rock:
        lines.add('We\'re standing strong against the tide');
        lines.add('With you right here by my side');
        lines.add('No force on earth could break us down');
        lines.add('We\'re kings and queens of this lost town');
        break;
      case MusicGenre.hipHop:
        lines.add('We rise up, never backing down');
        lines.add('Taking over every town');
        lines.add('From the bottom to the top');
        lines.add('And we\'re never gonna stop');
        break;
      case MusicGenre.electronic:
        lines.add('Electric love in digital space');
        lines.add('Finding rhythm, finding grace');
        lines.add('Pulses beating in the night');
        lines.add('We are the music, we are the light');
        break;
      case MusicGenre.country:
        lines.add('Back roads lead to where you are');
        lines.add('You\'re my compass, you\'re my star');
        lines.add('Simple life and open doors');
        lines.add('I could never want for more');
        break;
      case MusicGenre.jazz:
        lines.add('In this moment, time stands still');
        lines.add('Drinking in the midnight thrill');
        lines.add('Notes that dance and intertwine');
        lines.add('Your heart\'s rhythm with mine');
        break;
      case MusicGenre.classical:
        lines.add('Harmony in perfect time');
        lines.add('A symphony so divine');
        lines.add('Movement flowing, soft and grand');
        lines.add('Together, hand in hand');
        break;
      case MusicGenre.rnb:
        lines.add('You got me feeling so complete');
        lines.add('Every time our hearts beat');
        lines.add('In this moment, here with you');
        lines.add('I\'m falling deeper, it\'s true');
        break;
    }
    
    return lines.join('\n');
  }

  String _generateBridge(String theme, String mood, MusicGenre genre) {
    final lines = <String>[];
    
    switch (genre) {
      case MusicGenre.pop:
        lines.add('And if the world should fall apart');
        lines.add('We\'ll rebuild it, heart to heart');
        break;
      case MusicGenre.rock:
        lines.add('Through the fire and the rain');
        lines.add('We\'ll dance inside the hurricane');
        break;
      case MusicGenre.hipHop:
        lines.add('They said we couldn\'t make it far');
        lines.add('Look at us, we\'re shining like a star');
        break;
      case MusicGenre.electronic:
        lines.add('Breaking through the static noise');
        lines.add('We are one, we have no choice');
        break;
      case MusicGenre.country:
        lines.add('Through the storms and sunny days');
        lines.add('We\'ll find our own sweet ways');
        break;
      case MusicGenre.jazz:
        lines.add('The tempo slows, the lights grow dim');
        lines.add('The world belongs to him and her and him');
        break;
      case MusicGenre.classical:
        lines.add('Crescendo building, reaching high');
        lines.add('Touching stars within the sky');
        break;
      case MusicGenre.rnb:
        lines.add('When the night is cold and long');
        lines.add('You\'re the fire, you\'re the song');
        break;
    }
    
    return lines.join('\n');
  }

  String suggestChordProgression({
    required String key,
    required String scale,
    required MusicGenre genre,
    required String mood,
  }) {
    final progressions = <String>[];
    
    switch (genre) {
      case MusicGenre.pop:
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        break;
      case MusicGenre.rock:
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        break;
      case MusicGenre.hipHop:
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        break;
      case MusicGenre.electronic:
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        break;
      case MusicGenre.country:
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        break;
      case MusicGenre.jazz:
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        break;
      case MusicGenre.classical:
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        break;
      case MusicGenre.rnb:
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        progressions.add('$key - $scale - $key - $scale');
        break;
    }
    
    return '🎼 Suggested Chord Progressions for $key $scale (${genre.label}):\n' + 
           progressions.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
  }

  String getCompositionTips({
    required MusicGenre genre,
    required String mood,
  }) {
    final tips = <String>[];
    
    switch (genre) {
      case MusicGenre.pop:
        tips.add('Focus on catchy, memorable melodies');
        tips.add('Keep the structure simple and clear');
        tips.add('Use repetition to reinforce the hook');
        tips.add('Build energy toward the chorus');
        break;
      case MusicGenre.rock:
        tips.add('Emphasize strong rhythm and dynamics');
        tips.add('Use power chords for impact');
        tips.add('Create contrast between verse and chorus');
        tips.add('Don\'t be afraid to get loud');
        break;
      case MusicGenre.hipHop:
        tips.add('Focus on the beat and flow');
        tips.add('Use internal rhymes for complexity');
        tips.add('Keep the rhythm consistent');
        tips.add('Layer vocals for texture');
        break;
      case MusicGenre.electronic:
        tips.add('Build tension through layering');
        tips.add('Use automation for movement');
        tips.add('Focus on the bass and drums');
        tips.add('Create space with strategic silence');
        break;
      case MusicGenre.country:
        tips.add('Tell a story with your lyrics');
        tips.add('Use acoustic instruments authentically');
        tips.add('Keep the emotion genuine');
        tips.add('Focus on the vocal performance');
        break;
      case MusicGenre.jazz:
        tips.add('Embrace improvisation');
        tips.add('Use complex harmonies');
        tips.add('Focus on rhythm and swing');
        tips.add('Leave space for expression');
        break;
      case MusicGenre.classical:
        tips.add('Develop themes thoroughly');
        tips.add('Use counterpoint for complexity');
        tips.add('Focus on dynamics and phrasing');
        tips.add('Respect the form');
        break;
      case MusicGenre.rnb:
        tips.add('Focus on smooth, flowing melodies');
        tips.add('Use syncopation for groove');
        tips.add('Layer harmonies for richness');
        tips.add('Emphasize the vocal performance');
        break;
    }
    
    return '💡 Composition Tips for ${genre.label} ($mood):\n' + tips.map((t) => '• $t').join('\n');
  }

  String getMusicInsights() {
    if (_projects.isEmpty) {
      return 'No music projects started yet. Begin composing!';
    }
    
    final inProgress = _projects.where((p) => p.status == ProjectStatus.inProgress).length;
    const completed = 0; // Would calculate from completed projects
    
    final byGenre = <MusicGenre, int>{};
    for (final project in _projects) {
      byGenre[project.genre] = (byGenre[project.genre] ?? 0) + 1;
    }
    
    final buffer = StringBuffer();
    buffer.writeln('🎵 Music Composition Insights:');
    buffer.writeln('• Total Projects: $_totalProjects');
    buffer.writeln('• In Progress: $inProgress');
    buffer.writeln('• Total Tracks: $_totalTracks');
    buffer.writeln('');
    buffer.writeln('Projects by Genre:');
    for (final entry in byGenre.entries) {
      buffer.writeln('  • ${entry.key.label}: ${entry.value}');
    }
    
    return buffer.toString();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'projects': _projects.take(20).map((p) => p.toJson()).toList(),
        'tracks': _tracks.take(100).map((t) => t.toJson()).toList(),
        'totalProjects': _totalProjects,
        'totalTracks': _totalTracks,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[MusicComposition] Save error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _projects.clear();
        _projects.addAll(
          (data['projects'] as List<dynamic>)
              .map((p) => MusicProject.fromJson(p as Map<String, dynamic>))
        );
        
        _tracks.clear();
        _tracks.addAll(
          (data['tracks'] as List<dynamic>)
              .map((t) => Track.fromJson(t as Map<String, dynamic>))
        );
        
        _totalProjects = data['totalProjects'] as int;
        _totalTracks = data['totalTracks'] as int;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[MusicComposition] Load error: $e');
    }
  }
}

class MusicProject {
  final String id;
  final String title;
  final MusicGenre genre;
  final String description;
  final ProjectType type;
  final String mood;
  final int targetTracks;
  ProjectStatus status;
  final List<String> tracks;
  final String key;
  final int bpm;
  final String scale;
  final String lyrics;
  final String melody;
  final String chordProgression;
  final List<String> instruments;
  final DateTime createdAt;

  MusicProject({
    required this.id,
    required this.title,
    required this.genre,
    required this.description,
    required this.type,
    required this.mood,
    required this.targetTracks,
    required this.status,
    required this.tracks,
    required this.key,
    required this.bpm,
    required this.scale,
    required this.lyrics,
    required this.melody,
    required this.chordProgression,
    required this.instruments,
    required this.createdAt,
  });

  MusicProject copyWith({
    ProjectStatus? status,
    List<String>? tracks,
    String? key,
    String? scale,
    int? bpm,
    List<String>? instruments,
  }) {
    return MusicProject(
      id: id,
      title: title,
      genre: genre,
      description: description,
      type: type,
      mood: mood,
      targetTracks: targetTracks,
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      key: key ?? this.key,
      bpm: bpm ?? this.bpm,
      scale: scale ?? this.scale,
      lyrics: lyrics,
      melody: melody,
      chordProgression: chordProgression,
      instruments: instruments ?? this.instruments,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'genre': genre.name,
    'description': description,
    'type': type.name,
    'mood': mood,
    'targetTracks': targetTracks,
    'status': status.name,
    'tracks': tracks,
    'key': key,
    'bpm': bpm,
    'scale': scale,
    'lyrics': lyrics,
    'melody': melody,
    'chordProgression': chordProgression,
    'instruments': instruments,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MusicProject.fromJson(Map<String, dynamic> json) => MusicProject(
    id: json['id'],
    title: json['title'],
    genre: MusicGenre.values.firstWhere(
      (e) => e.name == json['genre'],
      orElse: () => MusicGenre.pop,
    ),
    description: json['description'],
    type: ProjectType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ProjectType.single,
    ),
    mood: json['mood'],
    targetTracks: json['targetTracks'],
    status: ProjectStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ProjectStatus.planning,
    ),
    tracks: List<String>.from(json['tracks'] ?? []),
    key: json['key'] ?? 'C',
    bpm: json['bpm'] ?? 120,
    scale: json['scale'] ?? 'Major',
    lyrics: json['lyrics'] ?? '',
    melody: json['melody'] ?? '',
    chordProgression: json['chordProgression'] ?? '',
    instruments: List<String>.from(json['instruments'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class Track {
  final String id;
  final String projectId;
  final String title;
  final TrackType type;
  final String content;
  final String? lyrics;
  final String? melody;
  final String? chordProgression;
  final List<String> instruments;
  final int duration; // in seconds
  TrackStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Track({
    required this.id,
    required this.projectId,
    required this.title,
    required this.type,
    required this.content,
    this.lyrics,
    this.melody,
    this.chordProgression,
    required this.instruments,
    required this.duration,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Track copyWith({
    String? content,
    String? lyrics,
    String? melody,
    String? chordProgression,
    List<String>? instruments,
    TrackStatus? status,
    DateTime? updatedAt,
  }) {
    return Track(
      id: id,
      projectId: projectId,
      title: title,
      type: type,
      content: content ?? this.content,
      lyrics: lyrics ?? this.lyrics,
      melody: melody ?? this.melody,
      chordProgression: chordProgression ?? this.chordProgression,
      instruments: instruments ?? this.instruments,
      duration: duration,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'title': title,
    'type': type.name,
    'content': content,
    'lyrics': lyrics,
    'melody': melody,
    'chordProgression': chordProgression,
    'instruments': instruments,
    'duration': duration,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    projectId: json['projectId'],
    title: json['title'],
    type: TrackType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TrackType.melody,
    ),
    content: json['content'],
    lyrics: json['lyrics'],
    melody: json['melody'],
    chordProgression: json['chordProgression'],
    instruments: List<String>.from(json['instruments'] ?? []),
    duration: json['duration'],
    status: TrackStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TrackStatus.draft,
    ),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

enum MusicGenre {
  pop('Pop'),
  rock('Rock'),
  hipHop('Hip Hop'),
  electronic('Electronic'),
  country('Country'),
  jazz('Jazz'),
  classical('Classical'),
  rnb('R&B');
  
  final String label;
  const MusicGenre(this.label);
}

enum ProjectType { album, ep, single, soundtrack }
enum ProjectStatus { planning, inProgress, completed, onHold }
enum TrackType { melody, lyrics, chord, full, instrumental }
enum TrackStatus { draft, revised, finalized, mastered }