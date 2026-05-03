import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

String? getEnvVar(String key) {
  final envFile = File('.env');
  if (!envFile.existsSync()) { exit(1); }
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

Future<void> testDeApiMusic() async {
  print('\n═══════════════════════════════════');
  print('  TEST: deAPI.ai MUSIC');
  print('═══════════════════════════════════');

  final key = getEnvVar('DEAPI_API_KEY');
  if (key == null || key.isEmpty) { print('❌ No DEAPI_API_KEY'); exit(1); }
  print('Key: ${key.substring(0, 10)}...');

  final res = await http
      .post(
        Uri.parse('https://api.deapi.ai/api/v1/client/txt2music'),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'caption': 'Lo-fi chill beats, anime style',
          'model': 'AceStep_1_5_Turbo',
          'duration': 10,
          'inference_steps': 8,
          'guidance_scale': 1,
          'seed': -1,
          'format': 'mp3',
          'vocal_language': 'unknown',
          'lyrics': '[Instrumental]',
        }),
      )
      .timeout(const Duration(seconds: 30));

  print('Status: ${res.statusCode}');
  print('Body: ${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}');

  if (res.statusCode == 200 || res.statusCode == 201) {
    final raw = jsonDecode(res.body) as Map<String, dynamic>;
    final data = raw['data'] ?? raw;
    final reqId = data['request_id'] ?? data['id'];
    print('Request ID: $reqId');
    if (reqId != null) {
      print('Polling for result...');
      for (int i = 0; i < 120; i++) {
        await Future.delayed(const Duration(seconds: 3));
        final pollRes = await http.get(
          Uri.parse('https://api.deapi.ai/api/v1/request-status/$reqId'),
          headers: {'Authorization': 'Bearer $key'},
        ).timeout(const Duration(seconds: 15));
        if (pollRes.statusCode == 200) {
          final pd = jsonDecode(pollRes.body) as Map<String, dynamic>;
          final status = (pd['status'] ?? pd['state'] ?? '').toString().toUpperCase();
          stdout.write('\r  Status: $status (${i * 3}s)');
          if (status == 'COMPLETED' || status == 'SUCCEEDED' || status == 'SUCCESS') {
            final result = pd['result'] ?? pd['output'] ?? pd;
            String? url;
            if (result is String) url = result;
            if (result is Map) {
              for (final k in ['audio_url', 'url', 'audio', 'download_url']) {
                final v = result[k];
                if (v is String && v.isNotEmpty) { url = v; break; }
                if (v is List && v.isNotEmpty) { url = v.first.toString(); break; }
              }
            }
            if (url != null) {
              print('\n✅ MUSIC SUCCESS! URL: $url');
              return;
            }
            print('\n❌ No audio URL in result');
            return;
          }
          if (status == 'FAILED' || status == 'ERROR') {
            print('\n❌ Failed: ${pd['error'] ?? pd['message']}');
            return;
          }
        }
      }
      print('\n❌ Timed out');
    }
  } else {
    print('❌ Create failed');
  }
}

Future<void> main() async {
  try { await testDeApiMusic(); } catch (e) { print('Error: $e'); }
  print('\nDone');
}
