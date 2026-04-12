import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

/// Enhanced Email Service with multiple provider support
/// Handles Brevo, Mailgun, SendGrid with automatic retry and fallback
class EnhancedEmailService {
  static final EnhancedEmailService _instance =
      EnhancedEmailService._internal();

  factory EnhancedEmailService() => _instance;
  EnhancedEmailService._internal();

  String _brevoApiKey = '';
  String _mailgunKey = '';
  String _sendgridKey = '';
  static const Duration _timeout = Duration(seconds: 20);
  static const int _maxRetries = 3;

  void configure({
    String? brevoApiKey,
    String? mailgunKey,
    String? sendgridKey,
  }) {
    if (brevoApiKey != null && brevoApiKey.isNotEmpty) {
      _brevoApiKey = brevoApiKey.trim();
    }
    if (mailgunKey != null && mailgunKey.isNotEmpty) {
      _mailgunKey = mailgunKey.trim();
    }
    if (sendgridKey != null && sendgridKey.isNotEmpty) {
      _sendgridKey = sendgridKey.trim();
    }
  }

  /// Send email with automatic retry and provider fallback
  Future<EmailResult> sendEmail({
    required String toEmail,
    required String subject,
    required String body,
    required String senderName,
    String senderEmail = 'noreply@zerotwo.app',
    bool useHtmlTemplate = true,
  }) async {
    if (toEmail.trim().isEmpty || !_isValidEmail(toEmail)) {
      return EmailResult(
        success: false,
        message: 'Invalid recipient email address',
        provider: 'none',
      );
    }

    if (subject.trim().isEmpty || body.trim().isEmpty) {
      return EmailResult(
        success: false,
        message: 'Subject and body cannot be empty',
        provider: 'none',
      );
    }

    String? htmlContent;
    try {
      if (useHtmlTemplate) {
        final template =
            await rootBundle.loadString('assets/template/zero_two_email_template.html');
        htmlContent = template
            .replaceAll('{{body}}', body)
            .replaceAll('{{year}}', DateTime.now().year.toString());
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load email template: $e');
      htmlContent = '<html><body>$body</body></html>';
    }

    // Try providers in order: Brevo → Mailgun → SendGrid
    final providers = [
      if (_brevoApiKey.isNotEmpty) () => _sendViaBrevo(toEmail, subject, body, senderName, senderEmail, htmlContent),
      if (_mailgunKey.isNotEmpty) () => _sendViaMailgun(toEmail, subject, body, senderName, senderEmail, htmlContent),
      if (_sendgridKey.isNotEmpty) () => _sendViaSendGrid(toEmail, subject, body, senderName, senderEmail, htmlContent),
    ];

    if (providers.isEmpty) {
      return EmailResult(
        success: false,
        message: 'No email providers configured',
        provider: 'none',
      );
    }

    for (int i = 0; i < providers.length; i++) {
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          final result = await providers[i]();
          if (result.success) {
            debugPrint('✅ Email sent via ${result.provider}');
            return result;
          }
          debugPrint(
            '⚠️ ${result.provider} failed (attempt ${attempt + 1}/$_maxRetries): ${result.message}',
          );
        } catch (e) {
          debugPrint('❌ $e');
          if (attempt == _maxRetries - 1 && i == providers.length - 1) {
            return EmailResult(
              success: false,
              message: 'All email providers failed: $e',
              provider: 'error',
            );
          }
        }

        // Wait before retry
        if (attempt < _maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      }
    }

    return EmailResult(
      success: false,
      message: 'All email providers exhausted',
      provider: 'none',
    );
  }

  /// Send via Brevo SMTP API (Primary)
  Future<EmailResult> _sendViaBrevo(
    String toEmail,
    String subject,
    String body,
    String senderName,
    String senderEmail,
    String? htmlContent,
  ) async {
    const url = 'https://api.brevo.com/v3/smtp/email';

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'api-key': _brevoApiKey,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({
              'sender': {
                'name': senderName,
                'email': senderEmail,
              },
              'to': [
                {'email': toEmail}
              ],
              'subject': subject,
              'htmlContent': htmlContent ?? ('<html><body>$body</body></html>'),
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return EmailResult(
          success: true,
          message: 'Email sent successfully',
          provider: 'Brevo',
        );
      }

      final errorBody = jsonDecode(response.body);
      final errorMsg = errorBody['message'] ?? 'Unknown error';

      if (response.statusCode == 401) {
        return EmailResult(
          success: false,
          message: 'Brevo API key invalid or expired (401): $errorMsg',
          provider: 'Brevo',
        );
      } else if (response.statusCode == 429) {
        return EmailResult(
          success: false,
          message: 'Brevo rate limit exceeded (429)',
          provider: 'Brevo',
        );
      }

      return EmailResult(
        success: false,
        message: 'Brevo error (${response.statusCode}): $errorMsg',
        provider: 'Brevo',
      );
    } on TimeoutException {
      return EmailResult(
        success: false,
        message: 'Brevo request timeout',
        provider: 'Brevo',
      );
    } catch (e) {
      return EmailResult(
        success: false,
        message: 'Brevo error: $e',
        provider: 'Brevo',
      );
    }
  }

  /// Send via Mailgun API (Fallback 1)
  Future<EmailResult> _sendViaMailgun(
    String toEmail,
    String subject,
    String body,
    String senderName,
    String senderEmail,
    String? htmlContent,
  ) async {
    try {
      const domain = 'mg.zerotwo.app'; // Use your Mailgun domain
      final url = Uri.parse('https://api.mailgun.net/v3/$domain/messages');

      final response = await http
          .post(
            url,
            headers: {
              'Authorization':
                  'Basic ${base64Encode(utf8.encode('api:$_mailgunKey'))}',
            },
            body: {
              'from': '$senderName <$senderEmail>',
              'to': toEmail,
              'subject': subject,
              'html': htmlContent ?? body,
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return EmailResult(
          success: true,
          message: 'Email sent successfully',
          provider: 'Mailgun',
        );
      }

      return EmailResult(
        success: false,
        message: 'Mailgun error (${response.statusCode})',
        provider: 'Mailgun',
      );
    } catch (e) {
      return EmailResult(
        success: false,
        message: 'Mailgun error: $e',
        provider: 'Mailgun',
      );
    }
  }

  /// Send via SendGrid API (Fallback 2)
  Future<EmailResult> _sendViaSendGrid(
    String toEmail,
    String subject,
    String body,
    String senderName,
    String senderEmail,
    String? htmlContent,
  ) async {
    const url = 'https://api.sendgrid.com/v3/mail/send';

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $_sendgridKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'personalizations': [
                {
                  'to': [
                    {'email': toEmail}
                  ],
                }
              ],
              'from': {
                'email': senderEmail,
                'name': senderName,
              },
              'subject': subject,
              'content': [
                {
                  'type': 'text/html',
                  'value': htmlContent ?? body,
                }
              ],
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 202) {
        return EmailResult(
          success: true,
          message: 'Email sent successfully',
          provider: 'SendGrid',
        );
      }

      return EmailResult(
        success: false,
        message: 'SendGrid error (${response.statusCode})',
        provider: 'SendGrid',
      );
    } catch (e) {
      return EmailResult(
        success: false,
        message: 'SendGrid error: $e',
        provider: 'SendGrid',
      );
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}

/// Email result model
class EmailResult {
  final bool success;
  final String message;
  final String provider;

  EmailResult({
    required this.success,
    required this.message,
    required this.provider,
  });

  @override
  String toString() =>
      'EmailResult(success: $success, provider: $provider, message: $message)';
}

/// Global email service
final emailService = EnhancedEmailService();
