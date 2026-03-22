import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../../models/manga_models.dart';
import 'manga_provider.dart';

class RawManhwaProvider implements MangaProvider {
  static const String _baseUrl = 'https://toonily.com';
  
  Map<String, String> get _headers => {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Referer': _baseUrl,
      };

  @override
  String get name => 'Toonily (Adult Manhwa)';

  @override
  Future<List<MangaItem>> searchManga(String title, {int limit = 20}) async {
    try {
      final uri = Uri.parse('$_baseUrl/?s=${Uri.encodeComponent(title)}&post_type=wp-manga');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      return _parseMadaraList(resp.body);
    } catch (_) { return []; }
  }

  @override
  Future<List<MangaItem>> getTrending({int limit = 20}) async {
    try {
      final uri = Uri.parse('$_baseUrl/webtoon/'); // Main listing page
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      return _parseMadaraList(resp.body);
    } catch (_) { return []; }
  }

  @override
  Future<List<MangaItem>> getByTag(String tagId, {int limit = 20}) async {
    try {
      // Toonily uses /webtoon-genre/slug/
      final uri = Uri.parse('$_baseUrl/webtoon-genre/\$tagId/');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      return _parseMadaraList(resp.body);
    } catch (_) { return []; }
  }

  @override
  @override
  Future<List<ChapterItem>> getChapters(String mangaId, {String lang = 'en', int limit = 100, int offset = 0}) async {
    try {
      // For Madara themes, mangaId is usually the URL path like 'webtoon/secret-class'
      // Or we can just send a POST to admin-ajax.php if needed, but often chapters are in the DOM.
      final uri = Uri.parse(mangaId.startsWith('http') ? mangaId : '$_baseUrl/$mangaId');
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      
      final doc = parse(resp.body);
      final chapterNodes = doc.querySelectorAll('.wp-manga-chapter');
      List<ChapterItem> chapters = [];
      
      for (var node in chapterNodes) {
        final aTag = node.querySelector('a');
        if (aTag == null) continue;
        
        final url = aTag.attributes['href'] ?? '';
        final title = aTag.text.trim();
        final dateTag = node.querySelector('.chapter-release-date');
        final date = dateTag != null ? dateTag.text.trim() : '';
        
        // Extract chapter number from title (e.g., "Chapter 123")
        final match = RegExp(r'Chapter\s+([\d\.]+)').firstMatch(title);
        final chNum = match?.group(1);
        
        chapters.add(ChapterItem(
          id: url, // For scraper, URL is the ID
          chapter: chNum,
          title: title,
          publishedAt: date,
          pageCount: 0, // Unknown until fetched
        ));
      }
      return chapters;
    } catch (_) { return []; }
  }

  @override
  Future<ChapterPages?> getChapterPages(String chapterId, {bool dataSaver = false}) async {
    try {
      // chapterId is the direct URL to the chapter page
      final uri = Uri.parse(chapterId);
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      
      final doc = parse(resp.body);
      final imageNodes = doc.querySelectorAll('.reading-content img');
      List<String> pageUrls = [];
      
      for (var img in imageNodes) {
        String? src = img.attributes['data-src'] ?? img.attributes['src'];
        if (src != null) {
          src = src.trim();
          if (src.startsWith('//')) src = 'https:$src';
          pageUrls.add(src);
        }
      }
      return ChapterPages(chapterId: chapterId, pageUrls: pageUrls);
    } catch (_) { return null; }
  }

  @override
  Future<List<TagItem>> getTags() async => [];

  Future<List<MangaItem>> _parseMadaraList(String htmlContent) async {
    final doc = parse(htmlContent);
    final nodes = doc.querySelectorAll('.col-6.col-sm-3.col-md-2, .manga-item, .page-item-detail');
    List<MangaItem> items = [];
    
    for (var node in nodes) {
      final aTag = node.querySelector('.post-title a') ?? node.querySelector('h3 a') ?? node.querySelector('.manga-name a') ?? node.querySelector('a');
      final imgTag = node.querySelector('img');
      if (aTag == null || imgTag == null) continue;
      
      final title = aTag.text.trim();
      final link = aTag.attributes['href'] ?? '';
      String? coverUrl = imgTag.attributes['data-src'] ?? imgTag.attributes['src'];
      if (coverUrl != null && coverUrl.startsWith('//')) coverUrl = 'https:$coverUrl';
      
      // Extract the path as standard ID
      String id = link;
      if (link.startsWith(_baseUrl)) {
        id = link.replaceFirst(_baseUrl, '');
      }
      if (id.startsWith('/')) id = id.substring(1);
      
      items.add(MangaItem(
        id: id,
        title: title,
        description: '',
        status: 'unknown',
        contentRating: 'pornographic',
        tags: ['Adult', 'Manhwa'],
        availableLanguages: ['en'],
        externalCoverUrl: coverUrl,
      ));
    }
    return items;
  }
}
