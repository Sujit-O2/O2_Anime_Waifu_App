// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  print('Testing Brevo API mail sending with REAL template...\n');

  // ── Config from env or CLI args ───────────────────────────────────────────
  final apiKey = Platform.environment['BREVO_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Missing BREVO_API_KEY environment variable');
    exit(1);
  }

  String recipientEmail;
  if (args.isNotEmpty) {
    recipientEmail = args[0];
  } else {
    recipientEmail =
        Platform.environment['RECIPIENT_EMAIL'] ?? 'sujitswain077@gmail.com';
  }

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(recipientEmail)) {
    print('❌ Invalid email format: $recipientEmail');
    exit(1);
  }

  final subject = 'System Verification: Brevo + Real Template Test';
  final bodyText =
      'This is a test verifying the REAL email template (with base64 avatar) renders correctly across all email clients!';

  // ── Load the ACTUAL asset template ──────────────────────────────────────
  final templateFile = File('assets/template/zero_two_email_template.html');
  if (!templateFile.existsSync()) {
    print('❌ Template file not found at: ${templateFile.path}');
    print('   Make sure you run this from the project root directory.');
    exit(1);
  }

  print('✅ Template found: ${templateFile.path}');
  final htmlTemplate = await templateFile.readAsString();
  print('   Template size: ${htmlTemplate.length} bytes');

  // ── Inject body text (same as production sendMail) ──────────────────────
  final htmlFinal = htmlTemplate
      .replaceAll('{{body}}', bodyText)
      .replaceAll('{{year}}', DateTime.now().year.toString());
  final hasPlaceholder = htmlTemplate.contains('{{body}}');
  print('   {{body}} placeholder found: $hasPlaceholder');
  print('   Body injected: ${htmlFinal.contains(bodyText)}');

  // ── Verify base64 image is present ──────────────────────────────────────
  final hasBase64 = htmlFinal.contains('data:image/');
  print('   Base64 image embedded: $hasBase64');
  print('');

  // ── Send via Brevo API with retry ─────────────────────────────────────────
  final url = Uri.parse('https://api.brevo.com/v3/smtp/email');

  const maxRetries = 3;
  for (var attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      print(
          'Sending email to $recipientEmail... (attempt $attempt/$maxRetries)');
      final response = await http
          .post(
            url,
            headers: {
              'api-key': apiKey,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "sender": {
                "name": "Zero Two",
                "email": "zerozerotwoxsujit@gmail.com"
              },
              "to": [
                {"email": recipientEmail}
              ],
              "subject": subject,
              "htmlContent": htmlFinal,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('\n✅ Mail sent successfully using the REAL template!');
        print('   Check $recipientEmail inbox to verify rendering.');
        break;
      } else if (attempt < maxRetries) {
        print('   Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      } else {
        print('\n❌ Mail send failed after $maxRetries attempts.');
      }
    } catch (err) {
      if (attempt < maxRetries) {
        print('❌ Error: $err. Retrying in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      } else {
        print('\n❌ Error after $maxRetries attempts: $err');
      }
    }
  }
}
