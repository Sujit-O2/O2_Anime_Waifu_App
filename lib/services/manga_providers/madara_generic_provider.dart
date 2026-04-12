
import 'package:anime_waifu/models/manga_models.dart';
import 'package:anime_waifu/services/utilities_core/robust_http_client.dart';
import 'package:anime_waifu/services/manga_providers/manga_provider.dart';

/// A universal wrapper for WordPress Madara themes.
/// By injecting a host URL, this class can natively scrape 15+ adult manhwa apps.
class MadaraGenericProvider implements MangaProvider {
  final String providerName;
  final String providerBaseUrl;
  final bool isAdult;

  MadaraGenericProvider({
    required this.providerName,
    required this.providerBaseUrl,
    this.isAdult = true,
  });

  Map<String, String> get _headers => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)',
    'Referer': providerBaseUrl,
    'Accept': 'text/html',
  };

  @override
  String get name => providerName;

  /// Extremely optimized regex-based lightweight scraping to avoid HTML parsing library dependencies
  @override
  Future<List<MangaItem>> searchManga(String title, {int limit = 24}) async {
    try {
      final q = Uri.encodeQueryComponent(title);
      final uri = Uri.parse('$providerBaseUrl/?s=$q&post_type=wp-manga');
      final resp = await RobustHttpClient.get(uri, headers: _headers);
      if (resp.statusCode != 200) return [];
      return _regexScrapeMangaList(resp.body);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MangaItem>> getTrending({int limit = 24}) async {
    try {
      final uri = Uri.parse('$providerBaseUrl/manga/');
      final resp = await RobustHttpClient.get(uri, headers: _headers);
      if (resp.statusCode != 200) return [];
      return _regexScrapeMangaList(resp.body);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MangaItem>> getByTag(String tagId, {int limit = 24}) async {
    try {
      final uri = Uri.parse('$providerBaseUrl/manga-genre/$tagId/');
      final resp = await RobustHttpClient.get(uri, headers: _headers);
      if (resp.statusCode != 200) return [];
      return _regexScrapeMangaList(resp.body);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ChapterItem>> getChapters(String mangaId,
      {String lang = 'en', int limit = 100, int offset = 0}) async {
    try {
      // POST logic to get chapters on Madara themes
      final mangaSlug = mangaId.replaceAll(providerBaseUrl, '').replaceAll('/manga/', '').replaceAll('/', '');
      final uri = Uri.parse('$providerBaseUrl/manga/$mangaSlug/ajax/chapters/');
      final resp = await RobustHttpClient.post(uri, headers: _headers);
      if (resp.statusCode != 200) return [];
      
      final exp = RegExp(r'<a href="([^"]+)".*?>\s*(?:Chapter\s*)?([^<]+)\s*</a>', caseSensitive: false);
      final matches = exp.allMatches(resp.body);
      
      return matches.map((m) {
        return ChapterItem(
          id: m.group(1) ?? '',
          chapter: m.group(2)?.trim() ?? '0',
          title: m.group(2)?.trim(),
          pageCount: 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ChapterPages?> getChapterPages(String chapterId,
      {bool dataSaver = false}) async {
    try {
      final uri = Uri.parse(chapterId);
      final resp = await RobustHttpClient.get(uri, headers: _headers);
      if (resp.statusCode != 200) return null;
      
      final exp = RegExp(r'data-src="([^"]+)"|src="([^"]+)"', caseSensitive: false);
      final lines = resp.body.split('\n');
      List<String> urls = [];
      
      bool readingBlock = false;
      for (final line in lines) {
        if (line.contains('reading-content')) readingBlock = true;
        if (readingBlock && line.contains('</div>') && !line.contains('page-break')) break;
        if (readingBlock) {
          final m = exp.firstMatch(line);
          if (m != null) {
            String url = m.group(1) ?? m.group(2) ?? '';
            if (url.startsWith('//')) url = 'https:$url';
            if (url.isNotEmpty && !urls.contains(url)) urls.add(url.trim());
          }
        }
      }
      return ChapterPages(chapterId: chapterId, pageUrls: urls);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TagItem>> getTags() async {
    return [
      TagItem(id: 'action', name: 'Action', group: 'genre'),
      TagItem(id: 'adult', name: 'Adult', group: 'genre'),
      TagItem(id: 'smut', name: 'Smut', group: 'genre'),
      TagItem(id: 'mature', name: 'Mature', group: 'genre'),
      TagItem(id: 'harem', name: 'Harem', group: 'genre'),
      TagItem(id: 'romance', name: 'Romance', group: 'genre'),
    ];
  }

  List<MangaItem> _regexScrapeMangaList(String html) {
    List<MangaItem> items = [];
    final itemExp = RegExp(r'<div class="page-item-detail[^>]*>([\s\S]*?)</div><!--', caseSensitive: false);
    final linkExp = RegExp(r'<a href="([^"]+)" title="([^"]+)">');
    final imgExp = RegExp(r'src="([^"]+)"');

    for (final block in itemExp.allMatches(html)) {
      final content = block.group(1) ?? '';
      final lMatch = linkExp.firstMatch(content);
      final iMatch = imgExp.firstMatch(content);
      
      if (lMatch != null) {
        String url = lMatch.group(1) ?? '';
        String title = lMatch.group(2) ?? 'Unknown';
        String img = iMatch?.group(1) ?? '';
        if (img.startsWith('//')) img = 'https:$img';
        
        items.add(MangaItem(
          id: url,
          title: title,
          description: '',
          externalCoverUrl: img,
          status: 'ongoing',
          contentRating: isAdult ? 'pornographic' : 'safe',
          tags: isAdult ? ['adult', 'mature'] : [],
          availableLanguages: const ['en'],
        ));
      }
    }
    return items;
  }
}


