import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final url = 'https://search.htv-services.com/';
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)',
    'Content-Type': 'application/json',
  };
  final body = jsonEncode({
    'search_text': '',
    'tags': ['Uncensored'],
    'tags_mode': 'AND',
    'brands': <String>[],
    'blacklist': <String>[],
    'order_by': 'trending',
    'ordering': 'desc',
    'page': 0,
  });

  try {
    final resp = await http.post(Uri.parse(url), headers: headers, body: body);
    print('HTTP ${resp.statusCode}');
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      
      List<dynamic> hits = [];
      if (json['hits'] is String) {
        hits = jsonDecode(json['hits'] as String) as List? ?? [];
      } else if (json['hits'] is List) {
        hits = json['hits'] as List;
      }
      
      print('Hits: ${hits.length}');
      if (hits.isNotEmpty) {
        print('First hit: ${hits[0]['name']} (Slug: ${hits[0]['slug']})');
      }
    } else {
      print('Body: ${resp.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
