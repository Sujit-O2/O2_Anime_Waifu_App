import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('Testing amvstrm API...');
  final host = 'https://api.amvstr.me';
  
  try {
    // Search
    final q = Uri.encodeQueryComponent('Demon Slayer');
    final search = await http.get(Uri.parse('$host/api/v2/search?q=$q'));
    final results = jsonDecode(search.body)['results'] as List;
    print('Found: ${results[0]['title']} (ID: ${results[0]['id']})');
    
    final id = results[0]['id'];
    
    // Get Episodes
    final eps = await http.get(Uri.parse('$host/api/v2/info/$id'));
    final episodes = jsonDecode(eps.body)['episodes'] as List;
    print('Found episodes: ${episodes.length}');
    
    final epId = episodes[0]['id'];
    print('Episode ID: $epId');
    
    // Get Stream URL
    final stream = await http.get(Uri.parse('$host/api/v2/stream/$epId'));
    print('Stream status: ${stream.statusCode}');
    if (stream.statusCode == 200) {
      final data = jsonDecode(stream.body);
      print('Stream URL: ${data['stream']['multi']['main']['url']}');
    } else {
      print('Stream body: ${stream.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
