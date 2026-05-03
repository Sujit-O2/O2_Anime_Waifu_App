import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/api_call.dart';

class InboxCopilotService {
  static final InboxCopilotService instance = InboxCopilotService._internal();

  factory InboxCopilotService() {
    return instance;
  }

  InboxCopilotService._internal();

  late SharedPreferences _prefs;
  final List<EmailSummary> _summaries = [];
  final List<ActionItem> _actionItems = [];
  final List<SuggestedReply> _suggestedReplies = [];
  bool _isAnalyzing = false;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromStorage();
    if (kDebugMode) debugPrint('[InboxCopilot] Service initialized');
  }

  bool get isAnalyzing => _isAnalyzing;

  void pasteEmails(String rawEmails) {
    final parsed = _parseRawEmails(rawEmails);
    for (final email in parsed) {
      final exists = _summaries.any((s) =>
          s.from == email.from &&
          s.subject == email.subject &&
          s.rawBody == email.rawBody);
      if (!exists) {
        _summaries.add(email);
      }
    }
    if (kDebugMode)
      debugPrint('[InboxCopilot] Parsed ${parsed.length} emails from raw text');
  }

  Future<void> summarizeEmails() async {
    if (_summaries.isEmpty) return;
    _isAnalyzing = true;

    final emailsToSummarize =
        _summaries.where((e) => e.summary.isEmpty).toList();
    if (emailsToSummarize.isEmpty) {
      _isAnalyzing = false;
      return;
    }

    final prompt = _buildSummarizationPrompt(emailsToSummarize);

    try {
      final response = await ApiService().sendConversation([
        {'role': 'system', 'content': _systemPrompt()},
        {'role': 'user', 'content': prompt},
      ]);

      _parseAIResponse(response, emailsToSummarize);
      await _saveToStorage();
    } catch (e) {
      if (kDebugMode) debugPrint('[InboxCopilot] Summarization error: $e');
      for (final email in emailsToSummarize) {
        email.summary = 'Failed to analyze: ${e.toString().split('\n').first}';
        email.sentiment = 'unknown';
      }
      await _saveToStorage();
    }

    _isAnalyzing = false;
  }

  List<EmailSummary> getEmailSummaries() {
    return List.unmodifiable(_summaries);
  }

  List<ActionItem> getActionItems() {
    _actionItems.clear();
    for (final summary in _summaries) {
      for (final item in summary.actionItems) {
        _actionItems.add(ActionItem(
          description: item,
          from: summary.from,
          subject: summary.subject,
          priority: _inferPriority(item, summary.subject),
        ));
      }
    }
    _actionItems.sort((a, b) => _priorityOrder(b.priority)
        .compareTo(_priorityOrder(a.priority)));
    return List.unmodifiable(_actionItems);
  }

  List<SuggestedReply> getSuggestedReplies() {
    _suggestedReplies.clear();
    for (final summary in _summaries) {
      if (summary.suggestedReply.isNotEmpty) {
        _suggestedReplies.add(SuggestedReply(
          to: summary.from,
          subject: 'Re: ${summary.subject}',
          body: summary.suggestedReply,
          tone: _inferTone(summary.sentiment),
        ));
      }
    }
    return List.unmodifiable(_suggestedReplies);
  }

  Future<void> clearInbox() async {
    _summaries.clear();
    _actionItems.clear();
    _suggestedReplies.clear();
    await _prefs.remove('inbox_copilot_emails');
    await _prefs.remove('inbox_copilot_action_items');
    await _prefs.remove('inbox_copilot_replies');
    if (kDebugMode) debugPrint('[InboxCopilot] Inbox cleared');
  }

  String _systemPrompt() {
    return '''You are an email analysis assistant. Analyze emails and respond with ONLY valid JSON. No markdown, no explanation, just pure JSON.

For each email, provide:
- summary: 1-2 sentence concise summary
- sentiment: "positive", "neutral", "negative", or "urgent"
- actionItems: list of specific action items extracted from the email (empty list if none)
- suggestedReply: a professional reply suggestion (empty string if no reply needed)

Format:
{
  "emails": [
    {
      "index": 0,
      "summary": "...",
      "sentiment": "neutral",
      "actionItems": ["item1", "item2"],
      "suggestedReply": "..."
    }
  ]
}''';
  }

  String _buildSummarizationPrompt(List<EmailSummary> emails) {
    final buffer = StringBuffer();
    buffer.writeln('Analyze these ${emails.length} emails:\n');
    for (int i = 0; i < emails.length; i++) {
      buffer.writeln('EMAIL $i:');
      buffer.writeln('From: ${emails[i].from}');
      buffer.writeln('Subject: ${emails[i].subject}');
      buffer.writeln('Body: ${emails[i].rawBody}');
      buffer.writeln('---');
    }
    buffer.writeln('\nReturn the JSON analysis for each email by index.');
    return buffer.toString();
  }

  List<EmailSummary> _parseRawEmails(String rawText) {
    final emails = <EmailSummary>[];

    final separators = RegExp(r'^(From:|---|\n\n\n|\r\n\r\n\r\n)', multiLine: true);
    final chunks = rawText.split(separators).where((c) => c.trim().isNotEmpty).toList();

    if (chunks.length <= 1 && rawText.trim().isNotEmpty) {
      chunks.clear();
      chunks.add(rawText.trim());
    }

    for (final chunk in chunks) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;

      final fromMatch = RegExp(r'From:\s*(.+)', caseSensitive: false).firstMatch(trimmed);
      final subjectMatch = RegExp(r'Subject:\s*(.+)', caseSensitive: false).firstMatch(trimmed);
      final bodyMatch = RegExp(r'Body:\s*([\s\S]+)', caseSensitive: false).firstMatch(trimmed);

      final from = fromMatch?.group(1)?.trim() ?? _extractFirstLine(trimmed);
      final subject = subjectMatch?.group(1)?.trim() ?? _extractSubject(trimmed);
      final body = bodyMatch?.group(1)?.trim() ?? trimmed;

      emails.add(EmailSummary(
        from: from,
        subject: subject,
        rawBody: body,
        timestamp: DateTime.now(),
      ));
    }

    if (emails.isEmpty && rawText.trim().isNotEmpty) {
      emails.add(EmailSummary(
        from: 'Unknown',
        subject: _extractSubject(rawText),
        rawBody: rawText.trim(),
        timestamp: DateTime.now(),
      ));
    }

    return emails;
  }

  String _extractFirstLine(String text) {
    final lines = text.split('\n');
    return lines.isNotEmpty ? lines.first.trim() : 'Unknown';
  }

  String _extractSubject(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final match = RegExp(r'(?:RE|FW|FWD)?\s*:?\s*(.+)', caseSensitive: false).firstMatch(line);
      if (match != null && line.toLowerCase().contains('subject')) continue;
      if (line.length > 5 && line.length < 100) return line.trim();
    }
    return 'No Subject';
  }

  void _parseAIResponse(String response, List<EmailSummary> emails) {
    String cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      final data = jsonDecode(cleaned) as Map<String, dynamic>;
      final emailList = data['emails'] as List?;
      if (emailList == null) return;

      for (final item in emailList) {
        final entry = item as Map<String, dynamic>;
        final index = entry['index'] as int?;
        if (index == null || index >= emails.length) continue;

        final email = emails[index];
        email.summary = (entry['summary'] as String?)?.trim() ?? '';
        email.sentiment = (entry['sentiment'] as String?)?.trim().toLowerCase() ?? 'neutral';

        final actionItemsRaw = entry['actionItems'];
        if (actionItemsRaw is List) {
          email.actionItems = actionItemsRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        email.suggestedReply = (entry['suggestedReply'] as String?)?.trim() ?? '';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[InboxCopilot] JSON parse error: $e');
      final lines = response.split('\n');
      for (int i = 0; i < lines.length && i < emails.length; i++) {
        if (lines[i].trim().isNotEmpty) {
          emails[i].summary = lines[i].trim();
          emails[i].sentiment = 'neutral';
        }
      }
    }
  }

  String _inferPriority(String actionItem, String subject) {
    final urgent = RegExp(r'urgent|asap|immediately|deadline|critical|emergency', caseSensitive: false);
    final normal = RegExp(r'tomorrow|next week|schedule|review|update', caseSensitive: false);
    final text = '$actionItem $subject';
    if (urgent.hasMatch(text)) return 'high';
    if (normal.hasMatch(text)) return 'medium';
    return 'low';
  }

  int _priorityOrder(String priority) {
    switch (priority) {
      case 'high':
        return 0;
      case 'medium':
        return 1;
      case 'low':
        return 2;
      default:
        return 3;
    }
  }

  String _inferTone(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return 'warm';
      case 'negative':
        return 'diplomatic';
      case 'urgent':
        return 'professional-urgent';
      default:
        return 'professional';
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final summariesData = _summaries.map((s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList('inbox_copilot_emails', summariesData);
    } catch (e) {
      if (kDebugMode) debugPrint('[InboxCopilot] Save error: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final data = _prefs.getStringList('inbox_copilot_emails') ?? [];
      _summaries.clear();
      for (final item in data) {
        try {
          _summaries.add(EmailSummary.fromJson(jsonDecode(item) as Map<String, dynamic>));
        } catch (e) {
          if (kDebugMode) debugPrint('[InboxCopilot] Load error: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[InboxCopilot] Load error: $e');
    }
  }
}

class EmailSummary {
  final String from;
  final String subject;
  final String rawBody;
  String summary;
  String sentiment;
  List<String> actionItems;
  String suggestedReply;
  final DateTime timestamp;

  EmailSummary({
    required this.from,
    required this.subject,
    required this.rawBody,
    this.summary = '',
    this.sentiment = 'pending',
    this.actionItems = const [],
    this.suggestedReply = '',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'from': from,
        'subject': subject,
        'rawBody': rawBody,
        'summary': summary,
        'sentiment': sentiment,
        'actionItems': actionItems,
        'suggestedReply': suggestedReply,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EmailSummary.fromJson(Map<String, dynamic> json) {
    return EmailSummary(
      from: json['from'] as String? ?? 'Unknown',
      subject: json['subject'] as String? ?? 'No Subject',
      rawBody: json['rawBody'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      sentiment: json['sentiment'] as String? ?? 'pending',
      actionItems: (json['actionItems'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedReply: json['suggestedReply'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

class ActionItem {
  final String description;
  final String from;
  final String subject;
  final String priority;

  ActionItem({
    required this.description,
    required this.from,
    required this.subject,
    required this.priority,
  });
}

class SuggestedReply {
  final String to;
  final String subject;
  final String body;
  final String tone;

  SuggestedReply({
    required this.to,
    required this.subject,
    required this.body,
    required this.tone,
  });
}
