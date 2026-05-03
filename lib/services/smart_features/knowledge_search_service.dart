import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/utils/api_call.dart';

class KnowledgeSearchService {
  KnowledgeSearchService._();
  static final KnowledgeSearchService instance = KnowledgeSearchService._();

  static const String _indexKey = 'knowledge_search_index_v1';
  static const String _recentSearchesKey = 'knowledge_recent_searches_v1';
  static const int _maxRecentSearches = 10;
  static const int _maxIndexEntries = 5000;

  Future<void> indexContent({
    required String source,
    required String content,
    required String title,
    required DateTime createdAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_indexKey);
      List<Map<String, dynamic>> index = [];

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        index = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      index.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'source': source,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'indexedAt': DateTime.now().toIso8601String(),
      });

      if (index.length > _maxIndexEntries) {
        index = index.sublist(0, _maxIndexEntries);
      }

      await prefs.setString(_indexKey, jsonEncode(index));
      if (kDebugMode) debugPrint('[KnowledgeSearch] Indexed: $title from $source');
    } catch (e) {
      if (kDebugMode) debugPrint('[KnowledgeSearch] Index error: $e');
    }
  }

  Future<List<KnowledgeSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_indexKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List;
      final index = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final keywords = query.toLowerCase().split(RegExp(r'\s+')).where((k) => k.length > 2).toList();
      final keywordResults = <KnowledgeSearchResult>[];

      for (final entry in index) {
        final content = (entry['content'] as String).toLowerCase();
        final title = (entry['title'] as String).toLowerCase();
        final matchedKeywords = <String>[];

        for (final keyword in keywords) {
          if (content.contains(keyword) || title.contains(keyword)) {
            matchedKeywords.add(keyword);
          }
        }

        if (matchedKeywords.isNotEmpty) {
          final score = _calculateKeywordScore(matchedKeywords.length, keywords.length, content, title, query);
          keywordResults.add(KnowledgeSearchResult(
            source: entry['source'] as String,
            title: entry['title'] as String,
            content: entry['content'] as String,
            score: score,
            matchedKeywords: matchedKeywords,
            summary: _generateSnippet(entry['content'] as String, matchedKeywords),
          ));
        }
      }

      keywordResults.sort((a, b) => b.score.compareTo(a.score));

      final aiResults = await _performAISearch(query, index);
      final combined = <KnowledgeSearchResult>[...keywordResults];

      for (final aiResult in aiResults) {
        if (!combined.any((r) => r.title == aiResult.title && r.source == aiResult.source)) {
          combined.add(aiResult);
        }
      }

      combined.sort((a, b) => b.score.compareTo(a.score));
      await _saveRecentSearch(query);

      return combined.take(50).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[KnowledgeSearch] Search error: $e');
      return [];
    }
  }

  double _calculateKeywordScore(
    int matchedCount,
    int totalKeywords,
    String content,
    String title,
    String query,
  ) {
    double score = matchedCount / totalKeywords * 0.6;
    final titleMatches = query.toLowerCase().split(RegExp(r'\s+')).where((k) => k.length > 2 && title.contains(k)).length;
    score += (titleMatches / totalKeywords) * 0.3;
    if (content.contains(query.toLowerCase())) {
      score += 0.1;
    }
    return score.clamp(0.0, 1.0);
  }

  String _generateSnippet(String content, List<String> keywords) {
    if (content.isEmpty) return '';
    final lowerContent = content.toLowerCase();
    int bestPos = 0;

    for (final keyword in keywords) {
      final pos = lowerContent.indexOf(keyword);
      if (pos != -1) {
        bestPos = pos;
        break;
      }
    }

    final start = (bestPos - 50).clamp(0, content.length);
    final end = (bestPos + 150).clamp(0, content.length);
    var snippet = content.substring(start, end);

    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';

    return snippet;
  }

  Future<List<KnowledgeSearchResult>> _performAISearch(
    String query,
    List<Map<String, dynamic>> index,
  ) async {
    try {
      final sources = index.map((e) => '${e['title']} (${e['source']})').take(20).join('\n');

      final prompt = '''You are Zero Two, a smart knowledge search assistant.
Given the search query and available content sources, identify which sources are most relevant.
Return ONLY a JSON array of objects with: title, source, relevance_score (0.0 to 1.0), summary.
Do not include any text outside the JSON array.

Query: $query

Available sources:
$sources

Return format: [{"title": "...", "source": "...", "relevance_score": 0.8, "summary": "..."}]''';

      final response = await ApiService().sendConversation([
        {'role': 'user', 'content': prompt},
      ]);

      final cleaned = response.trim();
      final jsonStart = cleaned.indexOf('[');
      final jsonEnd = cleaned.lastIndexOf(']');

      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = cleaned.substring(jsonStart, jsonEnd + 1);
        final decoded = jsonDecode(jsonStr) as List;
        final results = <KnowledgeSearchResult>[];

        for (final item in decoded) {
          final map = item as Map<String, dynamic>;
          final matchedEntry = index.firstWhere(
            (e) => e['title'] == map['title'] && e['source'] == map['source'],
            orElse: () => <String, dynamic>{},
          );

          if (matchedEntry.isNotEmpty) {
            results.add(KnowledgeSearchResult(
              source: map['source'] as String? ?? '',
              title: map['title'] as String? ?? '',
              content: matchedEntry['content'] as String? ?? '',
              score: (map['relevance_score'] as num?)?.toDouble() ?? 0.5,
              matchedKeywords: [],
              summary: map['summary'] as String? ?? '',
            ));
          }
        }

        return results;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[KnowledgeSearch] AI search error: $e');
    }

    return [];
  }

  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recentSearchesKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => e as String).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[KnowledgeSearch] Recent searches error: $e');
      return [];
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recentSearchesKey);
      List<String> recent = [];

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        recent = decoded.map((e) => e as String).toList();
      }

      recent.remove(query);
      recent.insert(0, query);

      if (recent.length > _maxRecentSearches) {
        recent = recent.sublist(0, _maxRecentSearches);
      }

      await prefs.setString(_recentSearchesKey, jsonEncode(recent));
    } catch (e) {
      if (kDebugMode) debugPrint('[KnowledgeSearch] Save recent error: $e');
    }
  }

  Future<void> clearIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_indexKey);
      if (kDebugMode) debugPrint('[KnowledgeSearch] Index cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('[KnowledgeSearch] Clear error: $e');
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_indexKey);
      if (raw == null || raw.isEmpty) {
        return {'total': 0, 'sources': <String, int>{}};
      }

      final decoded = jsonDecode(raw) as List;
      final index = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final sources = <String, int>{};

      for (final entry in index) {
        final source = entry['source'] as String? ?? 'unknown';
        sources[source] = (sources[source] ?? 0) + 1;
      }

      return {'total': index.length, 'sources': sources};
    } catch (e) {
      if (kDebugMode) debugPrint('[KnowledgeSearch] Stats error: $e');
      return {'total': 0, 'sources': <String, int>{}};
    }
  }

  Future<List<KnowledgeSearchResult>> getAllEntries({String? filterSource}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_indexKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List;
      final index = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final filtered = filterSource != null && filterSource != 'All'
          ? index.where((e) => e['source'] == filterSource).toList()
          : index;

      return filtered.map((e) => KnowledgeSearchResult(
        source: e['source'] as String,
        title: e['title'] as String,
        content: e['content'] as String,
        score: 1.0,
        matchedKeywords: [],
        summary: _generateSnippet(e['content'] as String, []),
      )).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[KnowledgeSearch] Get all error: $e');
      return [];
    }
  }
}

class KnowledgeSearchResult {
  final String source;
  final String title;
  final String content;
  final double score;
  final List<String> matchedKeywords;
  final String summary;

  const KnowledgeSearchResult({
    required this.source,
    required this.title,
    required this.content,
    required this.score,
    required this.matchedKeywords,
    required this.summary,
  });
}
