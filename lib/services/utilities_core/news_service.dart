import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static const List<String> _fallbackHeadlines = [
    '- Keep showing up for the people and projects that matter to you.',
    '- Protect your focus by finishing one meaningful task before chasing the next.',
    '- Small habits compound faster than dramatic one-day bursts.',
    '- Rest is part of good performance, not the opposite of it.',
    '- Reach out to one person today and make their day lighter.',
  ];

  /// Fetches top headlines from a free mock NewsAPI endpoint (no key required).
  static Future<String?> getTopHeadlines() async {
    try {
      final uri = Uri.parse(
          'https://saurav.tech/NewsAPI/top-headlines/category/general/us.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final articles = data['articles'] as List;

        if (articles.isEmpty) return null;

        // Take top 5 news articles
        final top5 = articles.take(5).map((a) {
          final title = a['title'] ?? 'No title';
          final source = a['source']?['name'] ?? 'Unknown';
          return '• $title ($source)';
        }).join('\n');

        return top5;
      }
    } catch (_) {}
    return _fallbackHeadlines.join('\n');
  }
}


