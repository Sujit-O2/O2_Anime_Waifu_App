import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anime_waifu/models/manga_models.dart';
import 'package:anime_waifu/services/manga_providers/manga_provider.dart';

/// MangaPark v5 GraphQL API — massive raw & translated scan library.
/// GraphQL endpoint: https://mangapark.net/api/query
class MangaParkProvider implements MangaProvider {
  static const String _endpoint = 'https://mangapark.net/api/query';

  @override
  String get name => 'MangaPark';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'User-Agent': 'AnimeWaifuApp/3.0',
        'Accept': 'application/json',
        'Origin': 'https://mangapark.net',
        'Referer': 'https://mangapark.net/',
      };

  Future<dynamic> _query(String gql, Map<String, dynamic> variables) async {
    final body = jsonEncode({'query': gql, 'variables': variables});
    final resp = await http.post(Uri.parse(_endpoint),
        headers: _headers, body: body).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) return null;
    final decoded = jsonDecode(resp.body);
    return decoded['data'];
  }

  static const String _mangaFields = '''
    id
    data {
      name
      altNames
      genres
      originalStatus
      uploadStatus
      urlPath
      urlCoverOri
      urlCover600
      isHentai
      summary
    }
  ''';

  @override
  Future<List<MangaItem>> searchManga(String title, {int limit = 24}) async {
    const gql = '''
      query(\$select: SearchComic_Select) {
        searchComic(select: \$select) {
          items { $_mangaFields }
        }
      }
    ''';
    try {
      final data = await _query(gql, {
        'select': {'word': title, 'size': limit}
      });
      final items = (data?['searchComic']?['items'] as List?) ?? [];
      return items.map((e) => _fromMP(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<List<MangaItem>> getTrending({int limit = 24}) async {
    const gql = '''
      query(\$select: SearchComic_Select) {
        searchComic(select: \$select) {
          items { $_mangaFields }
        }
      }
    ''';
    try {
      final data = await _query(gql, {
        'select': {'sortby': 'field_follow_count', 'size': limit}
      });
      final items = (data?['searchComic']?['items'] as List?) ?? [];
      return items.map((e) => _fromMP(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<List<MangaItem>> getByTag(String tagId, {int limit = 24}) async {
    const gql = '''
      query(\$select: SearchComic_Select) {
        searchComic(select: \$select) {
          items { $_mangaFields }
        }
      }
    ''';
    try {
      final data = await _query(gql, {
        'select': {'genre': tagId, 'sortby': 'field_follow_count', 'size': limit}
      });
      final items = (data?['searchComic']?['items'] as List?) ?? [];
      return items.map((e) => _fromMP(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  @override
  Future<List<ChapterItem>> getChapters(String mangaId,
      {String lang = 'en', int limit = 100, int offset = 0}) async {
    const gql = '''
      query(\$comicId: ID!, \$select: ChapterList_Select) {
        chapterList(comicId: \$comicId, select: \$select) {
          items {
            id
            data { dname urlPath dateCreate }
          }
        }
      }
    ''';
    try {
      final data = await _query(gql, {
        'comicId': mangaId,
        'select': {'limit': limit, 'skip': offset}
      });
      final items = (data?['chapterList']?['items'] as List?) ?? [];
      return items.map((e) {
        final d = (e as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
        final name = d['dname'] as String? ?? '';
        final chMatch = RegExp(r'[\d.]+').firstMatch(name);
        return ChapterItem(
          id: e['id']?.toString() ?? '',
          chapter: chMatch?.group(0),
          title: name,
          publishedAt: d['dateCreate']?.toString(),
          pageCount: 0,
        );
      }).toList();
    } catch (_) { return []; }
  }

  @override
  Future<ChapterPages?> getChapterPages(String chapterId,
      {bool dataSaver = false}) async {
    const gql = '''
      query(\$chapterId: ID!) {
        chapterPages(chapterId: \$chapterId) {
          data {
            imageFile { urlList }
          }
        }
      }
    ''';
    try {
      final data = await _query(gql, {'chapterId': chapterId});
      final pages = (data?['chapterPages']?['data'] as List?) ?? [];
      final urls = pages
          .expand((p) => (p as Map<String, dynamic>)['imageFile']['urlList'] as List? ?? [])
          .map((u) => u.toString())
          .toList();
      return ChapterPages(chapterId: chapterId, pageUrls: urls);
    } catch (_) { return null; }
  }

  @override
  Future<List<TagItem>> getTags() async {
    // MangaPark genre strings (used directly as 'genre' filter in queries)
    return const [
      TagItem(id: 'Action',       name: 'Action',       group: 'genre'),
      TagItem(id: 'Adventure',    name: 'Adventure',    group: 'genre'),
      TagItem(id: 'Comedy',       name: 'Comedy',       group: 'genre'),
      TagItem(id: 'Drama',        name: 'Drama',        group: 'genre'),
      TagItem(id: 'Fantasy',      name: 'Fantasy',      group: 'genre'),
      TagItem(id: 'Harem',        name: 'Harem',        group: 'genre'),
      TagItem(id: 'Historical',   name: 'Historical',   group: 'genre'),
      TagItem(id: 'Horror',       name: 'Horror',       group: 'genre'),
      TagItem(id: 'Romance',      name: 'Romance',      group: 'genre'),
      TagItem(id: 'School Life',  name: 'School Life',  group: 'genre'),
      TagItem(id: 'Sci-fi',       name: 'Sci-Fi',       group: 'genre'),
      TagItem(id: 'Slice of Life',name: 'Slice of Life',group: 'genre'),
      TagItem(id: 'Supernatural', name: 'Supernatural', group: 'genre'),
      TagItem(id: 'Ecchi',        name: 'Ecchi',        group: 'genre'),
      TagItem(id: 'Hentai',       name: 'Hentai 🔞',    group: 'genre'),
    ];
  }

  MangaItem _fromMP(Map<String, dynamic> e) {
    final d = e['data'] as Map<String, dynamic>? ?? {};
    final id = e['id']?.toString() ?? '';
    final title = d['name'] as String? ?? '';
    String? cover = d['urlCover600'] as String? ?? d['urlCoverOri'] as String?;
    if (cover != null && !cover.startsWith('http')) {
      cover = 'https://mangapark.net$cover';
    }
    final genres = (d['genres'] as List?)?.cast<String>() ?? [];
    final isHentai = d['isHentai'] as bool? ?? false;
    final status = (d['uploadStatus'] as String? ?? '').contains('ongoing') ? 'ongoing' : 'completed';
    return MangaItem(
      id: id,
      title: title,
      description: d['summary'] as String? ?? '',
      status: status,
      contentRating: isHentai ? 'pornographic' : 'suggestive',
      externalCoverUrl: cover,
      tags: genres,
      availableLanguages: const ['en'],
    );
  }
}


