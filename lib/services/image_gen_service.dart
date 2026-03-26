import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// AI Image Generation Service — multi-API fallback approach.
/// 1. Primary: Pollinations.ai (returns image URL directly, no pre-check needed)
/// 2. Fallback: waifu.pics (random anime images)
class ImageGenService {
  static final _random = Random();

  /// Build a Pollinations URL — the image is generated on-demand when loaded.
  /// We skip any pre-verification and just give the URL to Image.network().
  static String _buildPollinationsUrl(String prompt, {int? seed}) {
    final s = seed ?? _random.nextInt(999999);
    final encoded = Uri.encodeComponent(prompt);
    // Use the latest Pollinations endpoint format
    return 'https://image.pollinations.ai/prompt/$encoded?width=512&height=512&nologo=true&seed=$s';
  }

  /// Returns a usable image URL for the given prompt.
  /// Strategy:
  /// 1. Try Pollinations — just return the URL without pre-checking (let Image widget load it)
  ///    BUT verify with a quick GET first. If 401/503, skip to fallback immediately.
  /// 2. Fallback to waifu.pics (free anime images API)
  static Future<String?> generateImage(String prompt) async {
    // ── Attempt 1: Pollinations.ai (direct URL, skip if 401) ──
    try {
      final url = _buildPollinationsUrl(prompt);
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 60),
          );
      if (response.statusCode == 200 && response.bodyBytes.length > 500) {
        debugPrint('ImageGen: Pollinations success (${response.bodyBytes.length} bytes)');
        return url;
      }
      debugPrint('ImageGen: Pollinations returned ${response.statusCode}');
    } catch (e) {
      debugPrint('ImageGen: Pollinations error: $e');
    }

    // ── Attempt 2: waifu.pics — free anime images ──
    try {
      final categories = ['waifu', 'neko', 'shinobu', 'megumin'];
      final cat = categories[_random.nextInt(categories.length)];
      final response = await http
          .get(Uri.parse('https://api.waifu.pics/sfw/$cat'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          debugPrint('ImageGen: waifu.pics success: $imageUrl');
          return imageUrl;
        }
      }
    } catch (e) {
      debugPrint('ImageGen: waifu.pics error: $e');
    }

    // ── Attempt 3: nekos.best — another free anime images API ──
    try {
      final categories = ['waifu', 'neko', 'kitsune', 'husbando'];
      final cat = categories[_random.nextInt(categories.length)];
      final response = await http
          .get(Uri.parse('https://nekos.best/api/v2/$cat'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final imageUrl = results[0]['url'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            debugPrint('ImageGen: nekos.best success: $imageUrl');
            return imageUrl;
          }
        }
      }
    } catch (e) {
      debugPrint('ImageGen: nekos.best error: $e');
    }

    return null;
  }
}
