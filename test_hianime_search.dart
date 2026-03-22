import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final hosts = [
    'https://aniwatch-api-five.vercel.app',
    'https://aniwatch-api-production.up.railway.app',
    'https://api-aniwatch.onrender.com',
  ];

  // Test Jikan Romaji title vs HiAnime Search
  const titlesToTest = [
    'Naruto',
    'Shingeki no Kyojin', // Attack on Titan
    'Kimetsu no Yaiba', // Demon Slayer
    'Boku no Hero Academia', // My Hero Academia
  ];

  for (final title in titlesToTest) {
    print('\nSearching HiAnime for: "$title"');
    bool found = false;
    for (final host in hosts) {
      if (found) break;
      try {
        final q = Uri.encodeQueryComponent(title);
        final resp = await http.get(Uri.parse('$host/anime/search?q=$q'));
        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body);
          final animes = json['animes'] as List? ?? [];
          if (animes.isNotEmpty) {
            print('  ✅ Found: ${animes[0]['name']} (ID: ${animes[0]['id']})');
            found = true;
          } else {
            print('  ❌ No results found on $host');
          }
        }
      } catch (e) {
        print('  ⚠️ Error on $host: $e');
      }
    }
    if (!found) {
      print('  🚨 FAILED TO FIND "$title" ON ALL HOSTS!');
    }
  }
}
