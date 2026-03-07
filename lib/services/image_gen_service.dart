import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageGenService {
  // Uses Pollinations.ai — free, no API key required!
  static String buildImageUrl(String prompt) {
    final encoded = Uri.encodeComponent(prompt);
    return 'https://image.pollinations.ai/prompt/$encoded?width=512&height=512&nologo=true';
  }

  /// Returns the image URL for the given prompt (verified to be reachable).
  static Future<String?> generateImage(String prompt) async {
    try {
      final url = buildImageUrl(prompt);
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 20),
          );
      if (response.statusCode == 200) {
        return url;
      }
    } catch (e) {
      debugPrint('ImageGen error: $e');
    }
    return null;
  }
}
