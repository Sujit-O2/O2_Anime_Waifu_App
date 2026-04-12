import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// A robust HTTP client wrapper that automatically handles:
/// - Maximum of 3 automatic retries with exponential backoff for 5xx errors and socket limits
/// - Evasion headers to bypass basic CloudFlare checks on Madara/WP scraping targets
/// - Connection timeouts (15s default) to prevent infinite UI hanging
class RobustHttpClient {
  static const int _maxRetries = 3;

  static Map<String, String> get evasiveHeaders => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Cache-Control': 'max-age=0',
  };

  static Future<http.Response> get(Uri url, {Map<String, String>? headers, Duration timeout = const Duration(seconds: 15)}) async {
    final mergedHeaders = {...evasiveHeaders, ...?headers};
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      try {
        final resp = await http.get(url, headers: mergedHeaders).timeout(timeout);
        // If 5xx server error or rate limited (429), retry
        if (resp.statusCode >= 500 || resp.statusCode == 429) {
          attempts++;
          if (attempts >= _maxRetries) return resp;
          await Future.delayed(Duration(milliseconds: 500 * attempts * attempts)); // exponential backoff
          continue;
        }
        return resp; // 200, 403, 404 etc
      } on SocketException {
        attempts++;
        if (attempts >= _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
      } on TimeoutException {
        attempts++;
        if (attempts >= _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      } catch (e) {
        rethrow;
      }
    }
    throw Exception('Max retries exceeded for \$url');
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 15)}) async {
    final mergedHeaders = {...evasiveHeaders, ...?headers};
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      try {
        final resp = await http.post(url, headers: mergedHeaders, body: body).timeout(timeout);
        if (resp.statusCode >= 500 || resp.statusCode == 429) {
          attempts++;
          if (attempts >= _maxRetries) return resp;
          await Future.delayed(Duration(milliseconds: 500 * attempts * attempts));
          continue;
        }
        return resp;
      } on SocketException {
        attempts++;
        if (attempts >= _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
      } on TimeoutException {
        attempts++;
        if (attempts >= _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      } catch (e) {
        rethrow;
      }
    }
    throw Exception('Max retries exceeded for \$url');
  }
}


