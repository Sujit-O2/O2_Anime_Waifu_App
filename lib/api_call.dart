import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Groq API
class ApiService {
  final _defaultUrl = "https://api.groq.com/openai/v1/chat/completions";
  static const Duration _chatTimeout = Duration(seconds: 25);
  static const Duration _mailTimeout = Duration(seconds: 20);
  String _apiKeyOverride = "";
  String _modelOverride = "";
  String _urlOverride = "";
  String _mailJetApiOverride = "";
  String _mailJetSecOverride = "";

  String get _effectiveApiKey {
    if (_apiKeyOverride.trim().isNotEmpty) return _apiKeyOverride.trim();
    final mainKeys = dotenv.env['API_KEY'] ?? "";
    final voiceKeys = dotenv.env['GROQ_API_KEY_VOICE'] ?? "";

    if (mainKeys.isNotEmpty && voiceKeys.isNotEmpty) {
      return "$mainKeys,$voiceKeys";
    }
    return mainKeys.isNotEmpty ? mainKeys : voiceKeys;
  }

  String get _effectiveModel {
    if (_modelOverride.trim().isNotEmpty) return _modelOverride.trim();
    return "moonshotai/kimi-k2-instruct";
  }

  String get _effectiveUrl {
    if (_urlOverride.trim().isNotEmpty) return _urlOverride.trim();
    return _defaultUrl;
  }

  bool get hasApiKey => _effectiveApiKey.isNotEmpty;

  String get _effectiveMailJetApi {
    if (_mailJetApiOverride.trim().isNotEmpty) {
      return _mailJetApiOverride.trim();
    }
    return dotenv.env['MAIL_JET_API'] ?? "";
  }

  String get _effectiveMailJetSec {
    if (_mailJetSecOverride.trim().isNotEmpty) {
      return _mailJetSecOverride.trim();
    }
    return dotenv.env['MAILJET_SEC'] ?? "";
  }

