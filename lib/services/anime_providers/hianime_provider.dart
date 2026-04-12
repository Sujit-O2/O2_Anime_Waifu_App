import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:anime_waifu/models/anime_models.dart';
import 'package:anime_waifu/services/anime_providers/anime_provider.dart';

class HiAnimeProvider implements AnimeProvider {
  static const List<String> _apiHosts = [
    'https://aniwatch-api-five.vercel.app',
    'https://aniwatch-api-production.up.railway.app',
    'https://api-aniwatch.onrender.com',
  ];

  static const String _jikanBase = 'https://api.jikan.moe/v4';

  Map<String, String> get _headers => const {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
        'Accept': 'application/json',
      };

  @override
  String get name => 'HiAnime';

  @override
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) async {
    try {
      final q = Uri.encodeQueryComponent(title);
      final uri = Uri.parse('$_jikanBase/anime?q=$q&limit=$limit&sfw=false');
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];
      return data.whereType<Map<String, dynamic>>().map(_fromJikan).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeItem>> getTrending({int limit = 24}) async {
    try {
      final uri = Uri.parse(
        '$_jikanBase/top/anime?filter=airing&limit=$limit&sfw=false',
      );
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];
      return data.whereType<Map<String, dynamic>>().map(_fromJikan).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeItem>> getPopular({int limit = 24}) async {
    try {
      final uri = Uri.parse(
        '$_jikanBase/top/anime?filter=bypopularity&limit=$limit&sfw=false',
      );
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];
      return data.whereType<Map<String, dynamic>>().map(_fromJikan).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) async {
    try {
      final titles = await _fetchJikanTitles(animeId);
      if (titles.isEmpty) {
        return _jikanEpisodes(animeId);
      }

      final hianimeId = await _findHiAnimeId(titles);
      if (hianimeId == null) {
        return _jikanEpisodes(animeId);
      }

      final episodes = await getEpisodesByProviderId(hianimeId);
      if (episodes.isNotEmpty) {
        return episodes;
      }
    } catch (_) {}

    return _jikanEpisodes(animeId);
  }

  Future<String?> searchHiAnimeId(String title) async {
    for (final host in _apiHosts) {
      try {
        final q = Uri.encodeQueryComponent(title);
        final resp = await http
            .get(
              Uri.parse('$host/anime/search?q=$q'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) {
          continue;
        }

        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final animes = _pickList(json['animes']);
        if (animes.isEmpty) {
          continue;
        }

        final best = _pickBestAnimeMatch(title, animes);
        final id = best['id']?.toString() ?? best['animeId']?.toString();
        if (id != null && id.isNotEmpty) {
          return id;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<List<AnimeEpisode>> getEpisodesByProviderId(
      String providerAnimeId) async {
    for (final host in _apiHosts) {
      try {
        final resp = await http
            .get(
              Uri.parse('$host/anime/episodes/$providerAnimeId'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 12));
        if (resp.statusCode != 200) {
          continue;
        }

        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final rawEpisodes = _pickList(json['episodes']);
        if (rawEpisodes.isEmpty) {
          continue;
        }

        final episodes = rawEpisodes
            .map(_toEpisode)
            .where((episode) => episode.id.isNotEmpty)
            .toList();
        if (episodes.isNotEmpty) {
          return episodes;
        }
      } catch (_) {
        continue;
      }
    }

    return [];
  }

  Future<List<AnimeEpisode>> _jikanEpisodes(String animeId) async {
    final episodes = <AnimeEpisode>[];
    try {
      final uri = Uri.parse('$_jikanBase/anime/$animeId/episodes?page=1');
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return episodes;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];
      for (final value in data.whereType<Map<String, dynamic>>()) {
        episodes.add(
          AnimeEpisode(
            id: '${value['mal_id']}',
            number: value['mal_id'] as int? ?? episodes.length + 1,
            title: value['title'] as String? ?? 'Episode ${value['mal_id']}',
            isFiller: value['filler'] as bool? ?? false,
          ),
        );
      }
    } catch (_) {}
    return episodes;
  }

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) {
    return getVideoSourcesForType(episodeId);
  }

  Future<List<AnimeVideoSource>> getVideoSourcesForType(
    String episodeId, {
    String type = 'sub',
  }) async {
    final orderedCategories = <String>[
      type,
      ...['sub', 'dub', 'raw'].where((category) => category != type),
    ];

    for (final host in _apiHosts) {
      try {
        final serversResp = await http
            .get(
              Uri.parse('$host/anime/servers?episodeId=$episodeId'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 5));
        if (serversResp.statusCode != 200) {
          continue;
        }

        final serversJson =
            jsonDecode(serversResp.body) as Map<String, dynamic>;
        for (final category in orderedCategories) {
          final servers = _pickList(serversJson[category]);
          for (final server in servers.whereType<Map<String, dynamic>>()) {
            final serverName = server['serverName']?.toString() ?? '';
            if (serverName.isEmpty) {
              continue;
            }

            try {
              final linksResp = await http
                  .get(
                    Uri.parse(
                      '$host/anime/episode-srcs?id=$episodeId&server=$serverName&category=$category',
                    ),
                    headers: _headers,
                  )
                  .timeout(const Duration(seconds: 5));
              if (linksResp.statusCode != 200) {
                continue;
              }

              final linksJson =
                  jsonDecode(linksResp.body) as Map<String, dynamic>;
              final sources = _pickList(linksJson['sources'])
                  .whereType<Map<String, dynamic>>()
                  .map(
                    (source) => AnimeVideoSource(
                      url: source['url']?.toString() ?? '',
                      quality:
                          source['quality']?.toString() ?? 'auto ($category)',
                      isM3U8: source['isM3U8'] as bool? ??
                          (source['url']?.toString().contains('.m3u8') ?? true),
                      headers: linksJson['headers'] is Map
                          ? Map<String, String>.from(
                              linksJson['headers'] as Map,
                            )
                          : null,
                    ),
                  )
                  .where((source) => source.url.isNotEmpty)
                  .toList();
              if (sources.isNotEmpty) {
                return sources;
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

  AnimeItem _fromJikan(Map<String, dynamic> value) {
    final images = value['images'] as Map<String, dynamic>? ?? {};
    final jpg = images['jpg'] as Map<String, dynamic>? ?? {};
    final genres = (value['genres'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((genre) => genre['name'] as String? ?? '')
        .where((genre) => genre.isNotEmpty)
        .toList();

    return AnimeItem(
      id: '${value['mal_id']}',
      title: value['title'] as String? ?? 'Unknown',
      description: value['synopsis'] as String? ?? '',
      coverUrl: jpg['large_image_url'] as String? ??
          jpg['image_url'] as String? ??
          '',
      status: value['status'] as String? ?? 'Unknown',
      totalEpisodes: value['episodes'] as int? ?? 0,
      score: (value['score'] as num?)?.toDouble() ?? 0.0,
      genres: genres,
    );
  }

  Future<List<String>> _fetchJikanTitles(String animeId) async {
    final resp = await http
        .get(
          Uri.parse('$_jikanBase/anime/$animeId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      return [];
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return <String>[
      data['title_english']?.toString() ?? '',
      data['title']?.toString() ?? '',
      data['title_japanese']?.toString() ?? '',
    ].where((title) => title.trim().isNotEmpty).toSet().toList();
  }

  Future<String?> _findHiAnimeId(List<String> titles) async {
    for (final title in titles) {
      final id = await searchHiAnimeId(title);
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }
    return null;
  }

  List<dynamic> _pickList(dynamic value) {
    if (value is List) {
      return value;
    }
    if (value is String && value.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded;
        }
      } catch (_) {}
    }
    return const [];
  }

  Map<String, dynamic> _pickBestAnimeMatch(
      String title, List<dynamic> results) {
    final normalizedQuery = _normalizeTitle(title);
    Map<String, dynamic>? best;
    var bestScore = -1;

    for (final entry in results.whereType<Map<String, dynamic>>()) {
      final candidateTitle =
          entry['name']?.toString() ?? entry['title']?.toString() ?? '';
      final normalizedCandidate = _normalizeTitle(candidateTitle);

      var score = 0;
      if (normalizedCandidate == normalizedQuery) score += 4;
      if (normalizedCandidate.contains(normalizedQuery)) score += 2;
      if (normalizedQuery.contains(normalizedCandidate)) score += 1;

      if (best == null || score > bestScore) {
        best = entry;
        bestScore = score;
      }
    }

    return best ?? const <String, dynamic>{};
  }

  AnimeEpisode _toEpisode(dynamic value) {
    final episode =
        value is Map<String, dynamic> ? value : const <String, dynamic>{};
    final number =
        _asInt(episode['number']) ?? _asInt(episode['episodeNo']) ?? 0;
    return AnimeEpisode(
      id: episode['episodeId']?.toString() ?? episode['id']?.toString() ?? '',
      number: number,
      title: episode['title']?.toString() ?? 'Episode $number',
      isFiller: episode['isFiller'] as bool? ?? false,
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _normalizeTitle(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}


