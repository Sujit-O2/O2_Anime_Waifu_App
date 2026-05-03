import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anime_waifu/models/manga_models.dart';
import 'package:anime_waifu/services/manga_providers/manga_provider.dart';

/// ComicK.io — Free public API. Strong on manhwa, manhua & manga.
/// ComicK.io — Free public API. Strong on manhwa, manhua & manga.
/// API Docs: https://api.comick.app
class ComickProvider implements MangaProvider {
  static const String _base = 'https://api.comick.app';

  @override
  String get name => 'ComicK';

  @override
  Future<List<MangaItem>> searchManga(String title, {int limit = 24}) async {
    try {
      final q = Uri.encodeQueryComponent(title);
      final uri = Uri.parse('$_base/v1.0/search?q=$q&limit=$limit&page=1');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(resp.body);
      return data.map((e) => _fromComick(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MangaItem>> getTrending({int limit = 24, int offset = 0}) async {
    try {
      final page = (offset ~/ limit) + 1;
      final uri = Uri.parse('$_base/v1.0/search?sort=follow&limit=$limit&page=$page');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(resp.body);
      return data.map((e) => _fromComick(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MangaItem>> getByTag(String tagId, {int limit = 24, int offset = 0}) async {
    try {
      final page = (offset ~/ limit) + 1;
      final uri = Uri.parse('$_base/v1.0/search?genres=$tagId&sort=follow&limit=$limit&page=$page');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(resp.body);
      return data.map((e) => _fromComick(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ChapterItem>> getChapters(String mangaId,
      {String lang = 'en', int limit = 100, int offset = 0}) async {
    try {
      // mangaId for ComicK is the hid (slug)
      final uri = Uri.parse('$_base/comic/$mangaId/chapters').replace(queryParameters: {
        'lang': lang,
        'limit': limit.toString(),
        'page': (offset ~/ limit + 1).toString(),
      });
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final chapters = json['chapters'] as List<dynamic>? ?? [];
      return chapters.map((e) {
        final c = e as Map<String, dynamic>;
        final num = c['chap']?.toString();
        final vol = c['vol']?.toString();
        return ChapterItem(
          id: c['hid'] as String? ?? c['id'].toString(),
          chapter: num,
          volume: vol,
          title: c['title'] as String?,
          publishedAt: c['created_at'] as String?,
          pageCount: c['group_reclass'] != null ? 0 : 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ChapterPages?> getChapterPages(String chapterId,
      {bool dataSaver = false}) async {
    try {
      final uri = Uri.parse('$_base/chapter/$chapterId');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final chapter = json['chapter'] as Map<String, dynamic>? ?? {};
      final images = chapter['images'] as List<dynamic>? ?? [];
      final pageUrls = images
          .map((img) => (img as Map<String, dynamic>)['url'] as String?)
          .where((u) => u != null)
          .cast<String>()
          .toList();
      return ChapterPages(chapterId: chapterId, pageUrls: pageUrls);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TagItem>> getTags() async {
    // ComicK genre list (hardcoded for speed — no network roundtrip)
    return [
      const TagItem(id: '1',  name: 'Action',    group: 'genre'),
      const TagItem(id: '2',  name: 'Adventure',  group: 'genre'),
      const TagItem(id: '3',  name: 'Comedy',     group: 'genre'),
      const TagItem(id: '6',  name: 'Drama',      group: 'genre'),
      const TagItem(id: '7',  name: 'Fantasy',    group: 'genre'),
      const TagItem(id: '8',  name: 'Harem',      group: 'genre'),
      const TagItem(id: '9',  name: 'Historical', group: 'genre'),
      const TagItem(id: '10', name: 'Horror',     group: 'genre'),
      const TagItem(id: '14', name: 'Mystery',    group: 'genre'),
      const TagItem(id: '17', name: 'Romance',    group: 'genre'),
      const TagItem(id: '22', name: 'School',     group: 'genre'),
      const TagItem(id: '30', name: 'Sci-Fi',     group: 'genre'),
      const TagItem(id: '34', name: 'Slice of Life', group: 'genre'),
      const TagItem(id: '37', name: 'Sports',     group: 'genre'),
      const TagItem(id: '38', name: 'Supernatural', group: 'genre'),
      const TagItem(id: '46', name: 'Ecchi',      group: 'genre'),
      const TagItem(id: '47', name: 'Adult',      group: 'genre'),
    ];
  }

  Map<String, String> get _headers => {
        'User-Agent': 'AnimeWaifuApp/3.0',
        'Accept': 'application/json',
      };

  MangaItem _fromComick(Map<String, dynamic> e) {
    final slug = e['slug'] as String? ?? e['hid'] as String? ?? e['id']?.toString() ?? '';
    final title = e['title'] as String? ??
        ((e['md_titles'] as List?)?.firstOrNull as Map?)?['title'] as String? ?? '';
    // Build cover URL safely
    String? cover = e['cover_url'] as String?;
    if (cover == null) {
      final covers = e['md_covers'] as List?;
      if (covers != null && covers.isNotEmpty) {
        final b2key = (covers.first as Map?)?['b2key'] as String?;
        if (b2key != null) cover = 'https://meo.comick.pictures/$b2key';
      }
    }
    final year = e['year'] as int?;
    final statusInt = e['status'];
    final status = statusInt == 2 ? 'completed' : statusInt == 3 ? 'cancelled' : 'ongoing';
    final contentRating = (e['hentai'] as bool? ?? false) ? 'pornographic' : 'safe';
    return MangaItem(
      id: slug,
      title: title,
      description: e['desc'] as String? ?? '',
      status: status,
      contentRating: contentRating,
      year: year,
      externalCoverUrl: (cover?.startsWith('http') == true) ? cover : null,
      tags: ((e['genres'] as List?)?.map((g) => g.toString()).toList()) ?? [],
      availableLanguages: const ['en'],
    );
  }
}



