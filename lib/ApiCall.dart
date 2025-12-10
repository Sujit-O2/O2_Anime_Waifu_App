import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Groq API
class ApiService {
  final _url = "https://api.groq.com/openai/v1/chat/completions";
  final _apiKey = dotenv.env['API_KEY'] ?? "";
  String  now = DateTime.now().toString();
     // Output example: 2025-12-10 20:08:32.456789
  

 Future<String> sendConversation(List<Map<String, dynamic>> messages) async {
  if (_apiKey.isEmpty) throw Exception("API_KEY not set in .env");

final timeMessage = {
    "role": "system",
    "content": "The current date and time is $now. Use this information if the user asks about the current time or a related query."
  };
  messages.add(timeMessage);
  final payload = {
    "model": "moonshotai/kimi-k2-instruct",
    "messages":messages,
  };

  final res = await http.post(
    Uri.parse(_url),
    headers: {
      "Authorization": "Bearer $_apiKey",
      "Content-Type": "application/json",
    },
    body: jsonEncode(payload),
  );

  print("RAW RESPONSE: ${res.body}");

  if (res.statusCode != 200) {
    throw Exception("API error: ${res.statusCode}. Body: ${res.body}");
  }

  final data = jsonDecode(res.body);
  final choice = data["choices"][0];
  final msg = choice["message"];
  
   String ss=msg["content"].toString();
   if(ss.contains("Mail:")){
    // Extract email using regex
    final emailRegex = RegExp(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}");
    final match = emailRegex.firstMatch(ss);
    String mail="ss";
    if (match != null) {
      mail = match.group(0).toString();
      print("Extracted Email: ${match.group(0)}");
    }
    final extSub="Zero Two";
    final extBody=ss.substring(ss.indexOf("Body:")+6);
    print(extSub);
    print(extBody);
    return sendMail(mail, extBody, extSub);
   }

  return msg["content"] ?? "No response";
}
Future<String> sendMail(String mailId,String body,String head)async{
   final url = Uri.parse('https://api.mailjet.com/v3.1/send');
  //  final _sandGridKey=dotenv.env['SAND_grid_key'] ?? "";
   // ignore: non_constant_identifier_names
   final SecKeyMailjet=dotenv.env['MAILJET_SEC']??"";
   // ignore: non_constant_identifier_names
   final SecApiMailjet=dotenv.env['MAIL_JET_API']??"";
   final basicAuth='Basic ${base64Encode(utf8.encode("$SecApiMailjet:$SecKeyMailjet"))}';
   final htmlTemplate = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zero Two Bot Notification</title>
    <style>
        /* General Reset */
        body, html { margin: 0; padding: 0; }
        
        /* Outlook VML Support - Crucial for background images in Outlook */
        /*[if gte mso 9]>
        <xml>
          <o:OfficeDocumentSettings>
            <o:AllowPNG/>
            <o:PixelsPerInch>96</o:PixelsPerInch>
          </o:OfficeDocumentSettings>
        </xml>
        <![endif]*/
        
        /* General Styles */
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f0f2f5; 
            margin: 0;
            padding: 0;
            -webkit-text-size-adjust: 100%;
            -ms-text-size-adjust: 100%;
        }
        
        /* Container for background image fallback on compliant clients (like Gmail/Apple Mail) */
        .body-wrapper {
            background-color: #f0f2f5;
            background-repeat: no-repeat;
            background-attachment: fixed;
            background-position: center top;
            background-size: cover;
            height: 100%;
            padding: 0;
            margin: 0;
        }

        .container {
            max-width: 600px;
            margin: 0 auto; /* Center alignment */
            background: rgba(255, 255, 255, 0.95);
            border-radius: 12px;
            padding: 30px;
            box-shadow: 0px 8px 25px rgba(0,0,0,0.2);
            border: 1px solid #ddd;
        }
        
        .header {
            text-align: center;
            padding-bottom: 15px;
            margin-bottom: 20px;
            border-bottom: 2px solid #2970ff;
        }

        .header h2 {
            color: #ff69b4; /* Changed to a proper pink hex code for consistency */
            margin: 0;
            font-size: 24px;
            font-weight: 600;
        }

        .content {
            margin-top: 20px;
            font-size: 16px;
            line-height: 1.7;
            color: #333;
        }

        .salutation {
            font-weight: 600;
            color: #000;
            margin-bottom: 15px;
            display: block;
        }
        
        .closing {
            margin-top: 30px;
        }

        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            text-align: center;
            font-size: 12px;
            color: #888;
            line-height: 1.8;
        }
        
        .footer a {
            color: #888;
            text-decoration: underline;
        }
        
    </style>
</head>
<body style="background-color: #ffe4e1;">

<div class="body-wrapper">
    <div style="height: 50px; line-height: 50px;">&nbsp;</div> <div class="container">
        <div class="header">
            <h2>Zero Two</h2>
        </div>
        <div class="content">
            <p>{{body}}</p>
            <br>
            <p class="closing">
                Best regards, <br>
                The Zero Two
            </p>
        </div>
        <div class="footer">
            © 2025 Zero Two. All rights reserved. <br>
            <br>
            <a href="https://github.com/Sujit-O2/O2_Anime_Waifu-Mobile-App">See The Codes</a> | <a href="#">Privacy Policy</a>
        </div>
    </div>
    <div style="height: 50px; line-height: 50px;">&nbsp;</div> </div>

</body>
</html>
""";
final htmlFinal=htmlTemplate.replaceAll("{{body}}", body);

   final respon=await http.post(url,
                headers: {
                  "Authorization":basicAuth,
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
            {"Email": mailId}
          ],
          "Subject": head,
          "HTMLPart": htmlFinal,
        }
      ]
    }),
  );

              if(respon.statusCode==200) {
                return "send......";
              } else {
                print(respon.statusCode);
               return "failed to send.......";
              }
}

}