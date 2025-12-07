import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Groq API
class ApiService {
  final _url = "https://api.groq.com/openai/v1/chat/completions";
  final _apiKey = dotenv.env['API_KEY'] ?? "";
  final _sandGridKey=dotenv.env['SAND_grid_key'] ?? "";

 Future<String> sendConversation(List<Map<String, dynamic>> messages) async {
  if (_apiKey.isEmpty) throw Exception("API_KEY not set in .env");


  final payload = {
    "model": "moonshotai/kimi-k2-instruct",
    "messages": messages,
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
   final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
   final respon=await http.post(url,
                headers: {
                  "Authorization":'Bearer $_sandGridKey',
                        'Content-Type': 'application/json',
                },
                body: jsonEncode({
                "personalizations": [
                  {"to": [{"email": mailId}]}
                ],
                "from": {"email": "zerozerotwoxsujit@gmail.com"},
                "subject": head,
                "content": [{"type": "text/plain", "value": body}]
              }), );
              if(respon.statusCode==202) {
                return "send......";
              } else {
                print(respon.statusCode);
               return "failed to send.......";
              }
}

}