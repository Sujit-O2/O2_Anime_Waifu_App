import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// AI Image Generation Service — Multi-provider with fallbacks.
/// Returns image bytes directly for reliable display.
class ImageGenService {
  static final _random = Random();

  // ── Provider: Airforce API (Free & Reliable) ────────────

  static const List<String> _models = [
    'flux-anime',   // Best quality for anime art
    'flux',         // Strong fallback
    'any-dark',     // Alternative aesthetic
  ];

  static String _buildUrl(String prompt, String model, int seed) {
    final encoded = Uri.encodeComponent(prompt);
    // Note: api.airforce returns raw image bytes directly
    return 'https://api.airforce/v1/imagine2?model=$model&prompt=$encoded&seed=$seed&size=1:1';
  }

  /// Returns image bytes on success, or null on total failure.
  static Future<ImageGenResult?> generateImage(String prompt) async {
    final enhancedPrompt =
        '$prompt, anime art style, high quality, detailed illustration, vibrant colors, masterpiece';

    // Try multiple models from Airforce API
    for (final model in _models) {
      final seed = _random.nextInt(999999);
      final url = _buildUrl(enhancedPrompt, model, seed);
      try {
        // ignore: avoid_print
        print('ImageGen: Trying Airforce API model=$model seed=$seed');
        final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 40));

        if (response.statusCode == 200 && response.bodyBytes.length > 2000) {
          final contentType = response.headers['content-type'] ?? '';
          final isImage = contentType.contains('image') ||
              _isImageBytes(response.bodyBytes);
          
          if (isImage) {
            // ignore: avoid_print
            print('ImageGen: ✅ Success with model=$model (${response.bodyBytes.length} bytes)');
            return ImageGenResult(url: url, bytes: response.bodyBytes);
          }
          // ignore: avoid_print
          print('ImageGen: ❌ model=$model returned non-image content ($contentType)');
        } else {
          // ignore: avoid_print
          print('ImageGen: ❌ model=$model returned ${response.statusCode} (${response.bodyBytes.length} bytes)');
        }
      } catch (e) {
        // ignore: avoid_print
        print('ImageGen: ❌ model=$model error: $e');
      }
      // Small cooldown to prevent rate limiting
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // ignore: avoid_print
    print('ImageGen: ❌ ALL AI providers failed');
    return null;
  }

  /// Check if bytes look like an image (PNG, JPEG, WEBP, GIF magic bytes)
  static bool _isImageBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // WebP: RIFF....WEBP
    if (bytes.length > 11 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[8] == 0x57 && bytes[9] == 0x45) return true;
    // GIF: GIF8
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
    return false;
  }
}

class ImageGenResult {
  final String url;
  final Uint8List bytes;
  ImageGenResult({required this.url, required this.bytes});
}
