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
      // Remove surrounding quotes
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      return value;
    }
  }
  return null;
}

Future<void> testMusic(String key) async {
  print('\n═══════════════════════════════════');
  print('  TEST 1: MUSIC GENERATION');
  print('═══════════════════════════════════');

  final res = await http
      .post(
        Uri.parse('https://api.replicate.com/v1/models/meta/musicgen/predictions'),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'input': {
            'prompt': 'Lo-fi chill beats, anime style',
            'duration': 5,
            'model_version': 'stereo-large',
            'output_format': 'mp3',
            'normalization_strategy': 'peak',
          },
        }),
      )
      .timeout(const Duration(seconds: 20));

  if (res.statusCode == 201) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final id = data['id'] as String?;
    final pollUrl = data['urls']?['get'] as String?;
    print('✅ Prediction created! ID: $id');
    if (pollUrl == null) {
      print('❌ No poll URL');
      return;
    }
    print('Polling...');
    for (int i = 0; i < 90; i++) {
      await Future.delayed(const Duration(seconds: 3));
      final pollRes = await http.get(Uri.parse(pollUrl),
          headers: {'Authorization': 'Bearer $key'});
      if (pollRes.statusCode == 200) {
        final pd = jsonDecode(pollRes.body) as Map<String, dynamic>;
        final status = pd['status'] as String?;
        stdout.write('\r  Status: $status (${i * 3}s elapsed)');
        if (status == 'succeeded') {
          final output = pd['output'];
          final url = output is List ? output.first.toString() : output.toString();
          print('\n✅ MUSIC SUCCESS! Audio URL: $url');
          return;
        }
        if (status == 'failed') {
          print('\n❌ Failed: ${pd['error']}');
          return;
        }
      }
    }
    print('\n❌ Timed out');
  } else {
    print('❌ Failed (${res.statusCode}): ${res.body}');
  }
}

Future<void> testVideo(String key) async {
  print('\n═══════════════════════════════════');
  print('  TEST 2: VIDEO GENERATION');
  print('═══════════════════════════════════');

  final res = await http
      .post(
        Uri.parse(
            'https://api.replicate.com/v1/models/anotherjesse/zeroscope-v2-xl/predictions'),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'input': {
            'prompt': 'Anime girl walking through cherry blossoms',
            'num_frames': 24,
            'fps': 8,
            'width': 576,
            'height': 320,
            'num_inference_steps': 10,
            'guidance_scale': 17.5,
          },
        }),
      )
      .timeout(const Duration(seconds: 30));

  if (res.statusCode == 201) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final id = data['id'] as String?;
    final pollUrl =
        'https://api.replicate.com/v1/predictions/${id ?? 'unknown'}';
    print('✅ Prediction created! ID: $id');
    print('Polling...');
    for (int i = 0; i < 100; i++) {
      await Future.delayed(const Duration(seconds: 3));
      final pollRes = await http.get(Uri.parse(pollUrl),
          headers: {'Authorization': 'Bearer $key'});
      if (pollRes.statusCode == 200) {
        final pd = jsonDecode(pollRes.body) as Map<String, dynamic>;
        final status = pd['status'] as String?;
        stdout.write('\r  Status: $status (${i * 3}s elapsed)');
        if (status == 'succeeded') {
          final output = pd['output'];
          final url = output is List ? output.first.toString() : output.toString();
          print('\n✅ VIDEO SUCCESS! Video URL: $url');
          return;
        }
        if (status == 'failed' || status == 'canceled') {
          print('\n❌ Failed: ${pd['error']}');
          return;
        }
      }
    }
    print('\n❌ Timed out');
  } else {
    print('❌ Failed (${res.statusCode}): ${res.body}');
  }
}

Future<void> main() async {
  final keyRaw = getEnvVar('REPLICATE_API_KEY');
  if (keyRaw == null || keyRaw.isEmpty || keyRaw == 'r8_YOUR_KEY_HERE') {
    print('❌ REPLICATE_API_KEY not found or placeholder in .env');
    exit(1);
  }

  final keys = keyRaw.split(',').map((e) => e.trim()).toList();
  print('Found ${keys.length} Replicate key(s)');
  print('Using: ${keys.first.substring(0, 10)}...');

  final key = keys.first;

  try {
    await testMusic(key);
  } catch (e) {
    print('\n❌ Music test error: $e');
  }

  try {
    await testVideo(key);
  } catch (e) {
    print('\n❌ Video test error: $e');
  }

  print('\n═══════════════════════════════════');
  print('  TESTS COMPLETE');
  print('═══════════════════════════════════');
}
