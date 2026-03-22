import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('Testing consumet zoro...');
  
  try {
    final search = await http.get(Uri.parse('https://consumet-xi.vercel.app/anime/zoro/naruto'));
    print('Search HTTP: ${search.statusCode}');
    if (search.statusCode != 200) return;
    
    final id = jsonDecode(search.body)['results'][0]['id'];
    print('ID: $id');
    
    final info = await http.get(Uri.parse('https://consumet-xi.vercel.app/anime/zoro/info?id=$id'));
    print('Info HTTP: ${info.statusCode}');
    if (info.statusCode != 200) {
      print('Info body: ${info.body}');
      return;
    }
    
    final epId = jsonDecode(info.body)['episodes'][0]['id'];
    print('Ep ID: $epId');
    
    final stream = await http.get(Uri.parse('https://consumet-xi.vercel.app/anime/zoro/watch?episodeId=$epId'));
    print('Stream HTTP: ${stream.statusCode}');
    if (stream.statusCode == 200) {
      print('Sources: ${jsonDecode(stream.body)['sources']}');
    } else {
      print('Stream failure: ${stream.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
