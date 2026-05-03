import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');

  final repKeys = (dotenv.env['REPLICATE_API_KEY'] ?? '')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty && e != 'r8_YOUR_KEY_HERE')
      .toList();

  if (repKeys.isEmpty) {
    print('NO REPLICATE_API_KEY found in .env');
    exit(1);
  }
  final testKey = repKeys.first;
  print('Testing Replicate key: ${testKey.substring(0, 10)}...');
  print('');

  // ── TEST 1: Music Generation ──
  print('═══════════════════════════════════');
  print('  TEST 1: MUSIC GENERATION');
  print('═══════════════════════════════════');
  try {
    final createRes = await http
        .post(
          Uri.parse('https://api.replicate.com/v1/models/meta/musicgen/predictions'),
          headers: {
            'Authorization': 'Bearer $testKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'input': {
              'prompt': 'Lo-fi chill beats, anime style, 15 seconds',
              'duration': 5,
              'model_version': 'stereo-large',
              'output_format': 'mp3',
              'normalization_strategy': 'peak',
            },
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (createRes.statusCode == 201) {
      final data = jsonDecode(createRes.body) as Map<String, dynamic>;
      final id = data['id'] as String?;
      final pollUrl = data['urls']?['get'] as String?;
      print('✅ Prediction created! ID: $id');
      print('Polling for result...');

      if (pollUrl != null) {
        for (int i = 0; i < 90; i++) {
          await Future.delayed(const Duration(seconds: 3));
          final pollRes = await http.get(Uri.parse(pollUrl),
              headers: {'Authorization': 'Bearer $testKey'});
          if (pollRes.statusCode == 200) {
            final pollData = jsonDecode(pollRes.body) as Map<String, dynamic>;
            final status = pollData['status'] as String?;
            stdout.write('\r  Status: $status (${i * 3}s elapsed)');
            if (status == 'succeeded') {
              final output = pollData['output'];
              final audioUrl = output is List ? output.first.toString() : output.toString();
              print('\n✅ MUSIC SUCCESS! URL: $audioUrl');
              break;
            }
            if (status == 'failed') {
              print('\n❌ Music failed: ${pollData['error']}');
              break;
            }
          }
        }
        print('');
      }
    } else {
      print('❌ Music create failed (${createRes.statusCode}): ${createRes.body}');
    }
  } catch (e) {
    print('❌ Music error: $e');
  }

  print('');

  // ── TEST 2: Video Generation ──
  print('═══════════════════════════════════');
  print('  TEST 2: VIDEO GENERATION');
  print('═══════════════════════════════════');
  try {
    final createRes = await http
        .post(
          Uri.parse(
              'https://api.replicate.com/v1/models/anotherjesse/zeroscope-v2-xl/predictions'),
          headers: {
            'Authorization': 'Bearer $testKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'input': {
              'prompt': 'Anime girl walking through cherry blossoms, cinematic',
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

    if (createRes.statusCode == 201) {
      final data = jsonDecode(createRes.body) as Map<String, dynamic>;
      final id = data['id'] as String?;
      final pollUrl = 'https://api.replicate.com/v1/predictions/$id';
      print('✅ Prediction created! ID: $id');
      print('Polling for result...');

      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(seconds: 3));
        final pollRes = await http.get(Uri.parse(pollUrl),
            headers: {'Authorization': 'Bearer $testKey'});
        if (pollRes.statusCode == 200) {
          final pollData = jsonDecode(pollRes.body) as Map<String, dynamic>;
          final status = pollData['status'] as String?;
          stdout.write('\r  Status: $status (${i * 3}s elapsed)');
          if (status == 'succeeded') {
            final output = pollData['output'];
            final videoUrl = output is List ? output.first.toString() : output.toString();
            print('\n✅ VIDEO SUCCESS! URL: $videoUrl');
            break;
          }
          if (status == 'failed' || status == 'canceled') {
            print('\n❌ Video failed: ${pollData['error']}');
            break;
          }
        }
      }
      print('');
    } else {
      print('❌ Video create failed (${createRes.statusCode}): ${createRes.body}');
    }
  } catch (e) {
    print('❌ Video error: $e');
  }

  print('');
  print('═══════════════════════════════════');
  print('  TESTS COMPLETE');
  print('═══════════════════════════════════');
  exit(0);
}
