import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📚 Academic Research Assistant Service
///
/// Help with literature reviews, citation management, and study planning.
class AcademicResearchService {
  AcademicResearchService._();
  static final AcademicResearchService instance = AcademicResearchService._();

  final List<ResearchProject> _projects = [];
  final List<LiteratureSource> _sources = [];
  final List<StudySession> _studySessions = [];

  int _totalProjects = 0;
  int _totalSources = 0;
  int _totalStudyHours = 0;

  static const String _storageKey = 'academic_research_v1';
  static const int _maxSources = 500;

  Future<void> initialize() async {
    await _loadData();
    if (kDebugMode)
      debugPrint(
          '[AcademicResearch] Initialized with $_totalProjects projects');
  }

  Future<ResearchProject> createResearchProject({
    required String title,
    required String topic,
    required String description,
    required DateTime deadline,
    required ResearchLevel level,
  }) async {
    final project = ResearchProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      topic: topic,
      description: description,
      deadline: deadline,
      level: level,
      status: ResearchStatus.planning,
      sources: [],
      citations: [],
      createdAt: DateTime.now(),
    );

    _projects.add(project);
    _totalProjects++;

    await _saveData();

    if (kDebugMode) debugPrint('[AcademicResearch] Created project: $title');
    return project;
  }

  Future<LiteratureSource> addSource({
    required String projectId,
    required String title,
    required String author,
    required String publicationYear,
    required SourceType type,
    required String urlOrDoi,
    String? abstract,
    String? notes,
    int? relevanceScore,
  }) async {
    final source = LiteratureSource(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      title: title,
      author: author,
      publicationYear: publicationYear,
      type: type,
      urlOrDoi: urlOrDoi,
      abstract: abstract,
      notes: notes,
      relevanceScore: relevanceScore,
      addedAt: DateTime.now(),
    );

    _sources.insert(0, source);
    if (_sources.length > _maxSources) {
      _sources.removeLast();
    }
    _totalSources++;

    // Add to project
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex != -1) {
      final project = _projects[projectIndex];
      _projects[projectIndex] = project.copyWith(
        sources: [...project.sources, source.id],
      );
    }

    await _saveData();

    if (kDebugMode) debugPrint('[AcademicResearch] Added source: $title');
    return source;
  }

  Future<void> addCitation({
    required String projectId,
    required String sourceId,
    required String citationText,
    required CitationStyle style,
    required String context,
  }) async {
    final citation = Citation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceId: sourceId,
      citationText: citationText,
      style: style,
      context: context,
      addedAt: DateTime.now(),
    );

    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex != -1) {
      final project = _projects[projectIndex];
      _projects[projectIndex] = project.copyWith(
        citations: [...project.citations, citation],
      );
    }

    await _saveData();
  }

  Future<void> startStudySession({
    required String projectId,
    required String focusArea,
    required int plannedDurationMinutes,
  }) async {
    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      focusArea: focusArea,
      plannedDurationMinutes: plannedDurationMinutes,
      actualDurationMinutes: 0,
      status: StudySessionStatus.inProgress,
      startTime: DateTime.now(),
      endTime: null,
      notes: '',
    );

    _studySessions.insert(0, session);

    await _saveData();

    if (kDebugMode)
      debugPrint('[AcademicResearch] Started study session: $focusArea');
  }

  Future<void> endStudySession({
    required String sessionId,
    required int actualDurationMinutes,
    required String notes,
  }) async {
    final sessionIndex = _studySessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final session = _studySessions[sessionIndex];
    _studySessions[sessionIndex] = session.copyWith(
      actualDurationMinutes: actualDurationMinutes,
      status: StudySessionStatus.completed,
      endTime: DateTime.now(),
      notes: notes,
    );

    _totalStudyHours += actualDurationMinutes;

    await _saveData();

    if (kDebugMode)
      debugPrint(
          '[AcademicResearch] Completed study session: ${actualDurationMinutes}min');
  }

  Future<void> updateProjectStatus(
      String projectId, ResearchStatus status) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final project = _projects[projectIndex];
    _projects[projectIndex] = project.copyWith(status: status);

    await _saveData();
  }

  String getLiteratureReview(String projectId) {
    final projectSources =
        _sources.where((s) => s.projectId == projectId).toList();

    if (projectSources.isEmpty) {
      return 'No sources added to this project yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln('📚 Literature Review for "${_getProjectTitle(projectId)}"');
    buffer.writeln('');
    buffer.writeln('Total Sources: ${projectSources.length}');
    buffer.writeln('');

    // Group by type
    final byType = <SourceType, List<LiteratureSource>>{};
    for (final source in projectSources) {
      byType.putIfAbsent(source.type, () => []).add(source);
    }

    for (final entry in byType.entries) {
      buffer.writeln('${entry.key.label}: ${entry.value.length}');
      for (final source in entry.value.take(5)) {
        buffer.writeln(
            '  • ${source.author} (${source.publicationYear}): ${source.title}');
      }
      if (entry.value.length > 5) {
        buffer.writeln('  ... and ${entry.value.length - 5} more');
      }
      buffer.writeln('');
    }

    // Top relevant sources
    final topSources = projectSources
        .where((s) => s.relevanceScore != null)
        .toList()
      ..sort(
          (a, b) => (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));

    if (topSources.isNotEmpty) {
      buffer.writeln('🎯 Top Relevant Sources:');
      for (final source in topSources.take(3)) {
        buffer.writeln('  ${source.relevanceScore}/10 - ${source.title}');
      }
    }

    return buffer.toString();
  }

  String getCitationBibliography(String projectId, CitationStyle style) {
    final projectSources =
        _sources.where((s) => s.projectId == projectId).toList();

    final buffer = StringBuffer();
    buffer.writeln('📄 Bibliography (${style.name})');
    buffer.writeln('');

    for (final source in projectSources) {
      buffer.writeln(_formatCitation(source, style));
    }

    return buffer.toString();
  }

  String _formatCitation(LiteratureSource source, CitationStyle style) {
    switch (style) {
      case CitationStyle.apa:
        return '${source.author} (${source.publicationYear}). ${source.title}. ${source.urlOrDoi}';
      case CitationStyle.mla:
        return '${source.author}. "${source.title}." ${source.publicationYear}. ${source.urlOrDoi}';
      case CitationStyle.chicago:
        return '${source.author}. ${source.publicationYear}. "${source.title}." ${source.urlOrDoi}';
      case CitationStyle.harvard:
        return '${source.author}, ${source.publicationYear}, ${source.title}, ${source.urlOrDoi}';
    }
  }

  String getStudyAnalytics() {
    if (_studySessions.isEmpty) {
      return 'No study sessions recorded yet.';
    }

    final completedSessions = _studySessions
        .where((s) => s.status == StudySessionStatus.completed)
        .toList();
    final totalMinutes = completedSessions.fold<int>(
        0, (sum, s) => sum + s.actualDurationMinutes);
    final avgDuration = completedSessions.isNotEmpty
        ? totalMinutes / completedSessions.length
        : 0;

    final byProject = <String, int>{};
    for (final session in completedSessions) {
      byProject[session.projectId] =
          (byProject[session.projectId] ?? 0) + session.actualDurationMinutes;
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 Study Analytics');
    buffer.writeln('');
    buffer.writeln('Total Sessions: ${completedSessions.length}');
    buffer.writeln(
        'Total Study Time: ${totalMinutes ~/ 60}h ${totalMinutes % 60}m');
    buffer
        .writeln('Average Session: ${avgDuration.toStringAsFixed(0)} minutes');
    buffer.writeln('');
    buffer.writeln('Time by Project:');
    for (final entry in byProject.entries) {
      final title = _getProjectTitle(entry.key);
      buffer.writeln('  • $title: ${entry.value ~/ 60}h ${entry.value % 60}m');
    }

    return buffer.toString();
  }

  String getResearchRecommendations(String projectId) {
    final projectSources =
        _sources.where((s) => s.projectId == projectId).toList();
    final project = _projects.firstWhere((p) => p.id == projectId);

    final recommendations = <String>[];

    if (projectSources.length < 5) {
      recommendations.add(
          'Add more sources to strengthen your literature review (aim for 10+)');
    }

    final recentSources = projectSources.where((s) {
      final year = int.tryParse(s.publicationYear) ?? 0;
      return year >= DateTime.now().year - 5;
    }).length;

    if (recentSources < 3) {
      recommendations.add(
          'Include more recent sources (last 5 years) for current perspectives');
    }

    final hasPrimary = projectSources.any((s) =>
        s.type == SourceType.journalArticle ||
        s.type == SourceType.conferencePaper);
    if (!hasPrimary) {
      recommendations.add(
          'Include primary research sources (journal articles, conference papers)');
    }

    if (project.citations.isEmpty) {
      recommendations.add('Start adding citations to your draft');
    }

    if (recommendations.isEmpty) {
      recommendations
          .add('Great progress! Your research project looks well-developed.');
    }

    return '📋 Research Recommendations:\n' +
        recommendations.map((r) => '• $r').join('\n');
  }

  String _getProjectTitle(String projectId) {
    return _projects
        .firstWhere((p) => p.id == projectId,
            orElse: () => ResearchProject(
                  id: '',
                  title: 'Unknown',
                  topic: '',
                  description: '',
                  deadline: DateTime.now(),
                  level: ResearchLevel.undergraduate,
                  status: ResearchStatus.planning,
                  sources: [],
                  citations: [],
                  createdAt: DateTime.now(),
                ))
        .title;
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'projects': _projects.map((p) => p.toJson()).toList(),
        'sources': _sources.take(100).map((s) => s.toJson()).toList(),
        'studySessions':
            _studySessions.take(100).map((s) => s.toJson()).toList(),
        'totalProjects': _totalProjects,
        'totalSources': _totalSources,
        'totalStudyHours': _totalStudyHours,
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicResearch] Save error: $e');
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
            .map((p) => ResearchProject.fromJson(p as Map<String, dynamic>)));

        _sources.clear();
        _sources.addAll((data['sources'] as List<dynamic>)
            .map((s) => LiteratureSource.fromJson(s as Map<String, dynamic>)));

        _studySessions.clear();
        _studySessions.addAll((data['studySessions'] as List<dynamic>)
            .map((s) => StudySession.fromJson(s as Map<String, dynamic>)));

        _totalProjects = data['totalProjects'] as int;
        _totalSources = data['totalSources'] as int;
        _totalStudyHours = data['totalStudyHours'] as int;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AcademicResearch] Load error: $e');
    }
  }
}

