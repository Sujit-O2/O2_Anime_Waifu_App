import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('Testing AnimeDex API...');
  try {
    final q = Uri.encodeQueryComponent('Demon Slayer');
    final s = await http.get(Uri.parse('https://api.animedex.org/search?query=$q'));
    print('Search HTTP: ${s.statusCode}');
    if (s.statusCode == 200) {
      final res = jsonDecode(s.body)['results'];
      if (res.isNotEmpty) {
        final id = res[0]['id'];
        print('Found ID: $id');
        
        final e = await http.get(Uri.parse('https://api.animedex.org/anime/$id'));
        print('Episodes HTTP: ${e.statusCode}');
        if (e.statusCode == 200) {
          final eps = jsonDecode(e.body)['results']['episodes'];
          if (eps.isNotEmpty) {
            final epId = eps[0][1]; // usually [number, id]
            print('Episode ID: $epId');
            
            final stream = await http.get(Uri.parse('https://api.animedex.org/episode/$epId'));
            print('Stream HTTP: ${stream.statusCode}');
            if (stream.statusCode == 200) {
              print('Sources: ${jsonDecode(stream.body)['results']['stream']['sources']}');
            }
          }
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
