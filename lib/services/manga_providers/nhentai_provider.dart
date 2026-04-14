import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anime_waifu/models/manga_models.dart';
import 'package:anime_waifu/services/manga_providers/manga_provider.dart';

/// NHentai Unofficial API — the most comprehensive adult doujinshi library.
/// API: https://nhentai.net/api/gallery/{id} and /galleries/search
class NhentaiProvider implements MangaProvider {
  static const String _base = 'https://nhentai.net/api';
  static const String _cdnThumb = 'https://t.nhentai.net/galleries';
  static const String _cdnImg   = 'https://i.nhentai.net/galleries';

  @override
  String get name => 'NHentai 🔞';

  Map<String, String> get _headers => {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36',
        'Accept': 'application/json',
        'Referer': 'https://nhentai.net/',
      };

  @override
  Future<List<MangaItem>> searchManga(String title, {int limit = 24}) async {
    try {
      final uri = Uri.parse('$_base/galleries/search').replace(queryParameters: {
        'query': title,
        'per_page': limit.toString(),
        'page': '1',
      });
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (json['result'] as List?) ?? [];
      return results.map((e) => _fromNH(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<List<MangaItem>> getTrending({int limit = 24}) async {
    try {
      // Popular/trending via main sorted endpoint
      final uri = Uri.parse('$_base/galleries/search').replace(queryParameters: {
        'query': '',
        'sort': 'popular-week',
        'per_page': limit.toString(),
        'page': '1',
      });
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return _fallbackPopular();
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (json['result'] as List?) ?? [];
      if (results.isEmpty) return _fallbackPopular();
      return results.map((e) => _fromNH(e as Map<String, dynamic>)).toList();
    } catch (_) { return _fallbackPopular(); }
  }

  /// Fallback: return popular by tag
  Future<List<MangaItem>> _fallbackPopular() async {
    try {
      final uri = Uri.parse('$_base/galleries/search').replace(queryParameters: {
        'query': 'language:english',
        'per_page': '24',
        'page': '1',
      });
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (json['result'] as List?) ?? [];
      return results.map((e) => _fromNH(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<List<MangaItem>> getByTag(String tagId, {int limit = 24}) async {
    try {
      final uri = Uri.parse('$_base/galleries/search').replace(queryParameters: {
        'query': tagId,
        'per_page': limit.toString(),
        'page': '1',
      });
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (json['result'] as List?) ?? [];
      return results.map((e) => _fromNH(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<List<ChapterItem>> getChapters(String mangaId,
      {String lang = 'en', int limit = 100, int offset = 0}) async {
    // NHentai doujins are single-chapter; return one chapter pointing to the gallery
    return [
      ChapterItem(
        id: mangaId, // gallery media_id
        chapter: '1',
        title: 'Full Gallery',
        publishedAt: null,
        pageCount: 0,
      )
    ];
  }

  @override
  Future<ChapterPages?> getChapterPages(String chapterId, {bool dataSaver = false}) async {
    // chapterId is the gallery id (NOT media_id)
    try {
      final uri = Uri.parse('$_base/gallery/$chapterId');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final mediaId = json['media_id']?.toString() ?? chapterId;
      final images = (json['images']?['pages'] as List?) ?? [];
      final exts = {'j': 'jpg', 'p': 'png', 'g': 'gif', 'w': 'webp'};
      final urls = images.asMap().entries.map((entry) {
        final ext = exts[(entry.value as Map<String, dynamic>)['t'] as String? ?? 'j'] ?? 'jpg';
        return '$_cdnImg/$mediaId/${entry.key + 1}.$ext';
      }).toList();
      return ChapterPages(chapterId: chapterId, pageUrls: urls);
    } catch (_) { return null; }
  }

  @override
  Future<List<TagItem>> getTags() async {
    // NHentai uses search queries as "tags" — return common search terms
    return const [
      TagItem(id: 'language:english',          name: '🇺🇸 English',      group: 'genre'),
      TagItem(id: 'language:japanese',         name: '🇯🇵 Japanese',     group: 'genre'),
      TagItem(id: 'language:korean',           name: '🇰🇷 Korean',       group: 'genre'),
      TagItem(id: 'tag:big breasts',           name: '💗 Big Breasts',   group: 'genre'),
      TagItem(id: 'tag:schoolgirl',            name: '🏫 Schoolgirl',    group: 'genre'),
      TagItem(id: 'tag:romance',               name: '💕 Romance',       group: 'genre'),
      TagItem(id: 'tag:vanilla',               name: '🍦 Vanilla',       group: 'genre'),
      TagItem(id: 'tag:sole male',             name: '🔵 Sole Male',     group: 'genre'),
      TagItem(id: 'tag:uncensored',            name: '🔓 Uncensored',    group: 'genre'),
      TagItem(id: 'tag:netorare',              name: '💔 NTR',           group: 'genre'),
      TagItem(id: 'tag:incest',               name: '🔞 Incest',        group: 'genre'),
      TagItem(id: 'tag:milf',                 name: '🔞 Milf',          group: 'genre'),
      TagItem(id: 'tag:hentai',               name: '🔞 Hentai',        group: 'genre'),
      TagItem(id: 'tag:full color',            name: '🎨 Full Color',    group: 'genre'),
      TagItem(id: 'tag:doujinshi',             name: '📕 Doujinshi',     group: 'genre'),
    ];
  }

  MangaItem _fromNH(Map<String, dynamic> e) {
    final id = e['id']?.toString() ?? '';
    final mediaId = e['media_id']?.toString() ?? id;
    // Title
    final titles = e['title'] as Map<String, dynamic>? ?? {};
    final title = titles['english'] as String? ??
        titles['pretty'] as String? ??
        titles['japanese'] as String? ?? 'Unknown';
    // Thumbnail
    final thumbExt = (e['images']?['thumbnail'] as Map?)?['t'] as String? ?? 'j';
    final extMap = {'j': 'jpg', 'p': 'png', 'g': 'gif', 'w': 'webp'};
    final cover = '$_cdnThumb/$mediaId/thumb.${extMap[thumbExt] ?? 'jpg'}';
    // Tags
    final tags = (e['tags'] as List?)
        ?.map((t) => (t as Map<String, dynamic>)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .take(5)
        .toList() ?? [];
    return MangaItem(
      id: id,
      title: title,
      description: 'Doujinshi · ${(e['num_pages'] ?? 0)} pages',
      status: 'completed',
      contentRating: 'pornographic',
      externalCoverUrl: cover,
      tags: tags,
      availableLanguages: const ['en'],
    );
  }
}


