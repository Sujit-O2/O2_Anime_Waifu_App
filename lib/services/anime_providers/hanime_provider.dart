import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anime_waifu/models/anime_models.dart';
import 'package:anime_waifu/services/anime_providers/anime_provider.dart';

/// 🔞 Hanime.tv provider — adult anime streaming via HTV search API.
class HanimeProvider implements AnimeProvider {
  static const String _searchBase = 'https://search.htv-services.com';
  static const String _videoBase = 'https://hanime.tv/api/v8';

  Map<String, String> get _headers => {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  @override
  String get name => 'Hanime 🔞';

  @override
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) async {
    try {
      return await _search(searchText: title, orderBy: 'likes', limit: limit);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeItem>> getTrending({int limit = 24}) async {
    try {
      return await _search(searchText: '', orderBy: 'trending', limit: limit);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeItem>> getPopular({int limit = 24}) async {
    try {
      return await _search(searchText: '', orderBy: 'likes', limit: limit);
    } catch (_) {
      return [];
    }
  }

  Future<List<AnimeItem>> getByTag(String tag, {int limit = 24}) async {
    try {
      return await _search(searchText: '', orderBy: 'trending', tags: [tag], limit: limit);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) async {
    // Hanime videos are standalone (each video is its own "episode")
    // Return a single-episode list with the slug as ID
    return [
      AnimeEpisode(id: animeId, number: 1, title: 'Watch'),
    ];
  }

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) async {
    try {
      final uri = Uri.parse('$_videoBase/video?id=$episodeId');
      final resp = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;

      // Try multiple response formats
      final servers = json['videos_manifest']?['servers'] as List? ?? [];
      final sources = <AnimeVideoSource>[];

      for (final server in servers) {
        final s = server as Map<String, dynamic>;
        final streams = s['streams'] as List? ?? [];
        for (final stream in streams) {
          final st = stream as Map<String, dynamic>;
          final url = st['url'] as String? ?? '';
          if (url.isEmpty) continue;
          final height = st['height'] as String? ?? 'default';
          sources.add(AnimeVideoSource(
            url: url,
            quality: '${height}p',
            isM3U8: url.contains('.m3u8'),
          ));
        }
      }

      // Fallback: check hentai_video.server_list
      if (sources.isEmpty) {
        final hv = json['hentai_video'] as Map<String, dynamic>? ?? {};
        final serverList = hv['servers'] as List? ?? [];
        for (final s in serverList) {
          final sv = s as Map<String, dynamic>;
          final streams = sv['streams'] as List? ?? [];
          for (final st in streams) {
            final stm = st as Map<String, dynamic>;
            final url = stm['url'] as String? ?? '';
            if (url.isEmpty) continue;
            sources.add(AnimeVideoSource(
              url: url,
              quality: stm['height']?.toString() ?? 'default',
              isM3U8: url.contains('.m3u8'),
            ));
          }
        }
      }

      return sources;
    } catch (_) {
      return [];
    }
  }

  /// Core search method using HTV services
  Future<List<AnimeItem>> _search({
    required String searchText,
    required String orderBy,
    List<String> tags = const [],
    int limit = 24,
  }) async {
    final body = jsonEncode({
      'search_text': searchText,
      'tags': tags,
      'tags_mode': 'AND',
      'brands': <String>[],
      'blacklist': <String>[],
      'order_by': orderBy,
      'ordering': 'desc',
      'page': 0,
    });

    final resp = await http.post(Uri.parse('$_searchBase/'),
        headers: _headers, body: body)
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return [];

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    
    List<dynamic> hits = [];
    if (json['hits'] is String) {
      hits = jsonDecode(json['hits'] as String) as List? ?? [];
    } else if (json['hits'] is List) {
      hits = json['hits'] as List;
    }

    final items = <AnimeItem>[];
    for (final hit in hits) {
      if (hit is! Map<String, dynamic>) continue;
      items.add(AnimeItem(
        id: hit['slug'] as String? ?? '',
        title: hit['name'] as String? ?? 'Unknown',
        description: _stripHtml(hit['description'] as String? ?? ''),
        coverUrl: hit['cover_url'] as String? ?? '',
        status: 'Released',
        totalEpisodes: 1,
        score: 0.0,
        genres: (hit['tags'] as List?)
            ?.map((t) => t.toString())
            .take(5)
            .toList() ?? [],
      ));
      if (items.length >= limit) break;
    }
    return items;
  }

  /// Strip HTML tags from description
  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  /// Available Hanime tags for genre filtering
  static const List<String> availableTags = [
    'Ahegao', 'Big Boobs', 'Blow Job', 'Bondage', 'Boobjob',
    'Censored', 'Cosplay', 'Creampie', 'Dark Skin', 'Facial',
    'Fantasy', 'Femdom', 'Futanari', 'Gangbang', 'Glasses',
    'Handjob', 'Harem', 'Horror', 'Incest', 'Lactation', 'Loli',
    'Maid', 'Masturbation', 'Milf', 'Monster', 'Netorase',
    'Netorare', 'Nurse', 'Orgy', 'Pov', 'Pregnancy', 'Public Sex',
    'Rape', 'Romance', 'School Girl', 'Shota', 'Softcore',
    'Succubus', 'Swimsuit', 'Teacher', 'Tentacle', 'Threesome',
    'Toys', 'Tsundere', 'Uncensored', 'Vanilla', 'Virgin', 'X-Ray',
    'Yuri',
  ];
}


