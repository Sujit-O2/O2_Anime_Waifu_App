import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('Testing consumet-xi.vercel.app for GogoAnime...');
  final host = 'https://consumet-xi.vercel.app/meta/anilist';
  
  try {
    // Search
    final q = Uri.encodeQueryComponent('Demon Slayer');
    final search = await http.get(Uri.parse('$host/$q'));
    print('Search HTTP: ${search.statusCode}');
    if (search.statusCode != 200) return;
    
    final results = jsonDecode(search.body)['results'] as List;
    print('Found: ${results[0]['title']} (ID: ${results[0]['id']})');
    final id = results[0]['id'];
    
    // Episodes
    final info = await http.get(Uri.parse('$host/info/$id?provider=gogoanime'));
    print('Info HTTP: ${info.statusCode}');
    if (info.statusCode != 200) return;
    
    final episodes = jsonDecode(info.body)['episodes'] as List;
    final epId = episodes[0]['id'];
    print('Episode ID: $epId');
    
    // Video Stream
    final stream = await http.get(Uri.parse('$host/watch/$epId'));
    print('Stream HTTP: ${stream.statusCode}');
    if (stream.statusCode == 200) {
      final data = jsonDecode(stream.body);
      final sources = data['sources'] as List;
      print('Sources: $sources');
    } else {
      print('Stream body: ${stream.body}');
    }
    
    print('\nTesting consumet-xi.vercel.app direct Gogoanime...');
    final dSearch = await http.get(Uri.parse('https://consumet-xi.vercel.app/anime/gogoanime/$q'));
    print('Direct Search: ${dSearch.statusCode}');
    if (dSearch.statusCode == 200) {
      final res = jsonDecode(dSearch.body)['results'] as List;
      final dId = res[0]['id'];
      print('Direct ID: $dId');
      final dEps = await http.get(Uri.parse('https://consumet-xi.vercel.app/anime/gogoanime/info/$dId'));
      final dEpId = jsonDecode(dEps.body)['episodes'][0]['id'];
      print('Direct Ep ID: $dEpId');
      final dStream = await http.get(Uri.parse('https://consumet-xi.vercel.app/anime/gogoanime/watch/$dEpId'));
      print('Direct Stream: ${dStream.statusCode}');
      if (dStream.statusCode == 200) {
        print('Direct Sources: ${jsonDecode(dStream.body)['sources']}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
