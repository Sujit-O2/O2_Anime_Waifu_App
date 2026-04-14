import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:anime_waifu/models/anime_models.dart';
import 'package:anime_waifu/services/anime_providers/anime_provider.dart';
import 'package:anime_waifu/services/anime_providers/hianime_provider.dart';

class AniListProvider implements AnimeProvider {
  static const String _base = 'https://graphql.anilist.co';
  static final HiAnimeProvider _hianime = HiAnimeProvider();

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  String get name => 'AniList';

  Future<List<AnimeItem>> _gql(
    String query,
    Map<String, dynamic> variables,
  ) async {
    try {
      final resp = await http
          .post(
            Uri.parse(_base),
            headers: _headers,
            body: jsonEncode({'query': query, 'variables': variables}),
          )
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return [];

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final page = json['data']?['Page'] as Map<String, dynamic>? ?? {};
      final media = page['media'] as List? ?? [];
      return media.whereType<Map<String, dynamic>>().map(_fromAniList).toList();
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
    try {
      final meta = await _fetchMediaMeta(animeId);
      if (meta == null) {
        return [];
      }

      final hianimeId = await _findHiAnimeId(meta.titles);
      if (hianimeId != null) {
        final episodes = await _hianime.getEpisodesByProviderId(hianimeId);
        if (episodes.isNotEmpty) {
          return episodes;
        }
      }

      return List.generate(
        meta.episodeCount,
        (index) => AnimeEpisode(
          id: '$animeId-ep-${index + 1}',
          number: index + 1,
          title: 'Episode ${index + 1}',
        ),
      );
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) {
    return getVideoSourcesForType(episodeId, 'sub');
  }

  Future<List<AnimeVideoSource>> getVideoSourcesForType(
    String episodeId,
    String type,
  ) async {
    try {
      if (!episodeId.contains('-ep-')) {
        return _hianime.getVideoSourcesForType(episodeId, type: type);
      }

      final parts = episodeId.split('-ep-');
      final animeId = parts[0];
      final episodeNumber = int.tryParse(parts[1]) ?? 1;
      final meta = await _fetchMediaMeta(animeId);
      if (meta == null) {
        return [];
      }

      final hianimeId = await _findHiAnimeId(meta.titles);
      if (hianimeId == null) {
        return [];
      }

      final episodes = await _hianime.getEpisodesByProviderId(hianimeId);
      if (episodes.isEmpty) {
        return [];
      }

      final targetEpisode = episodes.firstWhere(
        (episode) => episode.number == episodeNumber,
        orElse: () => episodes.first,
      );

      return _hianime.getVideoSourcesForType(targetEpisode.id, type: type);
    } catch (_) {
      return [];
    }
  }

  AnimeItem _fromAniList(Map<String, dynamic> value) {
    final title = value['title'] as Map<String, dynamic>? ?? {};
    final coverImage = value['coverImage'] as Map<String, dynamic>? ?? {};
    final displayTitle =
        title['english'] as String? ?? title['romaji'] as String? ?? 'Unknown';
    final score = (value['averageScore'] as int? ?? 0) / 10.0;

    String status;
    switch (value['status']) {
      case 'RELEASING':
        status = 'Airing';
        break;
      case 'FINISHED':
        status = 'Finished';
        break;
      case 'NOT_YET_RELEASED':
        status = 'Upcoming';
        break;
      default:
        status = value['status']?.toString() ?? 'Unknown';
    }

    return AnimeItem(
      id: '${value['id']}',
      title: displayTitle,
      description: (value['description'] as String? ?? '')
          .replaceAll(RegExp(r'<[^>]*>'), ''),
      coverUrl: coverImage['extraLarge'] as String? ??
          coverImage['large'] as String? ??
          '',
      status: status,
      totalEpisodes: value['episodes'] as int? ?? 0,
      score: score,
      genres: (value['genres'] as List?)?.cast<String>() ?? const [],
    );
  }

  Future<_AniListMediaMeta?> _fetchMediaMeta(String animeId) async {
    const query = '''
      query(\$id: Int) {
        Media(id: \$id, type: ANIME) {
          episodes
          title { english romaji native }
        }
      }
    ''';

    final resp = await http
        .post(
          Uri.parse(_base),
          headers: _headers,
          body: jsonEncode({
            'query': query,
            'variables': {'id': int.tryParse(animeId) ?? 0},
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      return null;
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final media = json['data']?['Media'] as Map<String, dynamic>?;
    if (media == null) {
      return null;
    }

    final title = media['title'] as Map<String, dynamic>? ?? {};
    final titles = <String>[
      title['english']?.toString() ?? '',
      title['romaji']?.toString() ?? '',
      title['native']?.toString() ?? '',
    ].where((entry) => entry.trim().isNotEmpty).toSet().toList();

    return _AniListMediaMeta(
      titles: titles,
      episodeCount: media['episodes'] as int? ?? 0,
    );
  }

  Future<String?> _findHiAnimeId(List<String> titles) async {
    for (final title in titles) {
      final id = await _hianime.searchHiAnimeId(title);
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }
    return null;
  }
}

class _AniListMediaMeta {
  const _AniListMediaMeta({
    required this.titles,
    required this.episodeCount,
  });

  final List<String> titles;
  final int episodeCount;
}


