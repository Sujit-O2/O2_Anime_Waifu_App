import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// LLM API Service - handles Groq LLM reasoning, vision, and Mailjet email integration.
/// Supports tool-use JSON action parsing for system commands.
class ApiService {
  String _modelName = 'moonshotai/kimi-k2-instruct';
  static const String _visionModel = 'llama-3.2-11b-vision-preview';
  String _baseUrl = 'https://api.groq.com/openai/v1';

  String get modelName => _modelName;

  set modelName(String value) => _modelName = value;
  set baseUrl(String value) => _baseUrl = value;

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    String? imageBase64,
  }) async {
    final model = imageBase64 != null ? _visionModel : _modelName;

    final List<Map<String, dynamic>> apiMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    if (imageBase64 != null && apiMessages.isNotEmpty) {
      final lastMsg = apiMessages.last;
      apiMessages[apiMessages.length - 1] = {
        'role': lastMsg['role'],
        'content': [
          {'type': 'text', 'text': lastMsg['content']},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
          },
        ],
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': apiMessages,
          'max_tokens': 1024,
          'temperature': 0.85,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          return message['content'] as String? ?? '';
        }
        return 'No response generated.';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  /// Parse action JSON blocks from AI response
  Map<String, dynamic>? parseAction(String response) {
    final regex = RegExp(r'\{[^{}]*"Action"[^{}]*\}', dotAll: true);
    final match = regex.firstMatch(response);
    if (match != null) {
      try {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Strip action JSON blocks from response text
  String stripActionBlocks(String response) {
    return response
        .replaceAll(
            RegExp(r'\{[^{}]*"Action"[^{}]*\}', dotAll: true), '')
        .trim();
  }

  /// Send email via Mailjet API
  Future<bool> sendMail({
    required String to,
    required String subject,
    required String body,
  }) async {
    final apiKey = dotenv.env['MAILJET_API_KEY'] ?? '';
    final secretKey = dotenv.env['MAILJET_SECRET_KEY'] ?? '';

    if (apiKey.isEmpty || secretKey.isEmpty) return false;

    final credentials = base64Encode(utf8.encode('$apiKey:$secretKey'));

    final htmlBody = '''
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#1a1a2e;padding:20px;">
      <tr><td align="center">
        <table width="600" cellpadding="20" style="background-color:#16213e;border-radius:12px;">
          <tr><td style="color:#e94560;font-size:24px;font-weight:bold;text-align:center;">
            Zero Two - Message
          </td></tr>
          <tr><td style="color:#eaeaea;font-size:16px;line-height:1.6;">
            $body
          </td></tr>
          <tr><td style="color:#666;font-size:12px;text-align:center;">
            Sent with love by O2-WAIFU
          </td></tr>
        </table>
      </td></tr>
    </table>
    ''';

    try {
      final response = await http.post(
        Uri.parse('https://api.mailjet.com/v3.1/send'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Messages': [
            {
              'From': {
                'Email': 'zerotwo@o2-waifu.app',
                'Name': 'Zero Two',
              },
              'To': [
                {'Email': to, 'Name': 'Darling'},
              ],
              'Subject': subject,
              'HTMLPart': htmlBody,
            }
          ]
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
