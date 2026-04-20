import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anime_waifu/models/anime_models.dart';
import 'package:anime_waifu/services/anime_providers/anime_provider.dart';

/// Uses Jikan (MyAnimeList) API for metadata and GogoAnime
/// scraper APIs for actual M3U8 streaming sources.
class GogoAnimeProvider implements AnimeProvider {
  static const String _jikanBase = 'https://api.jikan.moe/v4';

  // Multiple fallback Consumet instances for streaming sources
  static const List<String> _consumetHosts = [
    'https://consumet-api-xntj.onrender.com',
    'https://consumet-anight.vercel.app',
    'https://consumet-api-clone.vercel.app',
  ];

  Map<String, String> get _headers => {
    'User-Agent': 'AnimeWaifuApp/3.0',
    'Accept': 'application/json',
  };

  @override
  String get name => 'GogoAnime';

  // ──────────────────────── METADATA (Jikan / MAL) ────────────────────────

  @override
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) async {
    try {
      final q = Uri.encodeQueryComponent(title);
      final uri = Uri.parse('$_jikanBase/anime?q=$q&limit=$limit&sfw=false');
      final resp = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];
      return data.map((e) => _fromJikan(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeItem>> getTrending({int limit = 24}) async {
    try {
      final uri = Uri.parse(
          '$_jikanBase/top/anime?filter=airing&limit=$limit&sfw=false');
      final resp = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];
      return data.map((e) => _fromJikan(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeItem>> getPopular({int limit = 24}) async {
    try {
      final uri = Uri.parse(
          '$_jikanBase/top/anime?filter=bypopularity&limit=$limit&sfw=false');
      final resp = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];
      return data.map((e) => _fromJikan(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ──────────────────────── EPISODES ────────────────────────

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) async {
    // We use Jikan's episode list + paginate if needed
    final episodes = <AnimeEpisode>[];
    int page = 1;
    bool hasMore = true;

    try {
      while (hasMore && page <= 5) {
        // Cap at 5 pages (500 eps)
        final uri = Uri.parse(
            '$_jikanBase/anime/$animeId/episodes?page=$page');
        final resp = await http.get(uri, headers: _headers)
            .timeout(const Duration(seconds: 12));
        if (resp.statusCode != 200) break;

        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = json['data'] as List? ?? [];
        if (data.isEmpty) break;

        for (final e in data) {
          final ep = e as Map<String, dynamic>;
          episodes.add(AnimeEpisode(
            id: '${ep['mal_id']}',
            number: ep['mal_id'] as int? ?? episodes.length + 1,
            title: ep['title'] as String? ?? 'Episode ${ep['mal_id']}',
            isFiller: ep['filler'] as bool? ?? false,
          ));
        }

        hasMore = json['pagination']?['has_next_page'] as bool? ?? false;
        page++;

        // Jikan rate limit: 3 req/sec  — small delay between pages
        if (hasMore) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    } catch (_) {}

    return episodes;
  }

  // ──────────────────────── VIDEO SOURCES (GogoAnime via Consumet) ────────

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) async {
    // episodeId format expected: "slug-episode-N"  (GogoAnime slug)
    for (final host in _consumetHosts) {
      try {
        final uri = Uri.parse(
            '$host/anime/gogoanime/watch/$episodeId');
        final resp = await http.get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 200) continue;
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final sources = json['sources'] as List? ?? [];
        if (sources.isEmpty) continue;
        return sources.map((s) {
          final src = s as Map<String, dynamic>;
          return AnimeVideoSource(
            url: src['url'] as String? ?? '',
            quality: src['quality'] as String? ?? 'default',
            isM3U8: src['isM3U8'] as bool? ?? true,
          );
        }).toList();
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  /// Get video sources with sub/dub type selection.
  /// [type] can be 'sub', 'dub', or 'raw'.
  Future<List<AnimeVideoSource>> getVideoSourcesWithType(
      String episodeId, String type) async {
    for (final host in _consumetHosts) {
      try {
        final uri = Uri.parse(
            '$host/anime/gogoanime/watch/$episodeId?server=gogocdn');
        final resp = await http.get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 200) continue;
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final sources = json['sources'] as List? ?? [];
        if (sources.isEmpty) continue;
        return sources.map((s) {
          final src = s as Map<String, dynamic>;
          return AnimeVideoSource(
            url: src['url'] as String? ?? '',
            quality: '${src['quality'] ?? 'default'} ($type)',
            isM3U8: src['isM3U8'] as bool? ?? true,
          );
        }).toList();
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  /// Search for sub/dub variants of a title on GogoAnime.
  /// Returns the slug for sub or dub version.
  Future<String?> getGogoSlugForType(String title, String type) async {
    final suffix = type == 'dub' ? ' (Dub)' : '';
    return getGogoSlug('$title$suffix');
  }

  /// Look up the GogoAnime slug for a MAL anime so we can fetch streaming links
  Future<String?> getGogoSlug(String title) async {
    for (final host in _consumetHosts) {
      try {
        final q = Uri.encodeQueryComponent(title);
        final uri = Uri.parse('$host/anime/gogoanime/$q');
        final resp = await http.get(uri, headers: _headers)
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) continue;
        final json = jsonDecode(resp.body);
        final results = json['results'] as List? ?? [];
        if (results.isNotEmpty) {
          return results[0]['id'] as String?;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Fetch episode list from GogoAnime via Consumet for a specific slug
  Future<List<AnimeEpisode>> getGogoEpisodes(String gogoSlug) async {
    for (final host in _consumetHosts) {
      try {
        final uri = Uri.parse('$host/anime/gogoanime/info/$gogoSlug');
        final resp = await http.get(uri, headers: _headers)
            .timeout(const Duration(seconds: 12));
        if (resp.statusCode != 200) continue;
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final episodes = json['episodes'] as List? ?? [];
        return episodes.map((e) {
          final ep = e as Map<String, dynamic>;
          return AnimeEpisode(
            id: ep['id'] as String? ?? '',
            number: ep['number'] as int? ?? 0,
            title: 'Episode ${ep['number']}',
          );
        }).toList();
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  // ──────────────────────── HELPERS ────────────────────────

  AnimeItem _fromJikan(Map<String, dynamic> e) {
    final images = e['images'] as Map<String, dynamic>? ?? {};
    final jpg = images['jpg'] as Map<String, dynamic>? ?? {};
    final genres = (e['genres'] as List? ?? [])
        .map((g) => (g as Map<String, dynamic>)['name'] as String? ?? '')
        .where((g) => g.isNotEmpty)
        .toList();

    return AnimeItem(
      id: '${e['mal_id']}',
      title: e['title'] as String? ?? 'Unknown',
      description: e['synopsis'] as String? ?? '',
      coverUrl: jpg['large_image_url'] as String? ??
          jpg['image_url'] as String? ?? '',
      status: e['status'] as String? ?? 'Unknown',
      totalEpisodes: e['episodes'] as int? ?? 0,
      score: (e['score'] as num?)?.toDouble() ?? 0.0,
      genres: genres,
    );
  }
}


