import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
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
    return dotenv.env['API_KEY'] ?? "";
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

  Future<String> sendConversation(List<Map<String, dynamic>> messages) async {
    final apiKey = _effectiveApiKey;
    if (apiKey.isEmpty) {
      throw Exception("API_KEY not set in .env or dev config");
    }

    final now = DateTime.now().toString();
    final timeMessage = {
      "role": "system",
      "content":
          "The current date and time is $now. Use this information if the user asks about the current time or a related query."
    };
    final payloadMessages = [...messages, timeMessage];
    final payload = {
      "model": _effectiveModel,
      "messages": payloadMessages,
    };

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

    debugPrint("RAW RESPONSE: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("API error: ${res.statusCode}. Body: ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data["choices"];
    if (choices is! List || choices.isEmpty) {
      throw Exception("API response missing choices");
    }
    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw Exception("API response format invalid");
    }
    final msg = first["message"];
    if (msg is! Map<String, dynamic>) {
      throw Exception("API response missing message");
    }

    final content = (msg["content"] ?? "").toString().trim();
    if (content.isEmpty) {
      return "No response";
    }

    if (content.contains("Mail:") && content.contains("Body:")) {
      // Extract email using regex
      final emailRegex =
          RegExp(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}");
      final match = emailRegex.firstMatch(content);
      var mail = "Sujitswain077@gmail.com";
      if (match != null) {
        mail = match.group(0)!.toString();
        debugPrint("Extracted Email: ${match.group(0)}");
      }
      final extSub = "Zero Two";
      final bodyStart = content.indexOf("Body:");
      if (bodyStart == -1 || bodyStart + 5 >= content.length) {
        return content;
      }
      final extBody = content.substring(bodyStart + 5).trim();
      debugPrint(extSub);
      debugPrint(extBody);
      return sendMail(mail, extBody, extSub);
    }

    return content;
  }

  Future<String> sendMail(String mailId, String body, String head) async {
    final url = Uri.parse('https://api.mailjet.com/v3.1/send');
    final secKeyMailjet = _effectiveMailJetSec;
    final secApiMailjet = _effectiveMailJetApi;
    if (secKeyMailjet.isEmpty || secApiMailjet.isEmpty) {
      return "Mail API keys missing (MAIL_JET_API / MAILJET_SEC).";
    }
    if (mailId.trim().isEmpty) {
      return "Missing destination email for mail task.";
    }
    final basicAuth =
        'Basic ${base64Encode(utf8.encode("$secApiMailjet:$secKeyMailjet"))}';
    final htmlTemplate = """
<!DOCTYPE html>
<html lang="en" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Zero Two Darling Notification</title>
    
    <style>
        /* General Reset for Email Clients */
        body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
        table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
        img { -ms-interpolation-mode: bicubic; border: 0; }
        
        /* Thematic Colors */
        .primary-pink { color: #FF0057; } /* Zero Two Red/Pink - Intense */
        .accent-blue { color: #1e90ff; }
        .dark-bg { background-color: #1a1a1a; }
        .content-bg { background-color: #ffffff; }
        
        /* Responsive Styles */
        @media screen and (max-width: 600px) {
            .full-width-table { width: 100% !important; }
            .content-padding { padding: 25px 15px !important; }
            h1 { font-size: 24px !important; }
        }
    </style>
</head>

<body style="margin: 0; padding: 0; background-color: #1a1a1a; height: 100% !important; width: 100% !important;">

<center class="dark-bg" style="width: 100%; background-color: #1a1a1a;">
    
    <div style="height: 40px; line-height: 40px; mso-line-height-rule: exactly;">&nbsp;</div>

    <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" class="full-width-table" style="width: 100%; max-width: 600px; background-color: #ffe4e1; border-radius: 12px; border: 3px solid #FF0057; box-shadow: 0 8px 30px rgba(255,0,87,0.4); border-collapse: collapse;">
        
        <tr>
            <td align="center" style="background-color: #ffc0cb; border-top-left-radius: 9px; border-top-right-radius: 9px; padding: 25px 0 15px 0;">
                <h1 style="margin: 0; color: #ffffff; font-size: 30px; font-weight: 900; letter-spacing: 2px; text-transform: uppercase; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
                    🍁 ZERO TWO ALERT 🍁
                </h1>
            </td>
        </tr>
        <tr>
            <td align="left" class="content-padding" style="padding: 30px; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 17px; line-height: 1.7; color: #333333;">
                
                <p style="margin: 0 0 25px 0;">{{body}}</p>

                <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="margin: 30px auto;">
                    <tr>
                        <td align="center" style="border-radius: 8px; background-color: #FF0057; padding: 15px 30px; transition: background-color 0.3s ease-in-out;" onmouseover="this.style.backgroundColor='#d3004a'" onmouseout="this.style.backgroundColor='#FF0057'">
                            <a href="https://github.com/Sujit-O2" target="_blank" style="font-size: 17px; font-weight: bold; font-family: sans-serif; color: #ffffff; text-decoration: none; display: inline-block; text-transform: uppercase; letter-spacing: 1px;">
                                Fulfill My Request
                            </a>
                        </td>
                    </tr>
                </table>
                <p style="margin: 40px 0 0 0; font-size: 16px;">
                    Yours always, <br>
                    <strong class="primary-pink">Zero Two</strong>
                </p>
            </td>
        </tr>

        <tr>
            <td align="center" style="padding: 20px 30px; border-top: 1px solid #FFCCCC; font-size: 12px; color: #888888; line-height: 1.8; border-bottom-left-radius: 12px; border-bottom-right-radius: 12px; background-color: #f8f8f8;">
                <p style="margin: 0 0 10px 0; color: #555;">
                    © 2025 Zero Two. Code 002 is always watching.
                </p>
                <p style="margin: 0;">
                    <a href="https://github.com/Sujit-O2/O2_Anime_Waifu-Mobile-App" target="_blank" style="color: #FF0057; text-decoration: none; font-weight: bold;">See The Codes</a> 
                    <span style="color: #ccc;">|</span> 
                    <a href="#" target="_blank" style="color: #FF0057; text-decoration: none; font-weight: bold;">Privacy Policy</a>
                </p>
            </td>
        </tr>

    </table>

    <div style="height: 40px; line-height: 40px; mso-line-height-rule: exactly;">&nbsp;</div>
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
                  {"Email": mailId.trim()}
                ],
                "Subject": head,
                "HTMLPart": htmlFinal,
              }
            ]
          }),
        )
        .timeout(_mailTimeout);

    if (respon.statusCode == 200) {
      return "Mail sent successfully.";
    } else {
      debugPrint("${respon.statusCode}");
      return "Failed to send mail (${respon.statusCode}).";
    }
  }
}
