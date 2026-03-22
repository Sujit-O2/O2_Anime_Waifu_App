import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/anime_models.dart';
import 'anime_provider.dart';

/// HiAnime (aniwatch) Provider — uses the actively maintained 
/// aniwatch-api which scrapes hianime.to (successor to Zoro.to).
/// This replaces the dead GogoAnime/Consumet pipeline.
class HiAnimeProvider implements AnimeProvider {
  // Trimmed to verified-alive instances only. Dead Vercel clones removed to
  // prevent 20-second timeout chains before Cinetaro embed fallback triggers.
  static const List<String> _apiHosts = [
    'https://aniwatch-api-production.up.railway.app',
    'https://api-aniwatch.onrender.com',
  ];

  // We still use Jikan for reliable metadata (it's never down)
  static const String _jikanBase = 'https://api.jikan.moe/v4';

  Map<String, String> get _headers => {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
    'Accept': 'application/json',
  };

  @override
  String get name => 'HiAnime';

  // ──────────── METADATA via Jikan (reliable) ────────────

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

  // ──────────── EPISODES via HiAnime search + info ────────────

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) async {
    // animeId is MAL ID. We need to search HiAnime for the title,
    // then get episode list from HiAnime.
    // First: get title from Jikan
    try {
      final jikanResp = await http.get(
        Uri.parse('$_jikanBase/anime/$animeId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      if (jikanResp.statusCode != 200) return _jikanEpisodes(animeId);
      final jikanJson = jsonDecode(jikanResp.body) as Map<String, dynamic>;
      final data = jikanJson['data'] as Map<String, dynamic>? ?? {};
      
      // HiAnime prefers English titles (e.g., "Demon Slayer" not "Kimetsu no Yaiba")
      final englishTitle = data['title_english'] as String?;
      final romajiTitle = data['title'] as String? ?? '';
      
      if (romajiTitle.isEmpty) return _jikanEpisodes(animeId);

      // Try searching with English title first, fallback to Romaji
      String? hianimeId;
      if (englishTitle != null && englishTitle.isNotEmpty) {
        hianimeId = await searchHiAnimeId(englishTitle);
      }
      if (hianimeId == null) {
        hianimeId = await searchHiAnimeId(romajiTitle);
      }
      
      if (hianimeId == null) return _jikanEpisodes(animeId);

      // Get episodes from HiAnime
      for (final host in _apiHosts) {
        try {
          final resp = await http.get(
            Uri.parse('$host/anime/episodes/$hianimeId'),
            headers: _headers,
          ).timeout(const Duration(seconds: 12));
          if (resp.statusCode != 200) continue;
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final episodes = json['episodes'] as List? ?? [];
          if (episodes.isEmpty) continue;
          
          return episodes.map((e) {
            final ep = e as Map<String, dynamic>;
            return AnimeEpisode(
              id: ep['episodeId']?.toString() ?? '',
              number: ep['number'] as int? ?? 0,
              title: ep['title']?.toString() ?? 'Episode ${ep['number']}',
              isFiller: ep['isFiller'] as bool? ?? false,
            );
          }).toList();
        } catch (_) {
          continue;
        }
      }
    } catch (_) {}
    
    // Fallback to Jikan episode list
    return _jikanEpisodes(animeId);
  }

  /// Search HiAnime and return the hianime-specific ID (slug)
  Future<String?> searchHiAnimeId(String title) async {
    for (final host in _apiHosts) {
      try {
        final q = Uri.encodeQueryComponent(title);
        final resp = await http.get(
          Uri.parse('$host/anime/search?q=$q'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) continue;
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final animes = json['animes'] as List? ?? [];
        if (animes.isNotEmpty) {
          return animes[0]['id']?.toString();
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Fallback episode list from Jikan
  Future<List<AnimeEpisode>> _jikanEpisodes(String animeId) async {
    final episodes = <AnimeEpisode>[];
    try {
      final uri = Uri.parse('$_jikanBase/anime/$animeId/episodes?page=1');
      final resp = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return episodes;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];
      for (final e in data) {
        final ep = e as Map<String, dynamic>;
        episodes.add(AnimeEpisode(
          id: '${ep['mal_id']}',
          number: ep['mal_id'] as int? ?? episodes.length + 1,
          title: ep['title'] as String? ?? 'Episode ${ep['mal_id']}',
          isFiller: ep['filler'] as bool? ?? false,
        ));
      }
    } catch (_) {}
    return episodes;
  }

  // ──────────── VIDEO SOURCES via HiAnime ────────────

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) async {
    for (final host in _apiHosts) {
      try {
        final serversResp = await http.get(
          Uri.parse('$host/anime/servers?episodeId=$episodeId'),
          headers: _headers,
        ).timeout(const Duration(seconds: 5)); // Fails quickly if host is down
        
        if (serversResp.statusCode != 200) continue;
        final serversJson = jsonDecode(serversResp.body) as Map<String, dynamic>;
        
        for (final category in ['sub', 'dub', 'raw']) {
          final servers = serversJson[category] as List? ?? [];
          for (final server in servers) {
            final sv = server as Map<String, dynamic>;
            final serverName = sv['serverName']?.toString() ?? '';
            
            try {
              final linksResp = await http.get(
                Uri.parse('$host/anime/episode-srcs?id=$episodeId&server=$serverName&category=$category'),
                headers: _headers,
              ).timeout(const Duration(seconds: 5)); // Fast timeout to skip blocked proxies
              
              if (linksResp.statusCode != 200) continue;
              final linksJson = jsonDecode(linksResp.body) as Map<String, dynamic>;
              final sources = linksJson['sources'] as List? ?? [];
              
              if (sources.isNotEmpty) {
                Map<String, String>? streamHeaders;
                if (linksJson['headers'] is Map) {
                  streamHeaders = Map<String, String>.from(linksJson['headers'] as Map);
                }
                
                return sources.map((s) {
                  final src = s as Map<String, dynamic>;
                  return AnimeVideoSource(
                    url: src['url']?.toString() ?? '',
                    quality: src['quality']?.toString() ?? 'auto ($category)',
                    isM3U8: src['isM3U8'] as bool? ?? (src['url']?.toString().contains('.m3u8') ?? true),
                    headers: streamHeaders,
                  );
                }).toList();
              }
            } catch (_) {
              continue;
            }
          }
        }
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  // ──────────── HELPERS ────────────

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
