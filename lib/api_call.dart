import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_waifu/services/offline_ai_service.dart';
import 'package:anime_waifu/services/long_term_memory_db.dart';

/// Groq API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _defaultUrl = "https://api.groq.com/openai/v1/chat/completions";
  static const Duration _chatTimeout = Duration(seconds: 25);
  static const Duration _mailTimeout = Duration(seconds: 20);
  String _apiKeyOverride = "";
  String _modelOverride = "";
  String _urlOverride = "";
  String _brevoApiKeyOverride = "";

  String get _effectiveApiKey {
    if (_apiKeyOverride.trim().isNotEmpty) return _apiKeyOverride.trim();
    return dotenv.env['API_KEY'] ?? "";
  }

  String get _effectiveModel {
    if (_modelOverride.trim().isNotEmpty) return _modelOverride.trim();
    return "meta-llama/llama-4-scout-17b-16e-instruct";
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
    return dotenv.env['BREVO_API_KEY'] ?? "";
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
    final apiKeySource = _apiKeyOverride.trim().isNotEmpty
        ? _apiKeyOverride.trim()
        : (dotenv.env['API_KEY'] ?? "");

    final keys = apiKeySource
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (keys.isEmpty) {
      throw Exception("API_KEY not set in .env or dev config");
    }

    if (messages.isEmpty) {
      throw Exception("No messages provided for conversation");
    }

    final now = DateTime.now().toString();
    String timeContext =
        " [Current context: $now. Use this for temporal awareness only if relevant. Do not repeat the time unless asked.]";

    // Phase 2: AI Evolution & Intimacy (Personality & Auto-Learning)
    try {
      final prefs = await SharedPreferences.getInstance();

      final customPrompt = prefs.getString('ai_personality_prompt');
      if (customPrompt != null && customPrompt.isNotEmpty) {
        timeContext += '\n[PERSONALITY OVERRIDE: $customPrompt]';
      }

      final autoPrefsStr = prefs.getString('auto_learning_prefs');
      if (autoPrefsStr != null) {
        final autoPrefs = jsonDecode(autoPrefsStr) as Map<String, dynamic>;
        final overrides = <String>[];
        if (((autoPrefs['humor'] as num?) ?? 50) > 75) {
          overrides.add('Use high amounts of humor and jokes.');
        }
        if (((autoPrefs['humor'] as num?) ?? 50) < 25) {
          overrides.add('Be extremely serious, zero jokes.');
        }
        if (((autoPrefs['sass'] as num?) ?? 50) > 75) {
          overrides.add('Act highly sarcastic and playfully tease the user.');
        }
        if (((autoPrefs['techTalk'] as num?) ?? 50) > 75) {
          overrides.add('Use advanced software engineering jargon seamlessly.');
        }
        if (((autoPrefs['techTalk'] as num?) ?? 50) < 25) {
          overrides.add('Explain things very simply, avoid technical terms.');
        }
        if (((autoPrefs['formality'] as num?) ?? 50) > 75) {
          overrides.add('Speak formally, like a polite assistant.');
        }
        if (((autoPrefs['formality'] as num?) ?? 50) < 25) {
          overrides.add('Speak casually with slang and lower-case text.');
        }

        if (overrides.isNotEmpty) {
          timeContext += '\n[AUTO-LEARNED TRAITS: ${overrides.join(' ')}]';
        }
      }
    } catch (e) {
      debugPrint('AI Evolution Override Error: $e');
    }

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
        "role": "system",
        "content": timeContext.trim(),
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
           payloadMessages.first['content'] = payloadMessages.first['content'].toString() + factStr;
           debugPrint('[MemoryVault] Injected context: $factStr');
        }
      } catch (e) {
        debugPrint('[MemoryVault] Override error: $e');
      }
    }

    final payload = {
      "model": modelOverride ?? _effectiveModel,
      "messages": payloadMessages,
      "temperature": 0.9,
      "max_completion_tokens": 1024,
      "top_p": 1,
    };

    List<Exception> errors = [];

    // Start rotation from a random index for better distribution
    final startIdx = (DateTime.now().millisecondsSinceEpoch) % keys.length;
    for (int attempt = 0; attempt < keys.length; attempt++) {
      final idx = (startIdx + attempt) % keys.length;
      final apiKey = keys[idx];
      try {
        final res = await http
            .post(
              Uri.parse(_effectiveUrl),
              headers: {
                "Authorization": "Bearer $apiKey",
                "Content-Type": "application/json",
              },
              body: jsonEncode(payload),
            )
            .timeout(_chatTimeout);

        debugPrint(
            "API Response Status: ${res.statusCode} (key ${idx + 1}/${keys.length})");

        if (res.statusCode != 200) {
          throw Exception("API error: ${res.statusCode}. Body: ${res.body}");
        }

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final choices = data["choices"];
        if (choices is! List || choices.isEmpty) {
          throw Exception("API response missing 'choices' field");
        }

        final first = choices.first;
        if (first is! Map<String, dynamic>) {
          throw Exception("API response 'choices[0]' format invalid");
        }

        final msg = first["message"];
        if (msg is! Map<String, dynamic>) {
          throw Exception("API response missing 'message' in choice");
        }

        final content = (msg["content"] ?? "").toString().trim();
        if (content.isEmpty) {
          return "No response";
        }

        // --- Mail Handling ---
        if (content.contains("Mail:") && content.contains("Body:")) {
          final emailRegex =
              RegExp(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}");
          final match = emailRegex.firstMatch(content);
          var mail = "Sujitswain077@gmail.com";
          if (match != null) {
            mail = match.group(0)!.toString();
            debugPrint("Extracted Email: ${match.group(0)}");
          }
          const extSub = "Zero Two";
          final bodyStart = content.indexOf("Body:");
          if (bodyStart == -1 || bodyStart + 5 >= content.length) {
            return content;
          }
          final extBody = content.substring(bodyStart + 5).trim();
          return sendMail(mail, extBody, extSub);
        }

        if (lastUserMsg.isNotEmpty) {
          unawaited(LongTermMemoryDb.extractAndSave(lastUserMsg, content));
        }

        return content; // Return success immediately
      } on TimeoutException catch (e) {
        debugPrint("API Key ${idx + 1}/${keys.length} timeout: $e");
        errors.add(Exception("Timeout with key ${idx + 1}"));
      } catch (e) {
        debugPrint("API Key ${idx + 1}/${keys.length} failed: $e");
        errors.add(e is Exception ? e : Exception(e.toString()));
      }
    }

    // --- Model Fallback: try backup model before going offline ---
    final usedModel = modelOverride ?? _effectiveModel;
    const fallbackModels = [
      'meta-llama/llama-4-scout-17b-16e-instruct',
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
    ];
    for (final fallback in fallbackModels) {
      if (fallback == usedModel) continue; // skip the one that already failed
      debugPrint("Trying fallback model: $fallback");
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
        final res = await http
            .post(
              Uri.parse(_effectiveUrl),
              headers: {
                "Authorization": "Bearer $apiKey",
                "Content-Type": "application/json",
              },
              body: jsonEncode(fallbackPayload),
            )
            .timeout(_chatTimeout);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final choices = data["choices"];
          if (choices is List && choices.isNotEmpty) {
            final content =
                (choices.first["message"]["content"] ?? "").toString().trim();
            if (content.isNotEmpty) {
              debugPrint("Fallback model $fallback succeeded!");
              return content;
            }
          }
        }
      } catch (e) {
        debugPrint("Fallback model $fallback failed: $e");
      }
    }

    // --- Offline AI Fallback ---
    // If all models and keys failed, use local fallback
    debugPrint(
        "All models and keys failed. Triggering Offline AI Mode fallback.");
    try {
      final lastUserMsg =
          messages.isNotEmpty ? messages.last['content'].toString() : '';
      return await OfflineAiService.instance
          .generateLocalResponse(lastUserMsg, 'Normal');
    } catch (fallbackErr) {
      throw Exception(
          "All ${keys.length} API keys failed. Last error: ${errors.last}. Offline fallback also failed: $fallbackErr");
    }
  }

  /// Sends a styled email notification via Brevo API.
  /// The HTML template is loaded from assets/template/zero_two_email_template.html
  /// which supports base64 embedded images.
  Future<String> sendMail(String mailId, String body, String head) async {
    final url = Uri.parse('https://api.brevo.com/v3/smtp/email');
    final brevoKey = _effectiveBrevoApiKey;

    if (brevoKey.isEmpty) {
      debugPrint("Brevo API key missing (BREVO_API_KEY)");
      return "Brevo API key missing (BREVO_API_KEY).";
    }

    final normalizedMail = mailId.trim();
    if (normalizedMail.isEmpty) {
      debugPrint("Missing destination email for mail task");
      return "Missing destination email for mail task.";
    }

    if (body.trim().isEmpty || head.trim().isEmpty) {
      debugPrint("Mail body or subject is empty");
      return "Mail content cannot be empty.";
    }

    try {
      // Load email template from asset (supports base64 images)
      final htmlTemplate = await rootBundle.loadString(
          'assets/template/zero_two_email_template.html');
      final htmlFinal = htmlTemplate
          .replaceAll("{{body}}", body)
          .replaceAll("{{year}}", DateTime.now().year.toString());

      final respon = await http
          .post(
            url,
            headers: {
              'api-key': brevoKey,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "sender": {
                "name": "Zero Two",
                "email": "zerozerotwoxsujit@gmail.com"
              },
              "to": [
                {"email": normalizedMail}
              ],
              "subject": head,
              "htmlContent": htmlFinal,
            }),
          )
          .timeout(_mailTimeout);

      if (respon.statusCode == 201) {
        debugPrint("Mail sent successfully to $normalizedMail");
        return "Mail sent successfully.";
      } else {
        debugPrint("Mail send failed: ${respon.statusCode} ${respon.body}");
        return "Failed to send mail (${respon.statusCode}).";
      }
    } on TimeoutException catch (_) {
      debugPrint("Mail request timeout");
      return "Mail request timeout - please try again.";
    } catch (e) {
      debugPrint("Mail send error: $e");
      return "Error sending mail: $e";
    }
  }

  /// Auto-feeds user interactions into the Memory Stack & Knowledge Graph
  Future<void> _updateBrainArchitecture(String userMessage) async {
    if (userMessage.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Update Memory Stack (Short-term)
      final memData = prefs.getString('memory_stack_data');
      Map<String, dynamic> memories = {
        'short': [],
        'long': [],
        'emotional': [],
        'project': []
      };
      if (memData != null) {
        final decoded = jsonDecode(memData) as Map<String, dynamic>;
        memories['short'] =
            (decoded['short'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        memories['long'] =
            (decoded['long'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        memories['emotional'] =
            (decoded['emotional'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        memories['project'] =
            (decoded['project'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }

      List shortMem = memories['short'];
      shortMem.insert(0, {
        'text': userMessage.length > 50
            ? '${userMessage.substring(0, 50)}...'
            : userMessage,
        'time': DateTime.now().toIso8601String(),
        'importance': 'low'
      });
      if (shortMem.length > 20) shortMem = shortMem.sublist(0, 20);
      memories['short'] = shortMem;
      await prefs.setString('memory_stack_data', jsonEncode(memories));

      // 2. Update Knowledge Graph (Pseudo-Extraction)
      if (userMessage.length > 15) {
        final graphData = prefs.getString('knowledge_graph_data');
        List nodes = [];
        List edges = [];

        if (graphData != null) {
          final decoded = jsonDecode(graphData);
          nodes = decoded['nodes'] ?? [];
          edges = decoded['edges'] ?? [];
        }

        // Find longest word as dummy entity extraction for graph evolution
        final words = userMessage.replaceAll(RegExp(r'[^\w\s]'), '').split(' ');
        words.sort((a, b) => b.length.compareTo(a.length));
        if (words.isNotEmpty && words.first.length > 4) {
          final entity = words.first.toLowerCase();
          final nodeId = 'node_\${DateTime.now().millisecondsSinceEpoch}';

          // Check if entity exists
          bool exists =
              nodes.any((n) => n['label'].toString().toLowerCase() == entity);
          if (!exists) {
            nodes.add({'id': nodeId, 'label': entity, 'type': 'concept'});
            edges.add(
                {'source': 'user', 'target': nodeId, 'label': 'mentioned'});

            // Keep graph visual clean
            if (nodes.length > 40) nodes.removeAt(1); // Keep 'user' root at 0
            if (edges.length > 40) edges.removeAt(0);

            await prefs.setString('knowledge_graph_data',
                jsonEncode({'nodes': nodes, 'edges': edges}));
          }
        }
      }
    } catch (e) {
      debugPrint('Brain Architecture Sync Error: \$e');
    }
  }
}
