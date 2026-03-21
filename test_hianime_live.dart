// LIVE TEST: Does HiAnime API actually work from India?
// dart run test_hianime_live.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

final hosts = [
  'https://aniwatch-api-dusky.vercel.app',
  'https://aniwatch-api-gamma.vercel.app',
  'https://api-aniwatch.onrender.com',
];

void main() async {
  print('═══════════════════════════════════════');
  print('  LIVE TEST: HiAnime API from India');
  print('═══════════════════════════════════════\n');

  // Test 1: Can we search anime?
  print('TEST 1: Search for "Naruto"\n');
  String? workingHost;
  String? animeId;
  
  for (final host in hosts) {
    try {
      print('  Trying: $host ...');
      final resp = await http.get(
        Uri.parse('$host/anime/search?q=naruto'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 15));
      
      print('  Status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final animes = json['animes'] as List? ?? [];
        print('  ✅ Found ${animes.length} results!');
        if (animes.isNotEmpty) {
          animeId = animes[0]['id']?.toString();
          print('  First result: ${animes[0]['name']} (id: $animeId)');
          workingHost = host;
          break;
        }
      } else {
        print('  ❌ Failed with ${resp.statusCode}');
        // Print first 200 chars of body for debugging
        print('  Body: ${resp.body.substring(0, resp.body.length.clamp(0, 200))}');
      }
    } catch (e) {
      print('  ❌ Error: $e');
    }
    print('');
  }

  if (workingHost == null || animeId == null) {
    print('\n❌ NO ANIWATCH HOSTS WORKING. Need different approach.\n');
    
    // Try Jikan as metadata test  
    print('Testing Jikan (metadata)...');
    try {
      final resp = await http.get(
        Uri.parse('https://api.jikan.moe/v4/top/anime?filter=airing&limit=3'),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final data = json['data'] as List;
        print('  ✅ Jikan works! Top anime: ${data[0]['title']}');
      }
    } catch (e) {
      print('  ❌ Jikan failed: $e');
    }

    // Try Hanime
    print('\nTesting Hanime...');
    try {
      final resp = await http.post(
        Uri.parse('https://search.htv-services.com/'),
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'},
        body: jsonEncode({
          'search_text': '', 'tags': [], 'tags_mode': 'AND',
          'brands': [], 'blacklist': [], 'order_by': 'trending',
          'ordering': 'desc', 'page': 0,
        }),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final hits = json['hits'] as List;
        print('  ✅ Hanime works! ${hits.length} trending results');
        if (hits.isNotEmpty) {
          final slug = hits[0]['slug'];
          print('  Testing video for: $slug ...');
          final vidResp = await http.get(
            Uri.parse('https://hanime.tv/api/v8/video?id=$slug'),
            headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 10));
          if (vidResp.statusCode == 200) {
            final vj = jsonDecode(vidResp.body);
            final servers = vj['videos_manifest']?['servers'] as List? ?? [];
            int streamCount = 0;
            for (final s in servers) {
              final streams = s['streams'] as List? ?? [];
              for (final st in streams) {
                if (st['url']?.toString().isNotEmpty == true) {
                  streamCount++;
                  if (streamCount <= 3) {
                    print('  🎬 Stream URL: ${st['url']}');
                  }
                }
              }
            }
            print('  ✅ Got $streamCount video streams!');
          } else {
            print('  ❌ Video API status: ${vidResp.statusCode}');
          }
        }
      } else {
        print('  ❌ Status: ${resp.statusCode}');
      }
    } catch (e) {
      print('  ❌ Hanime error: $e');
    }
    
    return;
  }

  // Test 2: Get episodes
  print('\nTEST 2: Get episodes for "$animeId"\n');
  String? episodeId;
  try {
    final resp = await http.get(
      Uri.parse('$workingHost/anime/episodes/$animeId'),
      headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(const Duration(seconds: 15));
    
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final episodes = json['episodes'] as List? ?? [];
      print('  ✅ Found ${episodes.length} episodes!');
      if (episodes.isNotEmpty) {
        episodeId = episodes[0]['episodeId']?.toString();
        print('  First episode ID: $episodeId');
      }
    } else {
      print('  ❌ Status: ${resp.statusCode}');
    }
  } catch (e) {
    print('  ❌ Error: $e');
  }

  if (episodeId == null) {
    print('\n❌ Could not get episodes.\n');
    return;
  }

  // Test 3: Get video sources
  print('\nTEST 3: Get video sources for episode "$episodeId"\n');
  try {
    // First get servers
    final serversResp = await http.get(
      Uri.parse('$workingHost/anime/servers?episodeId=$episodeId'),
      headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(const Duration(seconds: 15));
    
    if (serversResp.statusCode == 200) {
      final sj = jsonDecode(serversResp.body) as Map<String, dynamic>;
      print('  Servers response keys: ${sj.keys.toList()}');
      
      for (final cat in ['sub', 'dub', 'raw']) {
        final servers = sj[cat] as List? ?? [];
        print('  $cat servers: ${servers.length}');
        if (servers.isNotEmpty) {
          final serverName = servers[0]['serverName'];
          print('  Trying server: $serverName ...');
          
          final linksResp = await http.get(
            Uri.parse('$workingHost/anime/episode-srcs?id=$episodeId&server=$serverName&category=$cat'),
            headers: {'User-Agent': 'Mozilla/5.0'},
          ).timeout(const Duration(seconds: 20));
          
          if (linksResp.statusCode == 200) {
            final lj = jsonDecode(linksResp.body) as Map<String, dynamic>;
            final sources = lj['sources'] as List? ?? [];
            print('  ✅ GOT ${sources.length} VIDEO SOURCES!');
            for (final s in sources) {
              print('    🎬 URL: ${s['url']}');
              print('    Quality: ${s['quality']}');
              print('    isM3U8: ${s['isM3U8']}');
            }
            if (lj['headers'] != null) {
              print('  Headers: ${lj['headers']}');
            }
            print('\n  ✅✅✅ VIDEO STREAMING CONFIRMED WORKING! ✅✅✅');
            return;
          } else {
            print('  ❌ Links status: ${linksResp.statusCode}');
          }
        }
      }
    } else {
      print('  ❌ Servers status: ${serversResp.statusCode}');
    }
  } catch (e) {
    print('  ❌ Error: $e');
  }

  print('\n❌ Could not get video sources from HiAnime.');
}
