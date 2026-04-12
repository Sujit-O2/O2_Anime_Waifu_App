import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:anime_waifu/models/anime_models.dart';
import 'package:anime_waifu/services/anime_providers/anime_provider.dart';
import 'package:anime_waifu/services/anime_providers/hianime_provider.dart';

class AmvstrmProvider implements AnimeProvider {
  static const String _baseUrl = 'https://api.amvstr.me/api/v2';
  static final HiAnimeProvider _fallback = HiAnimeProvider();

  Map<String, String> get _headers => const {
        'User-Agent': 'AnimeWaifuApp/5.0',
        'Accept': 'application/json',
      };

  @override
  String get name => 'Stream Auto';

  @override
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) async {
    try {
      final q = Uri.encodeQueryComponent(title);
      final resp = await http
          .get(Uri.parse('$_baseUrl/search?q=$q'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = json['results'] as List? ?? [];
        final parsed = results
            .whereType<Map<String, dynamic>>()
            .map(_fromAmv)
            .take(limit)
            .toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (_) {}
    return _fallback.searchAnime(title, limit: limit);
  }

  @override
  Future<List<AnimeItem>> getTrending({int limit = 24}) async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/trending'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = json['results'] as List? ?? [];
        final parsed = results
            .whereType<Map<String, dynamic>>()
            .map(_fromAmv)
            .take(limit)
            .toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (_) {}
    return _fallback.getTrending(limit: limit);
  }

  @override
  Future<List<AnimeItem>> getPopular({int limit = 24}) async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/popular'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = json['results'] as List? ?? [];
        final parsed = results
            .whereType<Map<String, dynamic>>()
            .map(_fromAmv)
            .take(limit)
            .toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (_) {}
    return _fallback.getPopular(limit: limit);
  }

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/info/$animeId'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final episodes = json['episodes'] as List? ?? [];
        final parsed = episodes.whereType<Map>().map((episode) {
          return AnimeEpisode(
            id: episode['id']?.toString() ?? '',
            number: int.tryParse(episode['number']?.toString() ?? '') ?? 0,
            title:
                episode['title']?.toString() ?? 'Episode ${episode['number']}',
          );
        }).toList();
        if (parsed.isNotEmpty) {
          return parsed.reversed.toList();
        }
      }
    } catch (_) {}
    return _fallback.getEpisodes(animeId);
  }

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/stream/$episodeId'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final streamUrl = json['stream']?['multi']?['main']?['url'] as String?;
        if (streamUrl != null && streamUrl.isNotEmpty) {
          return [
            AnimeVideoSource(
              url: streamUrl,
              quality: 'Auto',
              isM3U8: streamUrl.contains('.m3u8'),
              headers: const {'Referer': 'https://api.amvstr.me/'},
            ),
          ];
        }
      }
    } catch (_) {}
    return _fallback.getVideoSources(episodeId);
  }

  AnimeItem _fromAmv(Map<String, dynamic> value) {
    final titleInfo = value['title'] as Map<String, dynamic>? ?? {};
    final title = titleInfo['english'] ??
        titleInfo['romaji'] ??
        titleInfo['userPreferred'] ??
        'Unknown';

    return AnimeItem(
      id: value['id']?.toString() ?? '',
      title: title.toString(),
      description: _stripHtml(value['description']?.toString() ?? ''),
      coverUrl: value['coverImage']?['large']?.toString() ??
          value['image']?.toString() ??
          '',
      status: value['status']?.toString() ?? 'Unknown',
      totalEpisodes: int.tryParse(value['totalEpisodes']?.toString() ?? '') ??
          value['episodes'] as int? ??
          1,
      score: double.tryParse(value['averageScore']?.toString() ?? '') ?? 0.0,
      genres: (value['genres'] as List?)
              ?.map((genre) => genre.toString())
              .toList() ??
          const [],
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}


