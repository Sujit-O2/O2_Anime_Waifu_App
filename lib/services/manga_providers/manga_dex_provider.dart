import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anime_waifu/models/manga_models.dart';
import 'package:anime_waifu/services/manga_providers/manga_provider.dart';

class MangaDexProvider implements MangaProvider {
  static const String _base = 'https://api.mangadex.org';

  final List<String> _ratings = ['safe', 'suggestive', 'erotica', 'pornographic'];

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'User-Agent': 'AnimeWaifuApp/3.0',
      };

  @override
  String get name => 'MangaDex';



  // Build a full query string with repeated array params properly.
  Uri _buildUriWithArrays(String path, {
    required Map<String, String> scalar,
    required Map<String, List<String>> arrays,
  }) {
    final parts = <String>[];
    scalar.forEach((k, v) => parts.add('$k=${Uri.encodeQueryComponent(v)}'));
    arrays.forEach((k, values) {
      for (final v in values) {
        parts.add('$k[]=${Uri.encodeQueryComponent(v)}');
      }
    });
    return Uri.parse('$_base$path?${parts.join('&')}');
  }

  @override
  Future<List<MangaItem>> searchManga(String title, {int limit = 24}) async {
    final uri = _buildUriWithArrays('/manga', scalar: {
      'title': title,
      'limit': limit.toString(),
      'order[relevance]': 'desc',
    }, arrays: {
      'includes': ['cover_art'],
      'availableTranslatedLanguage': ['en'],
      'contentRating': _ratings,
    });
    return _fetchMangaList(uri);
  }

  @override
  Future<List<MangaItem>> getTrending({int limit = 24}) async {
    final uri = _buildUriWithArrays('/manga', scalar: {
      'limit': limit.toString(),
      'order[followedCount]': 'desc',
    }, arrays: {
      'includes': ['cover_art'],
      'availableTranslatedLanguage': ['en'],
      'contentRating': _ratings,
    });
    return _fetchMangaList(uri);
  }

  @override
  Future<List<MangaItem>> getByTag(String tagId, {int limit = 24}) async {
    final uri = _buildUriWithArrays('/manga', scalar: {
      'limit': limit.toString(),
      'order[followedCount]': 'desc',
    }, arrays: {
      'includes': ['cover_art'],
      'includedTags': [tagId],   // <-- the real fix: proper repeated param
      'contentRating': _ratings,
      // Removed 'availableTranslatedLanguage' restriction so ALL translations show up
    });
    return _fetchMangaList(uri);
  }

  @override
  Future<List<ChapterItem>> getChapters(String mangaId,
      {String lang = 'en', int limit = 100, int offset = 0}) async {
    try {
      final uri = _buildUriWithArrays('/manga/$mangaId/feed',
          scalar: {
            'limit': limit.toString(),
            'offset': offset.toString(),
            'order[chapter]': 'asc',
            'order[volume]': 'asc',
          },
          arrays: {
            'translatedLanguage': [lang],
          });
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => ChapterItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ChapterPages?> getChapterPages(String chapterId,
      {bool dataSaver = false}) async {
    try {
      final uri = Uri.parse('$_base/at-home/server/$chapterId');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final baseUrl = json['baseUrl'] as String;
      final chapter = json['chapter'] as Map<String, dynamic>;
      final hash = chapter['hash'] as String;
      final files = dataSaver
          ? (chapter['dataSaver'] as List<dynamic>).cast<String>()
          : (chapter['data'] as List<dynamic>).cast<String>();
      final quality = dataSaver ? 'data-saver' : 'data';
      final pageUrls = files.map((f) => '$baseUrl/$quality/$hash/$f').toList();
      return ChapterPages(chapterId: chapterId, pageUrls: pageUrls);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TagItem>> getTags() async {
    try {
      final uri = Uri.parse('$_base/manga/tag');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => TagItem.fromJson(e as Map<String, dynamic>))
          .where((t) => t.group == 'genre')
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      return [];
    }
  }

  Future<List<MangaItem>> _fetchMangaList(Uri uri) async {
    try {
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      return data.map((e) => MangaItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}


