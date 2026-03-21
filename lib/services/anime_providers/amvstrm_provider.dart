import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/anime_models.dart';
import 'anime_provider.dart';

/// Provider for amvstr.me (Aggregates multiple sources including GogoAnime)
class AmvstrmProvider implements AnimeProvider {
  static const String _baseUrl = 'https://api.amvstr.me/api/v2';

  Map<String, String> get _headers => {
    'User-Agent': 'AnimeWaifuApp/3.0',
    'Accept': 'application/json',
  };

  @override
  String get name => 'Anime (Amvstrm)';

  @override
  Future<List<AnimeItem>> searchAnime(String title, {int limit = 24}) async {
    try {
      final q = Uri.encodeQueryComponent(title);
      final resp = await http.get(Uri.parse('$_baseUrl/search?q=$q'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = json['results'] as List? ?? [];
      
      return results.map((e) => _fromAmv(e as Map<String, dynamic>)).take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeItem>> getTrending({int limit = 24}) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/trending'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = json['results'] as List? ?? [];
      
      return results.map((e) => _fromAmv(e as Map<String, dynamic>)).take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeItem>> getPopular({int limit = 24}) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/popular'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = json['results'] as List? ?? [];
      
      return results.map((e) => _fromAmv(e as Map<String, dynamic>)).take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeEpisode>> getEpisodes(String animeId) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/info/$animeId'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final eps = json['episodes'] as List? ?? [];
      
      final result = <AnimeEpisode>[];
      for (final ep in eps) {
        if (ep is! Map) continue;
        result.add(AnimeEpisode(
          id: ep['id']?.toString() ?? '',
          number: int.tryParse(ep['number']?.toString() ?? '') ?? 0,
          title: ep['title']?.toString() ?? 'Episode ${ep['number']}',
        ));
      }
      return result.reversed.toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeVideoSource>> getVideoSources(String episodeId) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/stream/$episodeId'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final streamUrl = json['stream']?['multi']?['main']?['url'] as String?;
      
      if (streamUrl != null && streamUrl.isNotEmpty) {
        return [
          AnimeVideoSource(
            url: streamUrl,
            quality: 'Auto',
            isM3U8: streamUrl.contains('.m3u8'),
            headers: {'Referer': 'https://api.amvstr.me/'},
          )
        ];
      }
    } catch (_) {
      // Ignore errors and return empty sources
    }
    return [];
  }

  AnimeItem _fromAmv(Map<String, dynamic> json) {
    final titleInfo = json['title'] as Map<String, dynamic>? ?? {};
    final title = titleInfo['english'] ?? titleInfo['romaji'] ?? titleInfo['userPreferred'] ?? 'Unknown';
    
    return AnimeItem(
      id: json['id']?.toString() ?? '',
      title: title.toString(),
      description: _stripHtml(json['description']?.toString() ?? ''),
      coverUrl: json['coverImage']?['large']?.toString() ?? json['image']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      totalEpisodes: int.tryParse(json['totalEpisodes']?.toString() ?? '') ?? json['episodes'] as int? ?? 1,
      score: double.tryParse(json['averageScore']?.toString() ?? '') ?? 0.0,
      genres: (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