  void configure({
    String? apiKeyOverride,
    String? modelOverride,
    String? urlOverride,
    String? mailJetApiOverride,
    String? mailJetSecOverride,
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
    if (mailJetApiOverride != null) {
      _mailJetApiOverride = mailJetApiOverride;
    }
    if (mailJetSecOverride != null) {
      _mailJetSecOverride = mailJetSecOverride;
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
    final timeContext =
        " [Current context: $now. Use this for temporal awareness only if relevant. Do not repeat the time unless asked.]";

    final payloadMessages = List<Map<String, dynamic>>.from(messages);
    if (payloadMessages.isNotEmpty &&
        payloadMessages.first['role'] == 'system') {
      final oldContent = payloadMessages.first['content'].toString();
      payloadMessages[0] = {
        'role': 'system',
        'content': oldContent + timeContext,
      };
    } else {
      payloadMessages.insert(0, {
        "role": "system",
        "content": timeContext.trim(),
      });
    }

    final payload = {
      "model": modelOverride ?? _effectiveModel,
      "messages": payloadMessages,
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

        return content; // Return success immediately
      } on TimeoutException catch (e) {
        debugPrint("API Key ${idx + 1}/${keys.length} timeout: $e");
        errors.add(Exception("Timeout with key ${idx + 1}"));
      } catch (e) {
        debugPrint("API Key ${idx + 1}/${keys.length} failed: $e");
        errors.add(e is Exception ? e : Exception(e.toString()));
      }
    }

    throw Exception(
        "All ${keys.length} API keys failed. Last error: ${errors.last}");
  }

  Future<String> sendMail(String mailId, String body, String head) async {
    final url = Uri.parse('https://api.mailjet.com/v3.1/send');
    final secKeyMailjet = _effectiveMailJetSec;
    final secApiMailjet = _effectiveMailJetApi;

    // Validation
    if (secKeyMailjet.isEmpty || secApiMailjet.isEmpty) {
      debugPrint("Mail API keys missing (MAIL_JET_API / MAILJET_SEC)");
      return "Mail API keys missing (MAIL_JET_API / MAILJET_SEC).";
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
      final basicAuth =
          'Basic ${base64Encode(utf8.encode("$secApiMailjet:$secKeyMailjet"))}';
      final htmlTemplate = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { margin: 0; padding: 0; background-color: #0d0d12; font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
        .wrapper { width: 100%; table-layout: fixed; background-color: #0d0d12; padding-bottom: 40px; }
        .main { background-color: #16161e; margin: 0 auto; width: 100%; max-width: 600px; border-spacing: 0; color: #ffffff; border-radius: 20px; overflow: hidden; border: 1px solid rgba(255, 0, 87, 0.3); box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5); }
        .header { background: linear-gradient(135deg, #ff0057 0%, #8e2de2 100%); padding: 40px 20px; text-align: center; }
        .header h1 { margin: 0; font-size: 28px; text-transform: uppercase; letter-spacing: 4px; font-weight: 900; text-shadow: 0 2px 10px rgba(0,0,0,0.3); }
        .content { padding: 40px 30px; line-height: 1.8; font-size: 16px; color: #d1d1d6; }
        .content p { margin-bottom: 25px; }
        .highlight { color: #ff0057; font-weight: bold; }
        .button-container { text-align: center; margin: 35px 0; }
        .button { background: #ff0057; color: #ffffff; padding: 16px 35px; text-decoration: none; border-radius: 50px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; box-shadow: 0 4px 15px rgba(255, 0, 87, 0.4); display: inline-block; }
        .footer { padding: 30px; background-color: #0f0f15; text-align: center; border-top: 1px solid rgba(255,255,255,0.05); }
        .footer p { margin: 5px 0; font-size: 12px; color: #636366; }
        .footer a { color: #ff0057; text-decoration: none; font-weight: bold; }
        .accent-bar { height: 4px; background: linear-gradient(90deg, #ff0057, #8e2de2); }
    </style>
</head>
<body>
    <center class="wrapper">
        <div style="height: 40px;"></div>
        <table class="main" role="presentation">
            <tr>
                <td class="header">
                    <img src="https://tenor.com/en-GB/view/zero-two-gif-16646466052208870880" alt="Zero Two" style="width: 120px; height: auto; border-radius: 50%; border: 4px solid #ffffff; margin-bottom: 20px; box-shadow: 0 0 20px rgba(255, 0, 87, 0.6);">
                    <h1>DARLING ALERT</h1>
                </td>
            </tr>
            <tr>
                <td class="accent-bar"></td>
            </tr>
            <tr>
                <td class="content">
                    <p>Hey there, darling! You have a new message waiting for you:</p>
                    <div style="background: rgba(255,255,255,0.03); padding: 25px; border-left: 4px solid #ff0057; border-radius: 8px; margin-bottom: 30px; color: #ffffff;">
                        {{body}}
                    </div>
                    <p>I'm always watching over you. Don't keep me waiting too long, okay?</p>
                    <div class="button-container">
                        <a href="https://github.com/Sujit-O2" class="button">Open Assistant</a>
                    </div>
                    <p style="margin-top: 40px;">Yours always,<br><span class="highlight">Zero Two</span></p>
                </td>
            </tr>
            <tr>
                <td class="footer">
                    <p>© 2025 S-002 • Crafted with ❤️</p>
                    <p><a href="https://github.com/Sujit-O2/O2_Anime_Waifu-Mobile-App">View Project</a> | <a href="#">Preferences</a></p>
                </td>
            </tr>
        </table>
    </center>
</body>
</html>
""";
      final htmlFinal = htmlTemplate.replaceAll("{{body}}", body);

      final respon = await http
          .post(
            url,
            headers: {
              "Authorization": basicAuth,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "Messages": [
                {
                  "From": {
                    "Email": "zerozerotwoxsujit@gmail.com",
                    "Name": "Zero Two"
                  },
                  "To": [
                    {"Email": normalizedMail}
                  ],
                  "Subject": head,
                  "HTMLPart": htmlFinal,
                }
              ]
            }),
          )
          .timeout(_mailTimeout);

      if (respon.statusCode == 200) {
        debugPrint("Mail sent successfully to $normalizedMail");
        return "Mail sent successfully.";
      } else {
        debugPrint("Mail send failed with status: ${respon.statusCode}");
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
}