class ResearchProject {
  final String id;
  final String title;
  final String topic;
  final String description;
  final DateTime deadline;
  final ResearchLevel level;
  final ResearchStatus status;
  final List<String> sources;
  final List<Citation> citations;
  final DateTime createdAt;

  ResearchProject({
    required this.id,
    required this.title,
    required this.topic,
    required this.description,
    required this.deadline,
    required this.level,
    required this.status,
    required this.sources,
    required this.citations,
    required this.createdAt,
  });

  ResearchProject copyWith({
    String? title,
    String? topic,
    String? description,
    DateTime? deadline,
    ResearchLevel? level,
    ResearchStatus? status,
    List<String>? sources,
    List<Citation>? citations,
  }) {
    return ResearchProject(
      id: id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      level: level ?? this.level,
      status: status ?? this.status,
      sources: sources ?? this.sources,
      citations: citations ?? this.citations,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'description': description,
        'deadline': deadline.toIso8601String(),
        'level': level.name,
        'status': status.name,
        'sources': sources,
        'citations': citations.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ResearchProject.fromJson(Map<String, dynamic> json) =>
      ResearchProject(
        id: json['id'],
        title: json['title'],
        topic: json['topic'],
        description: json['description'],
        deadline: DateTime.parse(json['deadline']),
        level: ResearchLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => ResearchLevel.undergraduate,
        ),
        status: ResearchStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ResearchStatus.planning,
        ),
        sources: List<String>.from(json['sources'] ?? []),
        citations: (json['citations'] as List<dynamic>)
            .map((c) => Citation.fromJson(c as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class LiteratureSource {
  final String id;
  final String projectId;
  final String title;
  final String author;
  final String publicationYear;
  final SourceType type;
  final String urlOrDoi;
  final String? abstract;
  final String? notes;
  final int? relevanceScore;
  final DateTime addedAt;

  LiteratureSource({
    required this.id,
    required this.projectId,
    required this.title,
    required this.author,
    required this.publicationYear,
    required this.type,
    required this.urlOrDoi,
    this.abstract,
    this.notes,
    this.relevanceScore,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'author': author,
        'publicationYear': publicationYear,
        'type': type.name,
        'urlOrDoi': urlOrDoi,
        'abstract': abstract,
        'notes': notes,
        'relevanceScore': relevanceScore,
        'addedAt': addedAt.toIso8601String(),
      };

  factory LiteratureSource.fromJson(Map<String, dynamic> json) =>
      LiteratureSource(
        id: json['id'],
        projectId: json['projectId'],
        title: json['title'],
        author: json['author'],
        publicationYear: json['publicationYear'],
        type: SourceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SourceType.other,
        ),
        urlOrDoi: json['urlOrDoi'],
        abstract: json['abstract'],
        notes: json['notes'],
        relevanceScore: json['relevanceScore'],
        addedAt: DateTime.parse(json['addedAt']),
      );
}

class Citation {
  final String id;
  final String sourceId;
  final String citationText;
  final CitationStyle style;
  final String context;
  final DateTime addedAt;

  Citation({
    required this.id,
    required this.sourceId,
    required this.citationText,
    required this.style,
    required this.context,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'citationText': citationText,
        'style': style.name,
        'context': context,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
        id: json['id'],
        sourceId: json['sourceId'],
        citationText: json['citationText'],
        style: CitationStyle.values.firstWhere(
          (e) => e.name == json['style'],
          orElse: () => CitationStyle.apa,
        ),
        context: json['context'],
        addedAt: DateTime.parse(json['addedAt']),
      );
}

class StudySession {
  final String id;
  final String projectId;
  final String focusArea;
  final int plannedDurationMinutes;
  final int actualDurationMinutes;
  final StudySessionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String notes;

  StudySession({
    required this.id,
    required this.projectId,
    required this.focusArea,
    required this.plannedDurationMinutes,
    required this.actualDurationMinutes,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.notes,
  });

  StudySession copyWith({
    int? actualDurationMinutes,
    StudySessionStatus? status,
    DateTime? endTime,
    String? notes,
  }) {
    return StudySession(
      id: id,
      projectId: projectId,
      focusArea: focusArea,
      plannedDurationMinutes: plannedDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'focusArea': focusArea,
        'plannedDurationMinutes': plannedDurationMinutes,
        'actualDurationMinutes': actualDurationMinutes,
        'status': status.name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'notes': notes,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'],
        projectId: json['projectId'],
        focusArea: json['focusArea'],
        plannedDurationMinutes: json['plannedDurationMinutes'],
        actualDurationMinutes: json['actualDurationMinutes'],
        status: StudySessionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => StudySessionStatus.inProgress,
        ),
        startTime: DateTime.parse(json['startTime']),
        endTime:
            json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        notes: json['notes'],
      );
}

enum ResearchLevel { undergraduate, masters, doctoral, postdoc }

enum ResearchStatus { planning, inProgress, review, completed, published }

enum SourceType {
  journalArticle('Journal Article'),
  conferencePaper('Conference Paper'),
  book('Book'),
  bookChapter('Book Chapter'),
  thesis('Thesis/Dissertation'),
  report('Technical Report'),
  website('Website'),
  other('Other');

  final String label;
  const SourceType(this.label);
}

enum CitationStyle { apa, mla, chicago, harvard }

enum StudySessionStatus { inProgress, completed, cancelled }
