import 'dart:async';
import 'dart:convert';

import 'package:anime_waifu/core/constants.dart';
import 'package:anime_waifu/services/ai_personalization/offline_ai_service.dart';
import 'package:anime_waifu/services/database_storage/long_term_memory_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent HTTP client for connection pooling — reuses TCP connections
/// across API calls, eliminating handshake overhead per request.
final http.Client _persistentClient = http.Client();

class _CachedResponse {
  final String content;
  final DateTime time;

  const _CachedResponse(this.content, this.time);
}

/// Groq API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _defaultUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const Duration _chatTimeout = Duration(seconds: 30);
  static const Duration _mailTimeout = Duration(seconds: 20);
  DateTime? _lastMailSentAt;

  /// Simple response cache — prevents duplicate API calls for identical
  /// messages sent within 30 seconds (e.g., double-tap send)
  final Map<String, _CachedResponse> _responseCache = {};
  static const int _maxCacheSize = 10;
  static const Duration _cacheTtl = Duration(seconds: 30);
  String _apiKeyOverride = '';
  String _modelOverride = '';
  String _urlOverride = '';
  String _brevoApiKeyOverride = '';

  String get _effectiveApiKey {
    if (_apiKeyOverride.trim().isNotEmpty) return _apiKeyOverride.trim();
    return dotenv.env['API_KEY'] ?? '';
  }

  String get _effectiveModel {
    if (_modelOverride.trim().isNotEmpty) return _modelOverride.trim();
    return 'meta-llama/llama-4-maverick-17b-128e-instruct';
  }

  String get _effectiveUrl {
    if (_urlOverride.trim().isNotEmpty) return _urlOverride.trim();
    return _defaultUrl;
  }

  bool get hasApiKey => _effectiveApiKey.isNotEmpty;

  String get _effectiveBrevoApiKey {
    if (_brevoApiKeyOverride.trim().isNotEmpty) {
      return _brevoApiKeyOverride.trim();
    }
    return dotenv.env['BREVO_API_KEY'] ?? '';
  }

  void configure({
    String? apiKeyOverride,
    String? modelOverride,
    String? urlOverride,
    String? brevoApiKeyOverride,
  }) {
    if (apiKeyOverride != null) {
      _apiKeyOverride = apiKeyOverride;
    }
    if (modelOverride != null) {
      _modelOverride = modelOverride;
    }
    if (urlOverride != null) {
      _urlOverride = urlOverride;
    }
    if (brevoApiKeyOverride != null) {
      _brevoApiKeyOverride = brevoApiKeyOverride;
    }
  }

  Future<String> sendConversation(
    List<Map<String, dynamic>> messages, {
    String? modelOverride,
  }) async {
    // Check response cache for duplicate rapid-fire requests
    final cacheKey = messages.isNotEmpty
        ? messages.last['content']?.toString().hashCode.toString() ?? ''
        : '';
    if (cacheKey.isNotEmpty) {
      final cached = _responseCache[cacheKey];
      if (cached != null &&
          DateTime.now().difference(cached.time) < _cacheTtl) {
        if (kDebugMode) debugPrint('[API] Cache hit for duplicate message');
        return cached.content;
      }
    }

    final apiKeySource = _apiKeyOverride.trim().isNotEmpty
        ? _apiKeyOverride.trim()
        : (dotenv.env['API_KEY'] ?? '');

    final keys = apiKeySource
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (messages.isEmpty) {
      throw Exception('No messages provided for conversation');
    }

    if (keys.isEmpty) {
      final lastUserMsg = messages.last['content']?.toString() ?? '';
      return OfflineAiService.instance.generateLocalResponse(
        lastUserMsg,
        'Normal',
      );
    }

    final now = DateTime.now().toString();
    String timeContext =
        ' [Current context: $now. Use this for temporal awareness only if relevant. Do not repeat the time unless asked.]';

    // Extract the valid user/assistant history
    var historyMessages = messages.where((m) => m['role'] != 'system').toList();

    // Limit to the last 15 messages max
    if (historyMessages.length > 15) {
      historyMessages = historyMessages.sublist(historyMessages.length - 15);
    }

    final payloadMessages = List<Map<String, dynamic>>.from(historyMessages);

    // Re-insert or create the system message at the top
    if (messages.isNotEmpty && messages.first['role'] == 'system') {
      final oldContent = messages.first['content'].toString();
      payloadMessages.insert(0, {
        'role': 'system',
        'content': oldContent + timeContext,
      });
    } else {
      payloadMessages.insert(0, {
        'role': 'system',
        'content': timeContext.trim(),
      });
    }

    // Phase 1: Brain Architecture Auto-Increase
    String lastUserMsg = '';
    if (messages.isNotEmpty && messages.last['role'] == 'user') {
      lastUserMsg = messages.last['content'].toString();
      _updateBrainArchitecture(lastUserMsg);
    }

    // Phase 3: Deep Vector Long-Term Memory Injection
    if (lastUserMsg.isNotEmpty) {
      try {
        final facts = await LongTermMemoryDb.getRelevantContext(lastUserMsg);
        if (facts.isNotEmpty) {
          final factStr = '\n[LONG-TERM MEMORY MATCH: ${facts.join(" | ")}]';
          payloadMessages.first['content'] =
              payloadMessages.first['content'].toString() + factStr;
          if (kDebugMode)
            debugPrint('[MemoryVault] Injected context: $factStr');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[MemoryVault] Override error: $e');
      }
    }

    final payload = {
      'model': modelOverride ?? _effectiveModel,
      'messages': payloadMessages,
      'temperature': 0.9,
      'max_completion_tokens': 2048,
      'top_p': 1,
    };

    List<Exception> errors = [];

    // Start rotation from a random index for better distribution
    final startIdx = (DateTime.now().millisecondsSinceEpoch) % keys.length;
    for (int attempt = 0; attempt < keys.length; attempt++) {
      final idx = (startIdx + attempt) % keys.length;
      final apiKey = keys[idx];
      // Exponential backoff: wait before retry (skip first attempt)
      if (attempt > 0) {
        final backoffMs = (200 * (1 << (attempt - 1))).clamp(0, 3000);
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
      try {
        final res = await _persistentClient
            .post(
              Uri.parse(_effectiveUrl),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(_chatTimeout);

        if (kDebugMode) {
          debugPrint(
              'API Response Status: ${res.statusCode} (key ${idx + 1}/${keys.length})');
        }

        if (res.statusCode != 200) {
          throw Exception('API error: ${res.statusCode}. Body: ${res.body}');
        }

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final choices = data['choices'];
        if (choices is! List || choices.isEmpty) {
          throw Exception("API response missing 'choices' field");
        }

        final first = choices.first;
        if (first is! Map<String, dynamic>) {
          throw Exception("API response 'choices[0]' format invalid");
        }

        final msg = first['message'];
        if (msg is! Map<String, dynamic>) {
          throw Exception("API response missing 'message' in choice");
        }

        final content = (msg['content'] ?? '').toString().trim();
        if (content.isEmpty) {
          return 'No response';
        }

        // --- Mail Handling ---
        if (content.contains('Mail:') && content.contains('Body:')) {
          final emailRegex =
              RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
          final match = emailRegex.firstMatch(content);
          var mail = Defaults.defaultEmail;
          if (match != null && match.group(0) != null) {
            mail = match.group(0)!;
            if (kDebugMode) debugPrint('Extracted Email: ${match.group(0)}');
          }
          const extSub = 'Zero Two';
          final bodyStart = content.indexOf('Body:');
          if (bodyStart == -1 || bodyStart + 5 >= content.length) {
            return content;
          }
          final extBody = content.substring(bodyStart + 5).trim();
          return await sendMail(mail, extBody, extSub);
        }

        if (lastUserMsg.isNotEmpty) {
          unawaited(LongTermMemoryDb.extractAndSave(lastUserMsg, content));
        }

        // Cache this response for dedup protection
        if (cacheKey.isNotEmpty) {
          _responseCache[cacheKey] = _CachedResponse(content, DateTime.now());
          // Evict oldest entries if cache is full
          if (_responseCache.length > _maxCacheSize) {
            final oldest = _responseCache.entries
                .reduce((a, b) => a.value.time.isBefore(b.value.time) ? a : b);
            _responseCache.remove(oldest.key);
          }
        }
        return content; // Return success immediately
      } on TimeoutException catch (e) {
        if (kDebugMode)
          debugPrint('API Key ${idx + 1}/${keys.length} timeout: $e');
        errors.add(Exception('Timeout with key ${idx + 1}'));
      } catch (e) {
        if (kDebugMode)
          debugPrint('API Key ${idx + 1}/${keys.length} failed: $e');
        errors.add(e is Exception ? e : Exception(e.toString()));
      }
    }

    // --- Model Fallback: try backup model before going offline ---
    final usedModel = modelOverride ?? _effectiveModel;
    const fallbackModels = [
      'meta-llama/llama-4-maverick-17b-128e-instruct',
      'meta-llama/llama-4-scout-17b-16e-instruct',
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
    ];
    for (final fallback in fallbackModels) {
      if (fallback == usedModel) continue; // skip the one that already failed
      if (kDebugMode) debugPrint('Trying fallback model: $fallback');
      try {
        final fallbackPayload = Map<String, dynamic>.from(payload);
        fallbackPayload['model'] = fallback;
        // Strip image content for non-vision fallback models
        final fallbackMessages = (fallbackPayload['messages'] as List).map((m) {
          if (m is Map && m['content'] is List) {
            // Multimodal content — extract text only for text-only models
            final textParts = (m['content'] as List)
                .where((p) => p is Map && p['type'] == 'text')
                .map((p) => p['text'].toString())
                .join(' ');
            return {'role': m['role'], 'content': textParts};
          }
          return m;
        }).toList();
        fallbackPayload['messages'] = fallbackMessages;

        final apiKey =
            keys[(DateTime.now().millisecondsSinceEpoch) % keys.length];
        final res = await _persistentClient
            .post(
              Uri.parse(_effectiveUrl),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(fallbackPayload),
            )
            .timeout(_chatTimeout);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final choices = data['choices'];
          if (choices is List && choices.isNotEmpty) {
            final content =
                (choices.first['message']['content'] ?? '').toString().trim();
            if (content.isNotEmpty) {
              if (kDebugMode) debugPrint('Fallback model $fallback succeeded!');
              return content;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Fallback model $fallback failed: $e');
      }
    }

    // --- Offline AI Fallback ---
    // If all models and keys failed, use local fallback
    if (kDebugMode) {
      debugPrint(
          'All models and keys failed. Triggering Offline AI Mode fallback.');
    }
    try {
      final lastUserMsg =
          messages.isNotEmpty ? messages.last['content'].toString() : '';
      return await OfflineAiService.instance
          .generateLocalResponse(lastUserMsg, 'Normal');
    } catch (fallbackErr) {
      throw Exception(
          'All ${keys.length} API keys failed. Last error: ${errors.last}. Offline fallback also failed: $fallbackErr');
    }
  }

  /// Sends a styled email notification via Brevo API with enhanced error handling
  /// Automatically retries on failure and provides diagnostic information
  Future<String> sendMail(String mailId, String body, String head) async {
    // Rate limit: max 1 email per 30 seconds
    final now = DateTime.now();
    if (_lastMailSentAt != null &&
        now.difference(_lastMailSentAt!) < const Duration(seconds: 30)) {
      return '⏳ Please wait before sending another email.';
    }
    final url = Uri.parse('https://api.brevo.com/v3/smtp/email');
    final brevoKey = _effectiveBrevoApiKey;

    // Validate API Key
    if (brevoKey.isEmpty) {
      if (kDebugMode) debugPrint('❌ Brevo API key missing (BREVO_API_KEY)');
      return '❌ Brevo API key not configured. Please add BREVO_API_KEY to .env or Dev Config.';
    }

    // Validate API key format (should start with xkeysib-)
    if (!brevoKey.startsWith('xkeysib-')) {
      if (kDebugMode) {
        debugPrint(
            "❌ Brevo API key format invalid. Expected to start with 'xkeysib-'");
      }
      return "❌ Brevo API key format is invalid. Check that it starts with 'xkeysib-'.";
    }

    final normalizedMail = mailId.trim();
    if (normalizedMail.isEmpty) {
      if (kDebugMode) debugPrint('❌ Missing destination email for mail task');
      return '❌ Missing destination email address.';
    }

    if (body.trim().isEmpty || head.trim().isEmpty) {
      if (kDebugMode) debugPrint('❌ Mail body or subject is empty');
      return '❌ Mail content cannot be empty.';
    }

    try {
      // Load email template from asset (supports base64 images)
      String htmlFinal;
      try {
        final htmlTemplate = await rootBundle
            .loadString('assets/template/zero_two_email_template.html');
        htmlFinal = htmlTemplate
            .replaceAll('{{body}}', body)
            .replaceAll('{{year}}', DateTime.now().year.toString());
      } catch (e) {
        if (kDebugMode)
          debugPrint('⚠️ Template not found, using plain HTML: $e');
        // Basic HTML entity encoding to prevent XSS in email body
        final safeBody = body
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;');
        htmlFinal = '<html><body><p>$safeBody</p></body></html>';
      }

      final respon = await _persistentClient
          .post(
            url,
            headers: {
              'api-key': brevoKey,
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'sender': {
                'name': 'Zero Two',
                'email': dotenv.env['SENDER_EMAIL']?.trim().isNotEmpty == true
                    ? dotenv.env['SENDER_EMAIL']!.trim()
                    : Defaults.defaultSenderEmail,
              },
              'to': [
                {'email': normalizedMail}
              ],
              'subject': head,
              'htmlContent': htmlFinal,
            }),
          )
          .timeout(_mailTimeout);

      if (respon.statusCode == 201) {
        if (kDebugMode)
          debugPrint('✅ Mail sent successfully to $normalizedMail');
        return '✅ Mail sent successfully.';
      } else if (respon.statusCode == 401) {
        if (kDebugMode)
          debugPrint('❌ Brevo authentication failed (401): ${respon.body}');
        return '❌ Brevo API key is invalid or expired (401). Check your API key in Dev Config.';
      } else if (respon.statusCode == 429) {
        if (kDebugMode) debugPrint('⚠️  Brevo rate limit exceeded (429)');
        return '⚠️ Too many requests sent. Please wait before trying again.';
      } else if (respon.statusCode == 400) {
        if (kDebugMode) debugPrint('❌ Bad request (400): ${respon.body}');
        return '❌ Invalid email format or recipient address.';
      } else {
        if (kDebugMode)
          debugPrint('❌ Mail send failed: ${respon.statusCode} ${respon.body}');
        return '❌ Failed to send mail (HTTP ${respon.statusCode}). ${respon.body}';
      }
    } on TimeoutException catch (_) {
      if (kDebugMode)
        debugPrint('❌ Mail request timeout after ${_mailTimeout.inSeconds}s');
      return '❌ Mail request timeout. Please ensure you have internet connection.';
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Mail send error: $e');
      return '❌ Error sending mail: $e';
    }
  }

  /// Auto-feeds user interactions into the Memory Stack.
  /// Uses defensive decoding to prevent corrupt JSON from breaking the app.
  Future<void> _updateBrainArchitecture(String userMessage) async {
    if (userMessage.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update Memory Stack (Short-term)
      final memData = prefs.getString(PrefsKeys.memoryStackData);
      Map<String, dynamic> memories = {
        'short': <Map<String, dynamic>>[],
        'long': <Map<String, dynamic>>[],
        'emotional': <Map<String, dynamic>>[],
        'project': <Map<String, dynamic>>[],
      };
      if (memData != null && memData.isNotEmpty) {
        try {
          final decoded = jsonDecode(memData);
          if (decoded is Map<String, dynamic>) {
            for (final key in ['short', 'long', 'emotional', 'project']) {
              final list = decoded[key];
              if (list is List) {
                memories[key] = list.whereType<Map<String, dynamic>>().toList();
              }
            }
          }
        } catch (_) {
          // Corrupt stored JSON — reset gracefully
          if (kDebugMode)
            debugPrint('[BrainArch] Corrupt memory data, resetting.');
        }
      }

      final shortMem = memories['short'] as List<Map<String, dynamic>>;
      shortMem.insert(0, {
        'text': userMessage.length > 50
            ? '${userMessage.substring(0, 50)}...'
            : userMessage,
        'time': DateTime.now().toIso8601String(),
        'importance': 'low',
      });
      // Cap at 20 entries
      if (shortMem.length > 20) {
        memories['short'] = shortMem.sublist(0, 20);
      }
      await prefs.setString(PrefsKeys.memoryStackData, jsonEncode(memories));
    } catch (e) {
      if (kDebugMode) debugPrint('Brain Architecture Sync Error: $e');
    }
  }
}
