import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VideoGenResult {
  final String videoUrl;
  final String prompt;
  final String provider;
  final DateTime createdAt;

  const VideoGenResult({
    required this.videoUrl,
    required this.prompt,
    required this.provider,
    required this.createdAt,
  });
}

/// AI Video Generation Service — HuggingFace Inference Providers (fal-ai).
///
/// Model: Lightricks/LTX-Video (fast, free tier via fal-ai provider)
///
/// .env:
///   HF_API_KEY = "hf_your_token"
///
/// Token MUST have "Make calls to Inference Providers" scope:
///   https://huggingface.co/settings/tokens/new?ownUserPermissions=inference.serverless.write&tokenType=fineGrained
class VideoGenService {
  VideoGenService._();
  static final VideoGenService instance = VideoGenService._();

  // fal-ai provider via HF router — Wan2.1 T2V 1.3B (fast & free tier)
  static const _hfUrl =
      'https://router.huggingface.co/fal-ai/fal-ai/wan/v2.1/1.3b/text-to-video';

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

  Future<VideoGenResult> generate({required String prompt}) async {
    final keys = _keys();
    if (keys.isEmpty) {
      throw const VideoGenException(
          'No HuggingFace API key found. Add HF_API_KEY to .env\n'
          'Get a token with Inference Providers scope:\n'
          'https://huggingface.co/settings/tokens/new?ownUserPermissions=inference.serverless.write&tokenType=fineGrained');
    }

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      if (kDebugMode) debugPrint('[VideoGen] Trying key ${i + 1}/${keys.length}');

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
            .timeout(const Duration(minutes: 5));

        if (kDebugMode) debugPrint('[VideoGen] Status: ${res.statusCode}');

        if (res.statusCode == 429 && i < keys.length - 1) continue;
        if (res.statusCode == 401) {
          throw const VideoGenException(
              'HuggingFace token invalid or missing "Inference Providers" scope.\n'
              'Generate a new token at:\n'
              'https://huggingface.co/settings/tokens/new?ownUserPermissions=inference.serverless.write&tokenType=fineGrained');
        }
        if (res.statusCode != 200) {
          if (i < keys.length - 1) continue;
          throw VideoGenException(_parseError(res.statusCode, res.body));
        }

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/videogen_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await file.writeAsBytes(res.bodyBytes);
        return VideoGenResult(
          videoUrl: file.path,
          prompt: prompt,
          provider: 'fal-ai/wan2.1-t2v',
          createdAt: DateTime.now(),
        );
      } on TimeoutException {
        if (i < keys.length - 1) continue;
        throw const VideoGenException('Request timed out. Try again.');
      }
    }
    throw const VideoGenException('All keys exhausted. Try again later.');
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

class VideoGenException implements Exception {
  final String message;
  const VideoGenException(this.message);
  @override
  String toString() => message;
}
