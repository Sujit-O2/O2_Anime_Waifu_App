import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final host = 'https://aniwatch-api-five.vercel.app';
  final q = Uri.encodeQueryComponent('Demon Slayer');
  
  try {
    final r = await http.get(Uri.parse('$host/anime/search?q=$q'));
    final h = jsonDecode(r.body)['animes'][0]['id'];
    print('Found Anime ID: $h');
    
    final r2 = await http.get(Uri.parse('$host/anime/episodes/$h'));
    final e = jsonDecode(r2.body)['episodes'][0]['episodeId'];
    print('Found Episode ID: $e');
    
    final r3 = await http.get(Uri.parse('$host/anime/servers?episodeId=$e'));
    final servers = jsonDecode(r3.body)['sub'] as List;
    print('Available Servers: ${servers.map((s) => s['serverName']).toList()}');
    
    for (final s in servers) {
      final sName = s['serverName'];
      print('\nTesting server: $sName');
      final url = '$host/anime/episode-srcs?id=$e&server=$sName&category=sub';
      final r4 = await http.get(Uri.parse(url));
      final l = jsonDecode(r4.body);
      
      print('Response HTTP: ${r4.statusCode}');
      print('Sources: ${l['sources']}');
      print('Headers: ${l['headers']}');
    }
  } catch(e) {
    print('Error: $e');
  }
}
