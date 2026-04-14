import 'dart:convert';
import 'package:anime_waifu/models/anime_models.dart';
import 'package:anime_waifu/services/utilities_core/robust_http_client.dart';
import 'package:anime_waifu/services/anime_providers/anime_provider.dart';

/// A universal wrapper for Consumet APIs that supports 10+ standard scraping routes
/// such as Zoro, Enime, Animepahe, 9Anime, Bilibili, Yugen, etc.
class ConsumetGenericProvider implements AnimeProvider {
  final String providerName;
  final String consumetRoute;

  ConsumetGenericProvider({required this.providerName, required this.consumetRoute});

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
  String get name => providerName;

  Future<dynamic> _fetchWrap(String path) async {
    for (final host in _consumetHosts) {
      try {
        final uri = Uri.parse('$host/anime/$consumetRoute$path');
        final resp = await RobustHttpClient.get(uri, headers: _headers, timeout: const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  @override
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) async {
    final q = Uri.encodeComponent(title);
    final json = await _fetchWrap('/$q');
    return _parseList(json);
  }

  @override
  Future<List<AnimeItem>> getTrending({int limit = 24}) async {
    final json = await _fetchWrap('/app/trending'); 
    if (json == null) {
      // fallback to popular
      return getPopular(limit: limit);
    }
    return _parseList(json);
  }

  @override
  Future<List<AnimeItem>> getPopular({int limit = 24}) async {
    final json = await _fetchWrap('/popular'); 
    return _parseList(json);
  }

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) async {
    final json = await _fetchWrap('/info?id=$animeId');
    if (json == null) return [];
    
    final eps = json['episodes'] as List? ?? [];
    return eps.map((e) {
      final epMap = e as Map<String, dynamic>;
      return AnimeEpisode(
        id: epMap['id']?.toString() ?? '',
        number: int.tryParse(epMap['number']?.toString() ?? '1') ?? 1,
        title: epMap['title']?.toString() ?? '',
      );
    }).toList();
  }

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) async {
    final json = await _fetchWrap('/watch?episodeId=$episodeId');
    if (json == null) return [];
    
    final sources = json['sources'] as List? ?? [];
    
    // Extract dynamic headers from Consumet (usually 'Referer' is required for GogoCDN/Zoro)
    Map<String, String>? dynamicHeaders;
    if (json['headers'] is Map) {
      dynamicHeaders = Map<String, String>.from(json['headers'] as Map);
    }

    return sources.map((s) {
      final srcMap = s as Map<String, dynamic>;
      return AnimeVideoSource(
        url: srcMap['url']?.toString() ?? '',
        quality: srcMap['quality']?.toString() ?? 'auto',
        isM3U8: srcMap['isM3U8'] as bool? ?? true,
        headers: dynamicHeaders,
      );
    }).toList();
  }

  List<AnimeItem> _parseList(dynamic json) {
    if (json == null) return [];
    List<dynamic> results = [];
    if (json is Map && json.containsKey('results')) {
      results = json['results'] as List;
    } else if (json is List) {
      results = json;
    }

    return results.map((e) {
      final item = e as Map<String, dynamic>;
      return AnimeItem(
        id: item['id']?.toString() ?? '',
        title: item['title']?.toString() ?? 'Unknown',
        coverUrl: item['image']?.toString() ?? '',
        status: item['status']?.toString() ?? 'unknown',
        score: double.tryParse(item['rating']?.toString() ?? '0') ?? 0.0,
      );
    }).toList();
  }
}


