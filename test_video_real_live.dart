import 'dart:io';
import 'dart:convert';

void main() async {
  print('--- CINETARO EMBED TEST ---');
  try {
    // 154587 is Frieren MAL ID
    final uri = Uri.parse('https://api.cinetaro.buzz/anime/154587/1/1/sub');
    final req = await HttpClient().getUrl(uri);
    final res = await req.close();
    print('Cinetaro HTTP Status: ${res.statusCode}');
    final b = await res.transform(utf8.decoder).join();
    print('Cinetaro HTML Length: ${b.length} bytes');
    print('Cinetaro HTML Snippet: ${b.substring(0, 50)}');
  } catch (e) {
    print('Cinetaro Crash: $e');
  }

  print('\n--- HIANIME M3U8 API TEST ---');
  try {
    final uri = Uri.parse('https://aniwatch-api-production.up.railway.app/anime/episodes/steins-gate-3');
    final req = await HttpClient().getUrl(uri);
    final res = await req.close();
    print('HiAnime HTTP Status: ${res.statusCode}');
  } catch (e) {
    print('HiAnime Crash: $e');
  }
  
  print('\n--- HENTAI API (HTV) TEST ---');
  try {
    final uri = Uri.parse('https://htv-app-server-v3.2.0.2.vercel.app/api/videos/search?search_text=milf');
    final req = await HttpClient().getUrl(uri);
    final res = await req.close();
    print('Hentai API HTTP Status: ${res.statusCode}');
  } catch (e) {
    print('Hentai API Crash: $e');
  }

  exit(0);
}
