import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/anime_models.dart';
import 'anime_provider.dart';
import 'amvstrm_provider.dart';

/// AniList GraphQL API — modern, ultra-fast anime metadata source.
/// Uses anilist.co/graphql for search, trending, and popular.
class AniListProvider implements AnimeProvider {
  static const String _base = 'https://graphql.anilist.co';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  @override
  String get name => 'AniList';

  Future<List<AnimeItem>> _gql(String query, Map<String, dynamic> variables) async {
    try {
      final resp = await http.post(
        Uri.parse(_base),
        headers: _headers,
        body: jsonEncode({'query': query, 'variables': variables}),
      ).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final page = json['data']?['Page'] as Map<String, dynamic>? ?? {};
      final media = page['media'] as List? ?? [];
      return media.map((e) => _fromAniList(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static const String _mediaFields = '''
    id
    title { romaji english native }
    description(asHtml: false)
    coverImage { large extraLarge }
    episodes
    status
    averageScore
    genres
    format
  ''';

  @override
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) async {
    const query = '''
      query(\$search: String, \$perPage: Int) {
        Page(perPage: \$perPage) {
          media(search: \$search, type: ANIME, sort: SEARCH_MATCH) {
            $_mediaFields
          }
        }
      }
    ''';
    return _gql(query, {'search': title, 'perPage': limit});
  }

  @override
  Future<List<AnimeItem>> getTrending({int limit = 24}) async {
    const query = '''
      query(\$perPage: Int) {
        Page(perPage: \$perPage) {
          media(type: ANIME, sort: TRENDING_DESC) {
            $_mediaFields
          }
        }
      }
    ''';
    return _gql(query, {'perPage': limit});
  }

  @override
  Future<List<AnimeItem>> getPopular({int limit = 24}) async {
    const query = '''
      query(\$perPage: Int) {
        Page(perPage: \$perPage) {
          media(type: ANIME, sort: POPULARITY_DESC) {
            $_mediaFields
          }
        }
      }
    ''';
    return _gql(query, {'perPage': limit});
  }

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) async {
    // AniList doesn't serve episodes directly — we generate placeholders
    // based on the anime's known episode count
    try {
      const query = '''
        query(\$id: Int) {
          Media(id: \$id, type: ANIME) { episodes }
        }
      ''';
      final resp = await http.post(Uri.parse(_base),
        headers: _headers,
        body: jsonEncode({'query': query, 'variables': {'id': int.tryParse(animeId) ?? 0}}),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final epCount = json['data']?['Media']?['episodes'] as int? ?? 0;
      return List.generate(epCount, (i) => AnimeEpisode(
        id: '$animeId-ep-${i + 1}',
        number: i + 1,
        title: 'Episode ${i + 1}',
      ));
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) async {
    try {
      if (!episodeId.contains('-ep-')) return [];
      final parts = episodeId.split('-ep-');
      final aid = parts[0];
      final epNum = int.tryParse(parts[1]) ?? 1;

      // 1. Fetch title from AniList
      const titleQuery = 'query(\$id: Int) { Media(id: \$id, type: ANIME) { title { english romaji } } }';
      final resp = await http.post(Uri.parse(_base), headers: _headers,
          body: jsonEncode({'query': titleQuery, 'variables': {'id': int.tryParse(aid) ?? 0}}));
      if (resp.statusCode != 200) return [];
      
      final media = jsonDecode(resp.body)['data']?['Media']?['title'];
      if (media == null) return [];
      final title = media['english'] ?? media['romaji'];
      if (title == null) return [];

      // 2. Search AMVSTRM using the exact title
      final amv = AmvstrmProvider();
      final searchResults = await amv.searchAnime(title.toString());
      if (searchResults.isEmpty) return [];

      // 3. Get episodes list from AMVSTRM for the first match
      final amvId = searchResults.first.id;
      final episodes = await amv.getEpisodes(amvId);
      
      // 4. Find matching episode number
      final targetEp = episodes.firstWhere((e) => e.number == epNum, 
          orElse: () => episodes.firstWhere((e) => e.id.endsWith('-$epNum'), orElse: () => episodes.first));

      // 5. Extract strictly raw M3U8 video link
      return await amv.getVideoSources(targetEp.id);
    } catch (_) {
      return [];
    }
  }

  AnimeItem _fromAniList(Map<String, dynamic> e) {
    final title = e['title'] as Map<String, dynamic>? ?? {};
    final coverImage = e['coverImage'] as Map<String, dynamic>? ?? {};
    final displayTitle = title['english'] as String? ??
        title['romaji'] as String? ?? 'Unknown';
    final score = (e['averageScore'] as int? ?? 0) / 10.0;

    String statusStr;
    switch (e['status']) {
      case 'RELEASING': statusStr = 'Airing'; break;
      case 'FINISHED': statusStr = 'Finished'; break;
      case 'NOT_YET_RELEASED': statusStr = 'Upcoming'; break;
      default: statusStr = e['status']?.toString() ?? 'Unknown';
    }

    return AnimeItem(
      id: '${e['id']}',
      title: displayTitle,
      description: (e['description'] as String? ?? '')
          .replaceAll(RegExp(r'<[^>]*>'), ''),
      coverUrl: coverImage['extraLarge'] as String? ??
          coverImage['large'] as String? ?? '',
      status: statusStr,
      totalEpisodes: e['episodes'] as int? ?? 0,
      score: score,
      genres: (e['genres'] as List?)?.cast<String>() ?? [],
    );
  }
}
