// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing Brevo API mail sending with REAL template...\n');

  // ── Config ──────────────────────────────────────────────────────────────
  final apiKey =
      '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';
  final recipientEmail = 'sujitswain077@gmail.com';
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

  // ── Send via Brevo API ──────────────────────────────────────────────────
  final url = Uri.parse('https://api.brevo.com/v3/smtp/email');

  try {
    print('Sending email to $recipientEmail...');
    final response = await http.post(
      url,
      headers: {
        'api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        "sender": {"name": "Zero Two", "email": "zerozerotwoxsujit@gmail.com"},
        "to": [
          {"email": recipientEmail}
        ],
        "subject": subject,
        "htmlContent": htmlFinal,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('\n✅ Mail sent successfully using the REAL template!');
      print('   Check $recipientEmail inbox to verify rendering.');
    } else {
      print('\n❌ Mail send failed.');
    }
  } catch (e) {
    print('\n❌ Error occurred: $e');
  }
}
