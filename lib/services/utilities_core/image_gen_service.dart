import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ImageGenService {
  static final Random _random = Random();

  static const List<String> _models = [
    'flux',
    'turbo',
    '',
  ];

  static String _buildUrl(String prompt, String model, int seed) {
    final encodedPrompt = Uri.encodeComponent(prompt);
    final uri = Uri.parse(
      'https://image.pollinations.ai/prompt/$encodedPrompt',
    ).replace(
      queryParameters: <String, String>{
        'seed': '$seed',
        'width': '768',
        'height': '768',
        'nologo': 'true',
        'private': 'true',
        if (model.isNotEmpty) 'model': model,
      },
    );
    return uri.toString();
  }

  static Future<ImageGenResult?> generateImage(String prompt) async {
    final enhancedPrompt =
        '$prompt, anime art style, cinematic lighting, crisp linework, vibrant palette, detailed illustration, masterpiece';

    for (final model in _models) {
      final seed = _random.nextInt(999999);
      final url = _buildUrl(enhancedPrompt, model, seed);
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: const {
            'User-Agent': 'AnimeWaifuApp/5.0',
            'Accept': 'image/*',
          },
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200 && response.bodyBytes.length > 2048) {
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.contains('image') ||
              _isImageBytes(response.bodyBytes)) {
            return ImageGenResult(url: url, bytes: response.bodyBytes);
          }
        }
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 800));
    }

    return null;
  }

  static bool _isImageBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    if (bytes.length > 11 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45) {
      return true;
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return true;
    }
    return false;
  }
}

class ImageGenResult {
  const ImageGenResult({
    required this.url,
    required this.bytes,
  });

  final String url;
  final Uint8List bytes;
}


