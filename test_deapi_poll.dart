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

Future<void> main() async {
  final key = getEnvVar('DEAPI_API_KEY')!;
  const reqId = '3cc5c39e-3510-48c2-be46-0102e24967dc';

  print('Polling status for: $reqId\n');
  for (int i = 0; i < 30; i++) {
    final res = await http.get(
      Uri.parse('https://api.deapi.ai/api/v1/request-status/$reqId'),
      headers: {'Authorization': 'Bearer $key'},
    ).timeout(const Duration(seconds: 15));

    print('[$i] ${res.statusCode}: ${res.body.substring(0, res.body.length > 400 ? 400 : res.body.length)}');

    if (res.statusCode == 200) {
      final raw = jsonDecode(res.body) as Map<String, dynamic>;
      final data = raw['data'] ?? raw;
      final status = (data['status'] ?? data['state'] ?? '').toString().toUpperCase();
      print('  → Parsed status: "$status"');
      if (status == 'COMPLETED' || status == 'SUCCEEDED' || status == 'SUCCESS' || status == 'FAILED' || status == 'ERROR') {
        break;
      }
    }
    await Future.delayed(const Duration(seconds: 10));
  }
}
