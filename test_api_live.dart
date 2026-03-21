import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Test 1: Hanime search
  print('=== TEST HANIME ===');
  try {
    final r = await http.post(
      Uri.parse('https://search.htv-services.com/'),
      headers: {'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'},
      body: jsonEncode({
        'search_text': '', 'tags': [], 'tags_mode': 'AND',
        'brands': [], 'blacklist': [], 'order_by': 'trending',
        'ordering': 'desc', 'page': 0,
      }),
    ).timeout(const Duration(seconds: 15));
    print('Status: ${r.statusCode}');
    if (r.statusCode == 200) {
      final j = jsonDecode(r.body);
      final h = j['hits'] as List;
      print('✅ Hanime ALIVE! ${h.length} results');
      if (h.isNotEmpty) {
        print('First: ${h[0]['name']} (slug: ${h[0]['slug']})');
        
        // Test video
        final slug = h[0]['slug'];
        print('\nTesting video for $slug...');
        final vr = await http.get(
          Uri.parse('https://hanime.tv/api/v8/video?id=$slug'),
          headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 15));
        print('Video API status: ${vr.statusCode}');
        if (vr.statusCode == 200) {
          final vj = jsonDecode(vr.body);
          final servers = vj['videos_manifest']?['servers'] as List? ?? [];
          int count = 0;
          for (final sv in servers) {
            for (final st in (sv['streams'] as List? ?? [])) {
              final url = st['url']?.toString() ?? '';
              if (url.isNotEmpty) {
                count++;
                if (count <= 3) print('🎬 STREAM: $url');
              }
            }
          }
          print('✅ Got $count video streams!');
        }
      }
    }
  } catch (e) {
    print('❌ Hanime error: $e');
  }

  // Test 2: Jikan
  print('\n=== TEST JIKAN ===');
  try {
    final r = await http.get(
      Uri.parse('https://api.jikan.moe/v4/top/anime?filter=airing&limit=3'),
    ).timeout(const Duration(seconds: 10));
    print('Jikan status: ${r.statusCode}');
    if (r.statusCode == 200) {
      final j = jsonDecode(r.body);
      final d = j['data'] as List;
      print('✅ Jikan ALIVE! Top: ${d[0]['title']}');
    }
  } catch (e) {
    print('❌ Jikan error: $e');
  }

  // Test 3: AniWatch API instances
  print('\n=== TEST ANIWATCH HOSTS ===');
  final hosts = [
    'https://aniwatch-api-dusky.vercel.app',
    'https://aniwatch-api-gamma.vercel.app',
    'https://api-aniwatch.onrender.com',
    'https://aniwatch-api-production.up.railway.app',
    'https://aniwatch-api-five.vercel.app',
    'https://aniwatch-api-v2.vercel.app',
  ];
  for (final host in hosts) {
    try {
      print('Testing $host ...');
      final r = await http.get(
        Uri.parse('$host/anime/search?q=naruto'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 12));
      print('  Status: ${r.statusCode}');
      if (r.statusCode == 200) {
        print('  ✅ WORKING!');
        break;
      }
    } catch (e) {
      print('  ❌ $e');
    }
  }
}
