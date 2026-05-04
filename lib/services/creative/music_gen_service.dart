import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MusicGenResult {
  final String audioUrl;
  final String prompt;
  final String provider;
  final DateTime createdAt;

  const MusicGenResult({
    required this.audioUrl,
    required this.prompt,
    required this.provider,
    required this.createdAt,
  });
}

/// AI Music Generation Service — HuggingFace Inference Providers (fal-ai).
///
/// Model: fal-ai/stable-audio (free tier via fal-ai provider)
///
/// .env:
///   HF_API_KEY = "hf_your_token"
///
/// Token MUST have "Make calls to Inference Providers" scope:
///   https://huggingface.co/settings/tokens/new?ownUserPermissions=inference.serverless.write&tokenType=fineGrained
class MusicGenService {
  MusicGenService._();
  static final MusicGenService instance = MusicGenService._();

  // fal-ai provider via HF router — Kokoro TTS (fast, free tier)
  static const _hfUrl =
      'https://router.huggingface.co/fal-ai/fal-ai/kokoro/american-english';

  List<String> _keys() {
    try {
      return (dotenv.env['HF_API_KEY'] ?? '')
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty && !k.contains('YOUR_'))
          .toList()
        ..shuffle();
    } catch (_) {
      return [];
    }
  }

  Future<MusicGenResult> generate({required String prompt}) async {
    final keys = _keys();
    if (keys.isEmpty) {
      throw const MusicGenException(
          'No HuggingFace API key found. Add HF_API_KEY to .env\n'
          'Get a token with Inference Providers scope:\n'
          'https://huggingface.co/settings/tokens/new?ownUserPermissions=inference.serverless.write&tokenType=fineGrained');
    }

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      if (kDebugMode) debugPrint('[MusicGen] Trying key ${i + 1}/${keys.length}');

      try {
        final res = await http
            .post(
              Uri.parse(_hfUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $key',
              },
              body: jsonEncode({'prompt': prompt}),
            )
            .timeout(const Duration(minutes: 3));

        if (kDebugMode) debugPrint('[MusicGen] Status: ${res.statusCode}');

        if (res.statusCode == 429 && i < keys.length - 1) continue;
        if (res.statusCode == 401) {
          throw const MusicGenException(
              'HuggingFace token invalid or missing "Inference Providers" scope.\n'
              'Generate a new token at:\n'
              'https://huggingface.co/settings/tokens/new?ownUserPermissions=inference.serverless.write&tokenType=fineGrained');
        }
        if (res.statusCode != 200) {
          if (i < keys.length - 1) continue;
          throw MusicGenException(_parseError(res.statusCode, res.body));
        }

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/musicgen_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await file.writeAsBytes(res.bodyBytes);
        return MusicGenResult(
          audioUrl: file.path,
          prompt: prompt,
          provider: 'fal-ai/kokoro',
          createdAt: DateTime.now(),
        );
      } on TimeoutException {
        if (i < keys.length - 1) continue;
        throw const MusicGenException('Request timed out. Try again.');
      }
    }
    throw const MusicGenException('All keys exhausted. Try again later.');
  }

  String _parseError(int status, String body) {
    try {
      final msg = (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ?? body;
      return 'Error ($status): ${msg.length > 120 ? '${msg.substring(0, 120)}…' : msg}';
    } catch (_) {
      return 'Error ($status)';
    }
  }
}

class MusicGenException implements Exception {
  final String message;
  const MusicGenException(this.message);
  @override
  String toString() => message;
}
