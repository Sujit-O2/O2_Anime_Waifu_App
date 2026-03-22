import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final host = 'https://aniwatch-api-five.vercel.app';
  final q = Uri.encodeQueryComponent('Naruto');
  
  try {
    final r = await http.get(Uri.parse('$host/anime/search?q=$q'));
    final animes = jsonDecode(r.body)['animes'] as List;
    final h = animes[0]['id'];
    print('Found Anime: ${animes[0]['name']} (ID: $h)');
    
    final r2 = await http.get(Uri.parse('$host/anime/episodes/$h'));
    final e = jsonDecode(r2.body)['episodes'][0]['episodeId'];
    print('Episode ID: $e');
    
    final sName = 'megacloud';
    final url = '$host/anime/episode-srcs?id=$e&server=$sName&category=sub';
    final r4 = await http.get(Uri.parse(url));
    
    print('Stream HTTP: ${r4.statusCode}');
    if (r4.statusCode == 200) {
      final l = jsonDecode(r4.body);
      print('Sources: ${l['sources']}');
    } else {
      print('Failed body: ${r4.body}');
    }
  } catch(e) {
    print('Error: $e');
  }
}
