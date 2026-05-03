import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

String? getEnvVar(String key) {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('ERROR: .env file not found');
    exit(1);
  }
  final content = envFile.readAsStringSync().replaceAll('\r', '');
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#') || trimmed.isEmpty) continue;
    final idx = trimmed.indexOf('=');
    if (idx < 0) continue;
    final envKey = trimmed.substring(0, idx).trim();
    if (envKey == key) {
      var value = trimmed.substring(idx + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      return value;
    }
  }
  return null;
}

Future<void> testHfMusic() async {
  print('\n═══════════════════════════════════');
  print('  TEST 1: HUGGINGFACE MUSIC');
  print('  (100% FREE, no payment needed)');
  print('═══════════════════════════════════');

  final hfKey = getEnvVar('HF_API_KEY');
  final hasKey = hfKey != null && hfKey.isNotEmpty && hfKey != 'hf_YOUR_KEY_HERE';
  print('Auth: ${hasKey ? "HF token configured" : "anonymous (free tier)"}');

  final url = Uri.parse('https://api-inference.huggingface.co/models/facebook/musicgen-small');
  final headers = <String, String>{'Content-Type': 'application/json'};
  if (hasKey) headers['Authorization'] = 'Bearer $hfKey';

  final res = await http
      .post(url, headers: headers,
          body: jsonEncode({'inputs': 'Lo-fi chill beats, anime style, relaxing'}))
      .timeout(const Duration(minutes: 5));

  print('Status: ${res.statusCode}');

  if (res.statusCode == 503) {
    final body = jsonDecode(res.body) as Map;
    final est = body['estimated_time'];
    print('⏳ Model loading. Est: ${est ?? "?"}s. Waiting 60s...');
    await Future.delayed(const Duration(seconds: 60));
    final res2 = await http
        .post(url, headers: headers, body: jsonEncode({'inputs': 'Lo-fi chill beats'}))
        .timeout(const Duration(minutes: 5));
    print('Retry: ${res2.statusCode}');
    if (res2.statusCode == 200) {
      final file = File('/tmp/test_musicgen.mp3');
      await file.writeAsBytes(res2.bodyBytes);
      print('✅ MUSIC! /tmp/test_musicgen.mp3 (${(file.lengthSync()/1024).toStringAsFixed(1)}KB)');
    } else {
      final body2 = res2.body.length > 200 ? res2.body.substring(0, 200) : res2.body;
      print('❌ $body2');
    }
  } else if (res.statusCode == 200) {
    final file = File('/tmp/test_musicgen.mp3');
    await file.writeAsBytes(res.bodyBytes);
    print('✅ MUSIC! /tmp/test_musicgen.mp3 (${(file.lengthSync()/1024).toStringAsFixed(1)}KB)');
  } else {
    final bodyStr = res.body.length > 300 ? res.body.substring(0, 300) : res.body;
    print('❌ $bodyStr');
  }
}

Future<void> testHfVideo() async {
  print('\n═══════════════════════════════════');
  print('  TEST 2: HUGGINGFACE VIDEO');
  print('  (100% FREE, no payment needed)');
  print('═══════════════════════════════════');

  final hfKey = getEnvVar('HF_API_KEY');
  final hasKey = hfKey != null && hfKey.isNotEmpty && hfKey != 'hf_YOUR_KEY_HERE';
  print('Auth: ${hasKey ? "HF token configured" : "anonymous (free tier)"}');

  final url = Uri.parse('https://api-inference.huggingface.co/models/damo-vilab/text-to-video-ms-1.7b');
  final headers = <String, String>{'Content-Type': 'application/json'};
  if (hasKey) headers['Authorization'] = 'Bearer $hfKey';

  final res = await http
      .post(url, headers: headers,
          body: jsonEncode({'inputs': 'Anime girl walking through cherry blossoms, cinematic'}))
      .timeout(const Duration(minutes: 5));

  print('Status: ${res.statusCode}');

  if (res.statusCode == 503) {
    final body = jsonDecode(res.body) as Map;
    final est = body['estimated_time'];
    print('⏳ Model loading. Est: ${est ?? "?"}s. Waiting 90s...');
    await Future.delayed(const Duration(seconds: 90));
    final res2 = await http
        .post(url, headers: headers, body: jsonEncode({'inputs': 'Anime cherry blossoms'}))
        .timeout(const Duration(minutes: 5));
    print('Retry: ${res2.statusCode}');
    if (res2.statusCode == 200) {
      final file = File('/tmp/test_video.mp4');
      await file.writeAsBytes(res2.bodyBytes);
      print('✅ VIDEO! /tmp/test_video.mp4 (${(file.lengthSync()/1024).toStringAsFixed(1)}KB)');
    } else {
      final body2 = res2.body.length > 200 ? res2.body.substring(0, 200) : res2.body;
      print('❌ $body2');
    }
  } else if (res.statusCode == 200) {
    final file = File('/tmp/test_video.mp4');
    await file.writeAsBytes(res.bodyBytes);
    print('✅ VIDEO! /tmp/test_video.mp4 (${(file.lengthSync()/1024).toStringAsFixed(1)}KB)');
  } else {
    final bodyStr = res.body.length > 300 ? res.body.substring(0, 300) : res.body;
    print('❌ $bodyStr');
  }
}

Future<void> main() async {
  print('═══════════════════════════════════');
  print('  FREE API TEST (no billing needed)');
  print('═══════════════════════════════════');

  try { await testHfMusic(); } catch (e) { print('Music error: $e'); }
  try { await testHfVideo(); } catch (e) { print('Video error: $e'); }

  print('\n═══════════════════════════════════');
  print('  DONE');
  print('═══════════════════════════════════');
}
